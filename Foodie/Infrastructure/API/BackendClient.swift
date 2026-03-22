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
    }

    struct WeeklyGlucoseSummaryResponse: Codable {
        let summary: GlucoseSummary
    }

    struct MealFeedbackResponse: Codable {
        let feedback: MealFeedback
    }

    struct CartGenerationResponse: Codable {
        let draft: CartDraft
    }

    static let shared = BackendClient()

    private let environment: APIEnvironment
    private let session: URLSession

    init(environment: APIEnvironment = .stub, session: URLSession = .shared) {
        self.environment = environment
        self.session = session
    }

    func startDexcomAuthorization() async throws -> DexcomAuthStartResponse {
        switch environment.mode {
        case .stub:
            return DexcomAuthStartResponse(
                authorizationURL: URL(string: "https://developer.dexcom.com/")!
            )
        case .remote(let baseURL):
            return try await get(path: "/auth/dexcom/start", from: baseURL)
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

    func fetchMealFeedback(for mealLogID: UUID) async throws -> MealFeedbackResponse {
        switch environment.mode {
        case .stub:
            return MealFeedbackResponse(
                feedback: MealFeedback(
                    mealLogID: mealLogID,
                    mode: .predicted,
                    headline: "Feedback on your meal",
                    summary: "Short rise, then steady decrease",
                    coachMessage: "This meal is nicely balanced. You may see a short rise in your blood sugar, followed by a steady decrease.",
                    suggestedSwap: "Swap fries for a side salad",
                    suggestedCartItems: ["Mixed greens", "Cherry tomatoes", "Cucumbers"]
                )
            )
        case .remote(let baseURL):
            return try await get(path: "/meals/\(mealLogID.uuidString)/feedback", from: baseURL)
        }
    }

    func generateCart(for profile: ProfileSnapshot) async throws -> CartGenerationResponse {
        switch environment.mode {
        case .stub:
            return CartGenerationResponse(
                draft: CartDraft(
                    title: "Weekly groceries",
                    source: .groceryPlanner,
                    storeName: "GIANT",
                    totalEstimate: 42.10,
                    items: [
                        CartItem(name: "Bananas", category: "Produce", quantity: "4 ct"),
                        CartItem(name: "Greek yogurt", category: "Protein", quantity: "1 tub"),
                        CartItem(name: "Broccoli", category: "Produce", quantity: "2 crowns")
                    ]
                )
            )
        case .remote(let baseURL):
            return try await post(path: "/cart/generate", body: profile, to: baseURL)
        }
    }

    private func get<Response: Decodable>(path: String, from baseURL: URL) async throws -> Response {
        let url = baseURL.appending(path: path)
        let (data, response) = try await session.data(from: url)
        return try decode(Response.self, from: data, response: response)
    }

    private func post<Body: Encodable, Response: Decodable>(path: String,
                                                            body: Body,
                                                            to baseURL: URL) async throws -> Response {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        return try decode(Response.self, from: data, response: response)
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
