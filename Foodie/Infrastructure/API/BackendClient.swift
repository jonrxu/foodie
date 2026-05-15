//
//  BackendClient.swift
//  Foodie
//

import Foundation

final class BackendClient {
    enum BackendError: Error, LocalizedError {
        case notConfigured
        case missingAuthentication
        case invalidResponse
        case badStatusCode(Int)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Backend is not configured yet."
            case .missingAuthentication:
                return "Please sign in again to continue."
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

    struct AgentFeedResponse: Codable {
        let runs: [AgentRun]
        let recommendations: [AgentRecommendation]
    }

    struct AgentRecommendationStateResponse: Codable {
        let id: UUID
        let readAt: Date?
        let dismissedAt: Date?
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
        let calories: Int?
    }

    struct LookupBarcodeResponse: Decodable {
        let summary: String
    }

    struct WeeklyCartGenerationRequest: Encodable {
        let careGoals: [String]
        let dietPreferences: [String]
    }

    struct UserProfileUpdateRequest: Encodable {
        let displayName: String
        let dietPreferences: [String]
        let careGoals: [String]
        let supportPreferences: [String]
        let hasCompletedOnboarding: Bool
    }

    struct CurrentUserProfileResponse: Decodable {
        let id: String
        let email: String?
        let displayName: String
        let dietPreferences: [String]
        let careGoals: [String]
        let supportPreferences: [String]
        let hasCompletedOnboarding: Bool

        enum CodingKeys: String, CodingKey {
            case id
            case email
            case displayName
            case dietPreferences
            case careGoals
            case supportPreferences
            case hasCompletedOnboarding
        }
    }

    static let shared = BackendClient()

    private let environment: APIEnvironment
    private let session: URLSession

    init(environment: APIEnvironment = .current,
         session: URLSession = .shared) {
        self.environment = environment
        self.session = session
    }

    func fetchCurrentUserProfile() async throws -> CurrentUserProfileResponse {
        switch environment.mode {
        case .stub:
            return CurrentUserProfileResponse(
                id: "stub-user",
                email: nil,
                displayName: "",
                dietPreferences: [],
                careGoals: [],
                supportPreferences: [],
                hasCompletedOnboarding: false
            )
        case .remote(let baseURL):
            return try await get(path: "/users/me", from: baseURL)
        }
    }

