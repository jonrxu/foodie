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
        let detected: Bool
        let summary: String
        let estimatedCalories: Int?
        let confidence: Double?
        let mealType: String?
        let score: Int?
        let level: String?
        let axes: FoodHealthAssessment.Axes?
        let tags: [String]?
        let highlights: [String]?
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

        let systemText = "You analyze meal photos. Return strict JSON: {detected, summary, items, estimatedCalories, confidence, mealType, score, level, axes, tags, highlights}.\nIf no edible food/drink is visible set detected=false and set other fields null or empty arrays. When detected=true: summary should concisely describe only the edible items with portion hints; items must be an array of canonical edible components (ignore utensils, plates, bowls, cups unless they are edible); estimatedCalories integer or null; confidence float 0-1 or null; mealType string like breakfast/lunch/dinner or null; score integer 0-100; level single uppercase letter A-E; axes object with integer fields nutrientDensity, processing, sugarLoad, saturatedFat, sodium, positives (each 0-100); tags array of lowercase snake_case strings; highlights array of 2-3 short phrases explaining key drivers. No extra keys, no prose, no uncertainty language."

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

    func estimateCalories(for description: String) async throws -> FoodAnalysisResult {
        guard let apiKey = ApiKeyStore.shared.getApiKey() else {
            throw OpenAIError.missingApiKey
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Message: Encodable { let role: String; let content: String }

        let systemPrompt = "You estimate nutrition facts from short meal descriptions. Return strict JSON: {detected, summary, estimatedCalories, confidence, mealType, score, level, axes, tags, highlights}.\nIf the text clearly describes edible food, set detected=true and rewrite the summary as a concise, well-structured description highlighting portions if possible. Provide an estimatedCalories integer (or null if impossible), confidence 0-1 (or null), mealType string (breakfast/lunch/dinner/snack/other or null). Score (0-100) and level (A-E) reflect overall healthfulness. Axes is an object with nutrientDensity, processing, sugarLoad, saturatedFat, sodium, positives (integers 0-100). Tags is an array of lowercase snake_case strings. Highlights is an array with 2-3 short phrases.\nIf no edible food is described, set detected=false and set the other fields to null or empty arrays. Respond with valid JSON only, no commentary."

        let messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: "Meal description: \(description)")
        ]

        struct Body: Encodable {
            let model: String
            let temperature: Double
            let messages: [Message]
            let response_format: ResponseFormat
            struct ResponseFormat: Encodable { let type: String }
        }

        let body = Body(model: model,
                        temperature: 0.2,
                        messages: messages,
                        response_format: .init(type: "json_object"))
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OpenAIError.badResponse
        }

        struct CompletionResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(CompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.badResponse
        }
        return try JSONDecoder().decode(FoodAnalysisResult.self, from: jsonData)
    }

    struct FoodClassification: Decodable {
        let score: Int
        let level: String
        let axes: Axes
        let tags: [String]
        let highlights: [String]

        struct Axes: Decodable {
            let nutrientDensity: Int
            let processing: Int
            let sugarLoad: Int
            let saturatedFat: Int
            let sodium: Int
            let positives: Int
        }
    }

    func classifyFood(summary: String) async throws -> FoodClassification {
        guard let apiKey = ApiKeyStore.shared.getApiKey() else {
            throw OpenAIError.missingApiKey
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Message: Encodable { let role: String; let content: String }

        let systemPrompt = "You classify meals. Return strict JSON with fields: score (0-100), level (A-E), axes (nutrientDensity, processing, sugarLoad, saturatedFat, sodium, positives each 0-100), tags (array lowercase snake_case), highlights (array of short phrases)." +
        " Score higher for nutrient-dense, minimally processed foods; lower for ultra-processed, fried, sugary, high sodium, high saturated fat items." +
        " Axes represent individual dimensions: nutrientDensity (higher better), processing (higher worse), sugarLoad (higher worse), saturatedFat (higher worse), sodium (higher worse), positives (higher better)." +
        " Level must be a single uppercase letter A (best) through E (worst). Tags capture notable attributes. Highlights explain top 2-3 drivers." +
        " Respond with valid JSON only. No extra commentary or fields."

        let messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: "Meal summary: \(summary)")
        ]

        struct Body: Encodable {
            let model: String
            let temperature: Double
            let messages: [Message]
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
        return try JSONDecoder().decode(FoodClassification.self, from: jsonData)
    }
}



