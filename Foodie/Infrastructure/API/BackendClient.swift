//
//  BackendClient.swift
//  Foodie
//

import Foundation

final class BackendClient {
    enum BackendError: Error, LocalizedError {
        case notConfigured
        case invalidResponse
        case badStatusCode(Int)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Backend is not configured yet."
            case .invalidResponse:
                return "Backend returned an invalid response."
            case .badStatusCode(let statusCode):
                return "Backend request failed with status \(statusCode)."
            }
        }
    }

    struct DexcomAuthStartResponse: Codable {
        let authorizationURL: URL

        enum CodingKeys: String, CodingKey {
            case authorizationURL = "authorization_url"
        }
    }

    struct DexcomConnectionStatusResponse: Codable {
        let provider: String
        let status: String
        let connectedAt: Date?
        let lastSyncAt: Date?
        let errorMessage: String?

        enum CodingKeys: String, CodingKey {
            case provider
            case status
            case connectedAt = "connected_at"
            case lastSyncAt = "last_sync_at"
            case errorMessage = "error_message"
        }
    }

    struct WeeklyGlucoseSummaryResponse: Codable {
        let summary: GlucoseSummary
    }

    struct MealInsightResponse: Codable {
        let mealLog: MealLog
        let mealImageName: String?
        let suggestionImageName: String?
        let feedback: MealFeedback
        let spikeEvent: SpikeEvent?
        let impact: MealImpactChartData
        let suggestedCartItems: [CartItem]
    }

    struct RecentMealsResponse: Codable {
        let meals: [MealLog]
    }

    struct CartDraftResponse: Codable {
        let draft: CartDraft?
    }

    struct CartGenerationRequest: Encodable {
        let mealLogID: UUID?
    }

    struct CartCheckoutRequest: Encodable {
        let draftID: UUID?
    }

    struct AnalyzePhotoRequest: Encodable {
        let imageBase64: String
        let mimeType: String
    }

    struct AnalyzePhotoResponse: Decodable {
        let summary: String
        let servingSize: String?
    }

    struct LookupBarcodeResponse: Decodable {
        let summary: String
    }

    struct WeeklyCartGenerationRequest: Encodable {
        let careGoals: [String]
        let dietPreferences: [String]
    }

    struct RegisterUserRequest: Encodable {
        let displayName: String
        let dietPreferences: [String]
        let careGoals: [String]
        let supportPreferences: [String]
    }

    struct RegisterUserResponse: Decodable {
        let id: String
        let displayName: String
        let dietPreferences: [String]
        let careGoals: [String]
        let supportPreferences: [String]
    }

    static let shared = BackendClient()

    private static let userIDKeychainKey = "backend_user_id"

    static func saveUserID(_ id: String) {
        KeychainStore.shared.write(id, account: userIDKeychainKey)
    }

    static var storedUserID: String? {
        KeychainStore.shared.read(account: userIDKeychainKey)
    }

    private let environment: APIEnvironment
    private let session: URLSession
    private let fallbackUserID: String

    private var effectiveUserID: String {
        KeychainStore.shared.read(account: Self.userIDKeychainKey) ?? fallbackUserID
    }

    init(environment: APIEnvironment = .current,
         session: URLSession = .shared,
         defaultUserID: String = AppConfig.defaultBackendUserID) {
        self.environment = environment
        self.session = session
        self.fallbackUserID = defaultUserID
    }

    func registerUser(name: String,
                      dietPreferences: [String] = [],
                      careGoals: [String] = [],
                      supportPreferences: [String] = []) async throws -> RegisterUserResponse {
        switch environment.mode {
        case .stub:
            return RegisterUserResponse(
                id: fallbackUserID,
                displayName: name,
                dietPreferences: dietPreferences,
                careGoals: careGoals,
                supportPreferences: supportPreferences
            )
        case .remote(let baseURL):
            return try await post(
                path: "/users/register",
                body: RegisterUserRequest(
                    displayName: name,
                    dietPreferences: dietPreferences,
                    careGoals: careGoals,
                    supportPreferences: supportPreferences
                ),
                to: baseURL,
                requiresAuth: false
            )
        }
    }

    func startDexcomAuthorization() async throws -> DexcomAuthStartResponse {
        switch environment.mode {
        case .stub:
            return DexcomAuthStartResponse(
                authorizationURL: URL(string: "https://developer.dexcom.com/")!
            )
        case .remote(let baseURL):
            return try await post(path: "/dexcom/connect/start", body: EmptyBody(), to: baseURL)
        }
    }

    func fetchDexcomConnectionStatus() async throws -> DexcomConnectionStatusResponse {
        switch environment.mode {
        case .stub:
            return DexcomConnectionStatusResponse(
                provider: "dexcom",
                status: "connected",
                connectedAt: Date(),
                lastSyncAt: Date(),
                errorMessage: nil
            )
        case .remote(let baseURL):
            return try await get(path: "/dexcom/connect/status", from: baseURL)
        }
    }

    func triggerDexcomSync() async throws -> DexcomConnectionStatusResponse {
        switch environment.mode {
        case .stub:
            return DexcomConnectionStatusResponse(
                provider: "dexcom",
                status: "connected",
                connectedAt: Date(),
                lastSyncAt: Date(),
                errorMessage: nil
            )
        case .remote(let baseURL):
            _ = try await post(path: "/dexcom/sync", body: EmptyBody(), to: baseURL) as DexcomSyncEnvelope
            return try await get(path: "/dexcom/connect/status", from: baseURL)
        }
    }

    func fetchGlucoseReadings(start: Date? = nil, end: Date? = nil) async throws -> [GlucoseReading] {
        switch environment.mode {
        case .stub:
            let response = try await fetchWeeklyGlucoseSummary()
            return response.summary.readings
        case .remote(let baseURL):
            var components = URLComponents(url: baseURL.appending(path: "/cgm/readings"), resolvingAgainstBaseURL: false)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]

            var queryItems: [URLQueryItem] = []
            if let start {
                queryItems.append(URLQueryItem(name: "start", value: formatter.string(from: start)))
            }
            if let end {
                queryItems.append(URLQueryItem(name: "end", value: formatter.string(from: end)))
            }
            components?.queryItems = queryItems.isEmpty ? nil : queryItems

            guard let url = components?.url else {
                throw BackendError.invalidResponse
            }

            var request = URLRequest(url: url)
            configureHeaders(for: &request)
            let (data, response) = try await session.data(for: request)
            return try decode(GlucoseReadingsEnvelope.self, from: data, response: response).readings
        }
    }

    func fetchWeeklyGlucoseSummary() async throws -> WeeklyGlucoseSummaryResponse {
        switch environment.mode {
        case .stub:
            let now = Date()
            let readings = [
                GlucoseReading(timestamp: now.addingTimeInterval(-6 * 86_400), valueMgdl: 126, source: .simulated),
                GlucoseReading(timestamp: now.addingTimeInterval(-5 * 86_400), valueMgdl: 160, source: .simulated),
                GlucoseReading(timestamp: now.addingTimeInterval(-4 * 86_400), valueMgdl: 149, source: .simulated),
                GlucoseReading(timestamp: now.addingTimeInterval(-3 * 86_400), valueMgdl: 176, source: .simulated),
                GlucoseReading(timestamp: now.addingTimeInterval(-2 * 86_400), valueMgdl: 166, source: .simulated),
                GlucoseReading(timestamp: now.addingTimeInterval(-1 * 86_400), valueMgdl: 154, source: .simulated),
                GlucoseReading(timestamp: now, valueMgdl: 162, source: .simulated)
            ]
            return WeeklyGlucoseSummaryResponse(
                summary: GlucoseSummary(
                    startDate: now.addingTimeInterval(-7 * 86_400),
                    endDate: now,
                    averageMgdl: 156.1,
                    timeInRangePercent: 82,
                    readings: readings
                )
            )
        case .remote(let baseURL):
            return try await get(path: "/cgm/summary/weekly", from: baseURL)
        }
    }

    func createMealLog(_ mealLog: MealLog) async throws -> MealLog {
        switch environment.mode {
        case .stub:
            return mealLog
        case .remote(let baseURL):
            return try await post(path: "/meals", body: mealLog, to: baseURL)
        }
    }

    func fetchRecentMeals(limit: Int = 10) async throws -> [MealLog] {
        switch environment.mode {
        case .stub:
            return []
        case .remote(let baseURL):
            var components = URLComponents(url: baseURL.appending(path: "/meals/recent"), resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
            guard let url = components?.url else {
                throw BackendError.invalidResponse
            }

            var request = URLRequest(url: url)
            configureHeaders(for: &request)
            let (data, response) = try await session.data(for: request)
            return try decode(RecentMealsResponse.self, from: data, response: response).meals
        }
    }

    func fetchMealInsight(for mealLogID: UUID) async throws -> MealInsightResponse {
        switch environment.mode {
        case .stub:
            let mealLog = MealLog(
                id: mealLogID,
                loggedAt: Date(),
                source: .photo,
                summary: "Chicken and fries",
                rawInput: "Captured meal photo"
            )
            return MealInsightResponse(
                mealLog: mealLog,
                mealImageName: "chickenandfries",
                suggestionImageName: "chickenandsalad",
                feedback: MealFeedback(
                    mealLogID: mealLogID,
                    mode: .predicted,
                    headline: "Feedback on your meal",
                    summary: "Short rise, then steady decrease",
                    coachMessage: "This meal is nicely balanced. You may see a short rise in your blood sugar, followed by a steady decrease.",
                    suggestedSwap: "Swap fries for a side salad",
                    suggestedCartItems: ["Mixed greens", "Cherry tomatoes", "Cucumbers"]
                ),
                spikeEvent: nil,
                impact: MealImpactChartData(
                    withMeal: [
                        MealImpactPoint(minute: 0, glucose: 118),
                        MealImpactPoint(minute: 30, glucose: 144),
                        MealImpactPoint(minute: 60, glucose: 152),
                        MealImpactPoint(minute: 90, glucose: 136),
                        MealImpactPoint(minute: 120, glucose: 123)
                    ],
                    withoutMeal: [
                        MealImpactPoint(minute: 0, glucose: 118),
                        MealImpactPoint(minute: 30, glucose: 116.8),
                        MealImpactPoint(minute: 60, glucose: 115.6),
                        MealImpactPoint(minute: 90, glucose: 114.7),
                        MealImpactPoint(minute: 120, glucose: 113.9)
                    ]
                ),
                suggestedCartItems: [
                    CartItem(name: "Mixed greens", category: "Produce", quantity: "1 box"),
                    CartItem(name: "Cherry tomatoes", category: "Produce", quantity: "1 pint"),
                    CartItem(name: "Cucumbers", category: "Produce", quantity: "2 ct")
                ]
            )
        case .remote(let baseURL):
            return try await get(path: "/meals/\(mealLogID.uuidString)/feedback", from: baseURL)
        }
    }

    func generateCart(mealLogID: UUID? = nil) async throws -> CartDraft {
        switch environment.mode {
        case .stub:
            return CartDraft(
                id: UUID(),
                title: "Recommended grocery swaps",
                source: .mealFeedback,
                storeName: "GIANT",
                totalEstimate: 21.76,
                items: [
                    CartItem(name: "Mixed greens", category: "Produce", quantity: "1 box", estimatedPrice: 4.29),
                    CartItem(name: "Cherry tomatoes", category: "Produce", quantity: "1 pint", estimatedPrice: 3.49),
                    CartItem(name: "Cucumbers", category: "Produce", quantity: "2 ct", estimatedPrice: 1.79),
                    CartItem(name: "Chicken breast", category: "Protein", quantity: "1.5 lb", estimatedPrice: 8.99),
                    CartItem(name: "Whole-grain bread", category: "Carbs", quantity: "1 loaf", estimatedPrice: 4.49)
                ]
            )
        case .remote(let baseURL):
            let response: CartDraftResponse = try await post(
                path: "/cart/generate",
                body: CartGenerationRequest(mealLogID: mealLogID),
                to: baseURL
            )
            guard let draft = response.draft else {
                throw BackendError.invalidResponse
            }
            return draft
        }
    }

    func fetchLatestCartDraft() async throws -> CartDraft? {
        switch environment.mode {
        case .stub:
            return nil
        case .remote(let baseURL):
            let response: CartDraftResponse = try await get(path: "/cart/latest", from: baseURL)
            return response.draft
        }
    }

    func analyzePhoto(_ imageData: Data, mimeType: String = "image/jpeg") async throws -> (summary: String, servingSize: String?) {
        switch environment.mode {
        case .stub:
            return ("Photo meal", nil)
        case .remote(let baseURL):
            let response: AnalyzePhotoResponse = try await post(
                path: "/meals/analyze-photo",
                body: AnalyzePhotoRequest(imageBase64: imageData.base64EncodedString(), mimeType: mimeType),
                to: baseURL
            )
            return (response.summary, response.servingSize)
        }
    }

    func lookupBarcode(code: String) async throws -> String {
        switch environment.mode {
        case .stub:
            return "Scanned product"
        case .remote(let baseURL):
            var components = URLComponents(url: baseURL.appending(path: "/meals/lookup-barcode"), resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "code", value: code)]
            guard let url = components?.url else { throw BackendError.invalidResponse }
            var request = URLRequest(url: url)
            configureHeaders(for: &request)
            let (data, response) = try await session.data(for: request)
            return try decode(LookupBarcodeResponse.self, from: data, response: response).summary
        }
    }

    func generateWeeklyCart(careGoals: [String] = [], dietPreferences: [String] = []) async throws -> CartDraft {
        switch environment.mode {
        case .stub:
            return CartDraft(
                title: "Your weekly grocery list",
                source: .weeklyCart,
                storeName: "GIANT",
                totalEstimate: 42.50,
                items: [
                    CartItem(name: "Mixed greens", category: "Produce", quantity: "1 box", estimatedPrice: 4.29),
                    CartItem(name: "Chicken breast", category: "Protein", quantity: "2 lb", estimatedPrice: 12.99),
                    CartItem(name: "Greek yogurt", category: "Dairy", quantity: "32 oz", estimatedPrice: 5.49),
                    CartItem(name: "Quinoa", category: "Carbs", quantity: "1 lb", estimatedPrice: 6.99),
                    CartItem(name: "Broccoli", category: "Produce", quantity: "1 head", estimatedPrice: 2.49)
                ]
            )
        case .remote(let baseURL):
            let response: CartDraftResponse = try await post(
                path: "/cart/generate-weekly",
                body: WeeklyCartGenerationRequest(careGoals: careGoals, dietPreferences: dietPreferences),
                to: baseURL
            )
            guard let draft = response.draft else { throw BackendError.invalidResponse }
            return draft
        }
    }

    func prepareCartCheckout(draftID: UUID? = nil) async throws -> CartDraft {
        switch environment.mode {
        case .stub:
            return CartDraft(
                title: "Recommended grocery swaps",
                source: .mealFeedback,
                storeName: "GIANT",
                totalEstimate: 21.76,
                checkoutURL: URL(string: "https://www.instacart.com/store/giant?foodie_cart_id=stub-cart"),
                items: [
                    CartItem(name: "Mixed greens", category: "Produce", quantity: "1 box", estimatedPrice: 4.29),
                    CartItem(name: "Cherry tomatoes", category: "Produce", quantity: "1 pint", estimatedPrice: 3.49),
                    CartItem(name: "Cucumbers", category: "Produce", quantity: "2 ct", estimatedPrice: 1.79)
                ]
            )
        case .remote(let baseURL):
            let response: CartDraftResponse = try await post(
                path: "/cart/checkout",
                body: CartCheckoutRequest(draftID: draftID),
                to: baseURL
            )
            guard let draft = response.draft else {
                throw BackendError.invalidResponse
            }
            return draft
        }
    }

    private func get<Response: Decodable>(path: String, from baseURL: URL) async throws -> Response {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        configureHeaders(for: &request)
        let (data, response) = try await session.data(for: request)
        return try decode(Response.self, from: data, response: response)
    }

    private func post<Body: Encodable, Response: Decodable>(path: String,
                                                            body: Body,
                                                            to baseURL: URL,
                                                            requiresAuth: Bool = true) async throws -> Response {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if requiresAuth { configureHeaders(for: &request) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601WithFallback
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        return try decode(Response.self, from: data, response: response)
    }

    private func configureHeaders(for request: inout URLRequest) {
        request.setValue(effectiveUserID, forHTTPHeaderField: "X-User-Id")
    }

    private func decode<Response: Decodable>(_ type: Response.Type, from data: Data, response: URLResponse) throws -> Response {
        guard let http = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw BackendError.badStatusCode(http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFallback
        guard let decoded = try? decoder.decode(type, from: data) else {
            throw BackendError.invalidResponse
        }
        return decoded
    }
}

private struct EmptyBody: Encodable {}

private struct DexcomSyncEnvelope: Codable {
    let status: String
    let syncedAt: Date

    enum CodingKeys: String, CodingKey {
        case status
        case syncedAt = "synced_at"
    }
}

private struct GlucoseReadingsEnvelope: Codable {
    let readings: [GlucoseReading]
}