    func updateCurrentUserProfile(
        displayName: String,
        dietPreferences: [String],
        careGoals: [String],
        supportPreferences: [String],
        hasCompletedOnboarding: Bool
    ) async throws -> CurrentUserProfileResponse {
        switch environment.mode {
        case .stub:
            return CurrentUserProfileResponse(
                id: "stub-user",
                email: nil,
                displayName: displayName,
                dietPreferences: dietPreferences,
                careGoals: careGoals,
                supportPreferences: supportPreferences,
                hasCompletedOnboarding: hasCompletedOnboarding
            )
        case .remote(let baseURL):
            return try await put(
                path: "/users/me",
                body: UserProfileUpdateRequest(
                    displayName: displayName,
                    dietPreferences: dietPreferences,
                    careGoals: careGoals,
                    supportPreferences: supportPreferences,
                    hasCompletedOnboarding: hasCompletedOnboarding
                ),
                to: baseURL
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
            try configureHeaders(for: &request)
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
            try configureHeaders(for: &request)
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

    func fetchAgentFeed(limit: Int = 10) async throws -> AgentFeed {
        switch environment.mode {
        case .stub:
            return AgentFeed(runs: [], recommendations: [])
        case .remote(let baseURL):
            var components = URLComponents(url: baseURL.appending(path: "/agent/feed"), resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
            guard let url = components?.url else {
                throw BackendError.invalidResponse
            }

            var request = URLRequest(url: url)
            try configureHeaders(for: &request)
            let (data, response) = try await session.data(for: request)
            let decoded = try decode(AgentFeedResponse.self, from: data, response: response)
            return AgentFeed(runs: decoded.runs, recommendations: decoded.recommendations)
        }
    }

    func markAgentRecommendationRead(_ id: UUID) async throws -> AgentRecommendationStateResponse {
        switch environment.mode {
        case .stub:
            return AgentRecommendationStateResponse(id: id, readAt: Date(), dismissedAt: nil)
        case .remote(let baseURL):
            return try await post(
                path: "/agent/recommendations/\(id.uuidString)/read",
                body: EmptyBody(),
                to: baseURL
            )
        }
    }

    func dismissAgentRecommendation(_ id: UUID) async throws -> AgentRecommendationStateResponse {
        switch environment.mode {
        case .stub:
            let now = Date()
            return AgentRecommendationStateResponse(id: id, readAt: now, dismissedAt: now)
        case .remote(let baseURL):
            return try await post(
                path: "/agent/recommendations/\(id.uuidString)/dismiss",
                body: EmptyBody(),
                to: baseURL
            )
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

    func analyzePhoto(_ imageData: Data, mimeType: String = "image/jpeg") async throws -> (summary: String, servingSize: String?, calories: Int?) {
        switch environment.mode {
        case .stub:
            return ("Photo meal", nil, nil)
        case .remote(let baseURL):
            let response: AnalyzePhotoResponse = try await post(
                path: "/meals/analyze-photo",
                body: AnalyzePhotoRequest(imageBase64: imageData.base64EncodedString(), mimeType: mimeType),
                to: baseURL
            )
            return (response.summary, response.servingSize, response.calories)
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
            try configureHeaders(for: &request)
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
        try configureHeaders(for: &request)
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
        if requiresAuth { try configureHeaders(for: &request) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601WithFallback
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        return try decode(Response.self, from: data, response: response)
    }

    private func put<Body: Encodable, Response: Decodable>(path: String,
                                                           body: Body,
                                                           to baseURL: URL,
                                                           requiresAuth: Bool = true) async throws -> Response {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if requiresAuth { try configureHeaders(for: &request) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601WithFallback
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        return try decode(Response.self, from: data, response: response)
    }

    private func configureHeaders(for request: inout URLRequest) throws {
        guard let accessToken = AuthSessionStore.shared.load()?.accessToken, accessToken.isEmpty == false else {
            throw BackendError.missingAuthentication
        }
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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

struct AuthSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date?
    let userID: String
    let email: String?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date().addingTimeInterval(30)
    }
}

enum AuthSignUpResult: Equatable {
    case authenticated(AuthSession)
    case emailVerificationRequired
}

final class AuthSessionStore {
    static let shared = AuthSessionStore()

    private let keychainAccount = "supabase_auth_session"

    func load() -> AuthSession? {
        guard let raw = KeychainStore.shared.read(account: keychainAccount),
              let data = raw.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    func save(_ authSession: AuthSession) {
        guard let data = try? JSONEncoder().encode(authSession),
              let raw = String(data: data, encoding: .utf8) else {
            return
        }
        _ = KeychainStore.shared.write(raw, account: keychainAccount)
    }

    func clear() {
        _ = KeychainStore.shared.delete(account: keychainAccount)
    }
}

final class SupabaseAuthClient {
    enum AuthError: Error, LocalizedError {
        case notConfigured
        case invalidResponse
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Authentication is not configured yet."
            case .invalidResponse:
                return "Authentication provider returned an invalid response."
            case .apiError(let message):
                return message
            }
        }
    }

    static let shared = SupabaseAuthClient()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func signUp(name: String, email: String, password: String) async throws -> AuthSignUpResult {
        let response: SupabaseAuthResponse = try await request(
            path: "/auth/v1/signup",
            method: "POST",
            body: SupabaseSignUpRequest(
                email: email,
                password: password,
                data: SupabaseUserMetadata(displayName: name)
            )
        )

        if let authSession = response.authSession {
            AuthSessionStore.shared.save(authSession)
            return .authenticated(authSession)
        }

        return .emailVerificationRequired
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        let response: SupabaseAuthResponse = try await request(
            path: "/auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: SupabasePasswordSignInRequest(email: email, password: password)
        )
        guard let authSession = response.authSession else {
            throw AuthError.invalidResponse
        }
        AuthSessionStore.shared.save(authSession)
        return authSession
    }

    func restoreSession() async throws -> AuthSession? {
        guard let stored = AuthSessionStore.shared.load() else { return nil }
        if stored.isExpired {
            return try await refreshSession(refreshToken: stored.refreshToken)
        }
        return try await fetchCurrentUser(session: stored)
    }

    func refreshSession(refreshToken: String) async throws -> AuthSession {
        let response: SupabaseAuthResponse = try await request(
            path: "/auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: SupabaseRefreshTokenRequest(refreshToken: refreshToken)
        )
        guard let authSession = response.authSession else {
            throw AuthError.invalidResponse
        }
        AuthSessionStore.shared.save(authSession)
        return authSession
    }

    func fetchCurrentUser(session authSession: AuthSession) async throws -> AuthSession {
        let response: SupabaseUserResponse = try await request(
            path: "/auth/v1/user",
            method: "GET",
            body: Optional<String>.none,
            accessToken: authSession.accessToken
        )
        let updated = AuthSession(
            accessToken: authSession.accessToken,
            refreshToken: authSession.refreshToken,
            expiresAt: authSession.expiresAt,
            userID: response.id,
            email: response.email
        )
        AuthSessionStore.shared.save(updated)
        return updated
    }

    func signOut() async {
        if let stored = AuthSessionStore.shared.load() {
            _ = try? await request(
                path: "/auth/v1/logout",
                method: "POST",
                body: Optional<String>.none,
                accessToken: stored.accessToken
            ) as SupabaseLogoutResponse
        }
        AuthSessionStore.shared.clear()
    }

    private func request<Request: Encodable, Response: Decodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Request?,
        accessToken: String? = nil
    ) async throws -> Response {
        guard let baseURLString = AppConfig.supabaseURL,
              let baseURL = URL(string: baseURLString),
              let publishableKey = AppConfig.supabasePublishableKey,
              publishableKey.isEmpty == false else {
            throw AuthError.notConfigured
        }

        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else {
            throw AuthError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let decodedError = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data)
            let responseBody = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let statusPrefix = "Authentication failed (\(http.statusCode))"
            let details = decodedError?.bestMessage ?? {
                guard let responseBody, responseBody.isEmpty == false else { return nil }
                return responseBody
            }()
#if DEBUG
            print("Supabase auth request failed: method=\(method) path=\(path) status=\(http.statusCode) body=\(responseBody ?? "<empty>")")
#endif
            let message = details.map { "\(statusPrefix): \($0)" } ?? statusPrefix
            throw AuthError.apiError(message)
        }

        if Response.self == SupabaseLogoutResponse.self, let empty = SupabaseLogoutResponse() as? Response {
            return empty
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFallback
        guard let decoded = try? decoder.decode(Response.self, from: data) else {
            throw AuthError.invalidResponse
        }
        return decoded
    }
}

private struct SupabaseSignUpRequest: Encodable {
    let email: String
    let password: String
    let data: SupabaseUserMetadata
}

private struct SupabasePasswordSignInRequest: Encodable {
    let email: String
    let password: String
}

private struct SupabaseRefreshTokenRequest: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

private struct SupabaseUserMetadata: Encodable {
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

private struct SupabaseAuthResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresAtEpoch: TimeInterval?
    let user: SupabaseUserResponse?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAtEpoch = "expires_at"
        case user
    }

    var authSession: AuthSession? {
        guard let accessToken, let refreshToken else {
            return nil
        }
        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAtEpoch.map(Date.init(timeIntervalSince1970:)),
            userID: user?.id ?? "",
            email: user?.email
        )
    }
}

private struct SupabaseUserResponse: Decodable {
    let id: String
    let email: String?
}

private struct SupabaseErrorResponse: Decodable {
    let message: String?
    let errorDescription: String?
    let error: String?
    let msg: String?
    let errorCode: String?
    let code: String?

    enum CodingKeys: String, CodingKey {
        case message
        case errorDescription = "error_description"
        case error
        case msg
        case errorCode = "error_code"
        case code
    }

    var bestMessage: String? {
        let primary = [message, errorDescription, msg, error]
            .compactMap { candidate -> String? in
                guard let candidate else { return nil }
                let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            .first

        let codes = [errorCode, code]
            .compactMap { candidate -> String? in
                guard let candidate else { return nil }
                let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }

        guard let primary else {
            return codes.isEmpty ? nil : "Code: \(codes.joined(separator: ", "))"
        }

        guard codes.isEmpty == false else {
            return primary
        }

        return "\(primary) [\(codes.joined(separator: ", "))]"
    }
}

private struct SupabaseLogoutResponse: Decodable {
    init() {}
}
