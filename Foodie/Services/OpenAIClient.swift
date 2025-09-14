//
//  OpenAIClient.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

struct OpenAIClient {
    enum OpenAIError: Error, LocalizedError {
        case missingApiKey
        case badResponse

        var errorDescription: String? {
            switch self {
            case .missingApiKey:
                return "Missing API Key. Add it via the gear in the app header."
            case .badResponse:
                return "OpenAI returned an unexpected response."
            }
        }
    }

    private let model = "gpt-4o-mini"

    func streamChat(systemPrompt: String,
                    messages: [ChatMessage],
                    temperature: Double = 0.4,
                    onToken: @escaping (String) -> Void) async throws {
        guard let apiKey = ApiKeyStore.shared.getApiKey() else {
            throw OpenAIError.missingApiKey
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct RequestMessage: Encodable { let role: String; let content: String }
        var requestMessages: [RequestMessage] = []
        requestMessages.append(.init(role: "system", content: systemPrompt))
        for message in messages {
            requestMessages.append(.init(role: message.role == .user ? "user" : "assistant",
                                         content: message.content))
        }

        struct Body: Encodable {
            let model: String
            let temperature: Double
            let stream: Bool
            let messages: [RequestMessage]
        }
        let body = Body(model: model, temperature: temperature, stream: true, messages: requestMessages)
        request.httpBody = try JSONEncoder().encode(body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OpenAIError.badResponse
        }

        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" { break }
                guard let data = jsonString.data(using: .utf8) else { continue }

                struct StreamChunk: Decodable {
                    struct Choice: Decodable {
                        struct Delta: Decodable { let content: String? }
                        let delta: Delta
                    }
                    let choices: [Choice]
                }

                if let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data) {
                    if let token = chunk.choices.first?.delta.content, !token.isEmpty {
                        onToken(token)
                    }
                }
            }
        }
    }
}

extension OpenAIClient {
    struct FoodAnalysisResult: Decodable {
        let summary: String
        let estimatedCalories: Int?
        let confidence: Double?
        let mealType: String?
    }

    // Sends an image (as base64 data URL) and asks for a single concise sentence summary.
    func analyzeFoodImage(imageData: Data) async throws -> FoodAnalysisResult {
        guard let apiKey = ApiKeyStore.shared.getApiKey() else {
            throw OpenAIError.missingApiKey
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64 = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64)"

        struct RequestMessage: Encodable {
            let role: String
            let content: [Content]
            struct Content: Encodable {
                let type: String
                let text: String?
                let image_url: ImageURL?
                struct ImageURL: Encodable { let url: String }
            }
        }

        let systemText = "You are a precise meal logger. Return ONE concise sentence that includes: item/brand, plain‑English portion/size, and an estimated calorie count.\nFormat example: 'Lay's Classic chips, regular bag (~28 g), estimated calories 160 kcal'.\nRules: no uncertainty words, no ranges, no emojis, no advice, <=140 chars.\nRespond strictly as JSON with keys: summary (string), estimatedCalories (integer kcal), confidence (0–1), mealType (string or null)."

        let messages: [RequestMessage] = [
            .init(role: "system", content: [.init(type: "text", text: systemText, image_url: nil)]),
            .init(role: "user", content: [
                .init(type: "text", text: "Analyze this meal photo and follow the instructions.", image_url: nil),
                .init(type: "image_url", text: nil, image_url: .init(url: dataURL))
            ])
        ]

        struct Body: Encodable {
            let model: String
            let temperature: Double
            let messages: [RequestMessage]
            let response_format: ResponseFormat
            struct ResponseFormat: Encodable { let type: String }
        }

        let body = Body(model: model, temperature: 0.2, messages: messages, response_format: .init(type: "json_object"))
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OpenAIError.badResponse
        }

        struct CompletionResponse: Decodable {
            struct Choice: Decodable { struct Message: Decodable { let content: String }; let message: Message }
            let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(CompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.badResponse
        }
        return try JSONDecoder().decode(FoodAnalysisResult.self, from: jsonData)
    }
}



