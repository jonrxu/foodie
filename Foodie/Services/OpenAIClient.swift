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


