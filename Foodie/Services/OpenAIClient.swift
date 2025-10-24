//
//  OpenAIClient.swift
//  Foodie
//
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
    struct FoodAnalysisResult: Codable {
        struct NutritionTotals: Codable {
            let calories: Double?
            let proteinGrams: Double?
            let carbohydrateGrams: Double?
            let fatGrams: Double?
            let fiberGrams: Double?
            let addedSugarGrams: Double?
            let sodiumMilligrams: Double?
            let saturatedFatGrams: Double?
            let unsaturatedFatGrams: Double?
        }

        struct Portion: Codable {
            let unit: String?
            let quantity: Double?
            let text: String?
        }

        struct AnalysisItem: Codable {
            let name: String
            let description: String?
            let portion: Portion?
            let totals: NutritionTotals
            let confidence: Double?
            let tags: [String]?
        }

        struct Confidence: Codable {
            let overall: Double?
            let calories: Double?
            let protein: Double?
            let carbohydrates: Double?
            let fat: Double?
            let fiber: Double?
            let addedSugar: Double?
            let sodium: Double?
        }

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
        let nutritionTotals: NutritionTotals?
        let nutritionItems: [AnalysisItem]?
        let nutritionConfidence: Confidence?
        let notes: [String]?
    }

    private struct ResponseFormat: Encodable {
        let type: String
        let json_schema: Schema
    }

    private struct Schema: Encodable {
        let name: String
        let strict: Bool
        let schema: SchemaNode

        final class SchemaNode: Encodable {
            let type: String
            let properties: [String: SchemaNode]?
            let required: [String]?
            let items: SchemaNode?
            let description: String?
            let additionalProperties: Bool?
            let enumValues: [String]? // use custom key for enums

            init(type: String,
                 properties: [String: SchemaNode]? = nil,
                 required: [String]? = nil,
                 items: SchemaNode? = nil,
                 description: String? = nil,
                 additionalProperties: Bool? = nil,
                 enumValues: [String]? = nil) {
                self.type = type
                self.properties = properties
                self.required = required
                self.items = items
                self.description = description
                self.additionalProperties = additionalProperties
                self.enumValues = enumValues
            }

            enum CodingKeys: String, CodingKey {
                case type, properties, required, items, description, additionalProperties
                case enumValues = "enum"
            }
        }
    }

    private var nutritionSchema: Schema {
        let nutritionTotals = Schema.SchemaNode(type: "object",
                                                properties: [
                                                    "calories": .init(type: "number", description: "Total calories in kilocalories"),
                                                    "proteinGrams": .init(type: "number", description: "Protein grams"),
                                                    "carbohydrateGrams": .init(type: "number", description: "Carbohydrate grams"),
                                                    "fatGrams": .init(type: "number", description: "Total fat grams"),
                                                    "fiberGrams": .init(type: "number", description: "Dietary fiber grams"),
                                                    "addedSugarGrams": .init(type: "number", description: "Added sugar grams"),
                                                    "sodiumMilligrams": .init(type: "number", description: "Sodium in milligrams"),
                                                    "saturatedFatGrams": .init(type: "number", description: "Saturated fat grams"),
                                                    "unsaturatedFatGrams": .init(type: "number", description: "Unsaturated fat grams")
                                                ],
                                                required: ["calories", "proteinGrams", "carbohydrateGrams", "fatGrams", "fiberGrams", "addedSugarGrams", "sodiumMilligrams", "saturatedFatGrams", "unsaturatedFatGrams"],
                                                additionalProperties: false)

        let portion = Schema.SchemaNode(type: "object",
                                        properties: [
                                            "unit": .init(type: "string", description: "Unit such as grams, ml, cup"),
                                            "quantity": .init(type: "number", description: "Numeric quantity if available"),
                                            "text": .init(type: "string", description: "Human-readable portion description")
                                        ],
                                        required: ["unit", "quantity", "text"],
                                        additionalProperties: false)

        let item = Schema.SchemaNode(type: "object",
                                     properties: [
                                        "name": .init(type: "string", description: "Canonical name of the food item"),
                                        "description": .init(type: "string", description: "Short description"),
                                        "portion": portion,
                                        "totals": nutritionTotals,
                                        "confidence": .init(type: "number", description: "Confidence 0-1"),
                                        "tags": .init(type: "array", items: .init(type: "string"), description: "Food item tags")
                                     ],
                                     required: ["name", "description", "portion", "totals", "confidence", "tags"],
                                     description: "Per-item nutrition analysis",
                                     additionalProperties: false)

        let confidence = Schema.SchemaNode(type: "object",
                                           properties: [
                                            "overall": .init(type: "number", description: "Overall confidence 0-1"),
                                            "calories": .init(type: "number", description: "Calories confidence"),
                                            "protein": .init(type: "number", description: "Protein confidence"),
                                            "carbohydrates": .init(type: "number", description: "Carbohydrate confidence"),
                                            "fat": .init(type: "number", description: "Fat confidence"),
                                            "fiber": .init(type: "number", description: "Fiber confidence"),
                                            "addedSugar": .init(type: "number", description: "Added sugar confidence"),
                                            "sodium": .init(type: "number", description: "Sodium confidence")
                                           ],
                                           required: ["overall", "calories", "protein", "carbohydrates", "fat", "fiber", "addedSugar", "sodium"],
                                           description: "Confidence scores",
                                           additionalProperties: false)

        let axes = Schema.SchemaNode(type: "object",
                                     properties: [
                                        "nutrientDensity": .init(type: "integer", description: "Nutrient density score 0-100"),
                                        "processing": .init(type: "integer", description: "Processing level score 0-100"),
                                        "sugarLoad": .init(type: "integer", description: "Sugar load score 0-100"),
                                        "saturatedFat": .init(type: "integer", description: "Saturated fat score 0-100"),
                                        "sodium": .init(type: "integer", description: "Sodium score 0-100"),
                                        "positives": .init(type: "integer", description: "Positive attributes score 0-100")
                                     ],
                                     required: ["nutrientDensity", "processing", "sugarLoad", "saturatedFat", "sodium", "positives"],
                                     description: "Legacy axes",
                                     additionalProperties: false)
        
        let rootProperties: [String: Schema.SchemaNode] = [
            "detected": .init(type: "boolean", description: "Whether edible food was detected"),
            "summary": .init(type: "string", description: "Concise meal summary"),
            "estimatedCalories": .init(type: "integer", description: "Legacy calorie estimate"),
            "confidence": .init(type: "number", description: "Legacy overall confidence"),
            "mealType": .init(type: "string", description: "Meal type such as breakfast"),
            "score": .init(type: "integer", description: "Legacy score"),
            "level": .init(type: "string", description: "Legacy level A-E"),
            "axes": axes,
            "tags": .init(type: "array", items: .init(type: "string"), description: "Tags array"),
            "highlights": .init(type: "array", items: .init(type: "string"), description: "Highlights array"),
            "nutritionTotals": nutritionTotals,
            "nutritionItems": .init(type: "array", items: item, description: "List of food items"),
            "nutritionConfidence": confidence,
            "notes": .init(type: "array", items: .init(type: "string"), description: "Short notes or caveats")
        ]

        return Schema(name: "NutritionAnalysis",
                      strict: true,
                      schema: .init(type: "object",
                                     properties: rootProperties,
                                     required: ["detected", "summary", "estimatedCalories", "confidence", "mealType", "score", "level", "axes", "tags", "highlights", "nutritionTotals", "nutritionItems", "nutritionConfidence", "notes"],
                                     description: "Structured nutrition analysis for a meal",
                                     additionalProperties: false))
    }

    private func structuredResponseFormat() -> ResponseFormat {
        ResponseFormat(type: "json_schema", json_schema: nutritionSchema)
    }

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

        let systemText = "You analyze meal photos and must respond with valid JSON that matches the provided NutritionAnalysis schema.\nGuidelines:\n- Describe edible food items only and estimate realistic portions (grams or household measures) when possible.\n- Provide nutrient totals per item and overall (calories, protein, carbohydrates, fat, fiber, added sugar, sodium, saturated fat, unsaturated fat).\n- If unsure, leave numeric fields null rather than guessing wildly; never output negative numbers.\n- Confidence values must be between 0 and 1.\n- Use canonical ingredient names and include helpful notes if something is uncertain or requires user confirmation.\n- For the summary field, provide a simple, concise description of the main food items (e.g., 'Caesar salad with grilled chicken' not 'This meal consists of a Caesar salad with grilled chicken breast').\n- If no edible food or drink is present, set detected=false, return an empty items array, and leave nutrient fields null."

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
        }

        let body = Body(model: model,
                        temperature: 0.2,
                        messages: messages,
                        response_format: structuredResponseFormat())
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        // Debug logging
        #if DEBUG
        if let requestBody = request.httpBody, let requestString = String(data: requestBody, encoding: .utf8) {
            print("📤 [analyzeFoodImage] Request - Status Code will follow...")
        }
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            print("❌ [analyzeFoodImage] Invalid HTTP response")
            throw OpenAIError.badResponse
        }
        
        print("📊 [analyzeFoodImage] HTTP Status: \(http.statusCode)")
        
        guard (200..<300).contains(http.statusCode) else {
            print("❌ [analyzeFoodImage] HTTP error: \(http.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response: \(errorString)")
            }
            throw OpenAIError.badResponse
        }

        return try decodeNutritionResponse(from: data)
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

        let systemPrompt = "You estimate nutrition facts from short meal descriptions and must respond with JSON adhering to the NutritionAnalysis schema.\nGuidelines:\n- Summarize the meal clearly and estimate realistic portions using grams or household measures when available.\n- Populate nutrition totals and per-item data (calories, protein, carbohydrates, fat, fiber, added sugar, sodium, saturated and unsaturated fat).\n- Leave fields null if the description lacks enough detail; never fabricate highly specific numbers.\n- Confidence values must fall between 0 and 1.\n- Include notes recommending user confirmation when detail is insufficient.\n- If no edible food is described, set detected=false and return empty arrays with null nutrient totals."

        let messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: "Meal description: \(description)")
        ]

        struct Body: Encodable {
            let model: String
            let temperature: Double
            let messages: [Message]
            let response_format: ResponseFormat
        }

        let body = Body(model: model,
                        temperature: 0.2,
                        messages: messages,
                        response_format: structuredResponseFormat())
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        // Debug logging
        #if DEBUG
        print("📤 [estimateCalories] Request for: \(description)")
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            print("❌ [estimateCalories] Invalid HTTP response")
            throw OpenAIError.badResponse
        }

        print("📊 [estimateCalories] HTTP Status: \(http.statusCode)")
        
        guard (200..<300).contains(http.statusCode) else {
            print("❌ [estimateCalories] HTTP error: \(http.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response: \(errorString)")
            }
            throw OpenAIError.badResponse
        }

        return try decodeNutritionResponse(from: data)
    }

    private func decodeNutritionResponse(from data: Data) throws -> FoodAnalysisResult {
        struct CompletionResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable {
                    struct ToolCall: Codable {
                        struct Function: Codable { let arguments: String }
                        let function: Function
                    }

                    let content: String?
                    let tool_calls: [ToolCall]?
                }

                let message: Message
            }
            let choices: [Choice]
            let error: ErrorResponse?
        }
        
        struct ErrorResponse: Codable {
            let message: String
            let type: String?
            let code: String?
        }

        let decoder = JSONDecoder()
        
        // First, log the raw response for debugging
        if let rawString = String(data: data, encoding: .utf8) {
            print("🔍 OpenAI Raw Response:")
            print(rawString)
            print("---")
        }
        
        let completion: CompletionResponse
        do {
            completion = try decoder.decode(CompletionResponse.self, from: data)
        } catch {
            print("❌ Failed to decode OpenAI response structure: \(error)")
            throw OpenAIError.badResponse
        }
        
        // Check for API error
        if let apiError = completion.error {
            print("❌ OpenAI API Error: \(apiError.message)")
            throw OpenAIError.badResponse
        }
        
        guard let choice = completion.choices.first else {
            print("❌ No choices in OpenAI response")
            throw OpenAIError.badResponse
        }

        // Try content first
        if let content = choice.message.content, !content.isEmpty {
            print("📝 Found content in response")
            guard let jsonData = sanitizedJSONData(from: content) else {
                print("❌ Failed to sanitize JSON from content")
                throw OpenAIError.badResponse
            }
            do {
                let result = try decoder.decode(FoodAnalysisResult.self, from: jsonData)
                print("✅ Successfully decoded from content")
                return result
            } catch {
                print("❌ Failed to decode FoodAnalysisResult from content: \(error)")
                throw error
            }
        }

        // Try tool_calls
        if let arguments = choice.message.tool_calls?.first?.function.arguments {
            print("🔧 Found tool_calls in response")
            guard let jsonData = sanitizedJSONData(from: arguments) else {
                print("❌ Failed to sanitize JSON from tool_calls")
                throw OpenAIError.badResponse
            }
            do {
                let result = try decoder.decode(FoodAnalysisResult.self, from: jsonData)
                print("✅ Successfully decoded from tool_calls")
                return result
            } catch {
                print("❌ Failed to decode FoodAnalysisResult from tool_calls: \(error)")
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("JSON that failed to decode:")
                    print(jsonString)
                }
                throw error
            }
        }

        print("❌ No content or tool_calls found in response")
        throw OpenAIError.badResponse
    }

    private func sanitizedJSONData(from rawString: String) -> Data? {
        var trimmed = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("```") {
            trimmed = trimmed.replacingOccurrences(of: "^```[A-Za-z]*\\n?", with: "", options: .regularExpression)
            if let closingRange = trimmed.range(of: "```", options: .backwards) {
                trimmed = String(trimmed[..<closingRange.lowerBound])
            }
            trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return trimmed.data(using: .utf8)
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

        struct CompletionResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(CompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.badResponse
        }
        return try JSONDecoder().decode(FoodClassification.self, from: jsonData)
    }
}

// MARK: - Voice Transcription
extension OpenAIClient {
    func transcribeAudio(audioData: Data, prompt: String? = nil) async throws -> String {
        guard let apiKey = ApiKeyStore.shared.getApiKey() else {
            throw OpenAIError.missingApiKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add prompt field if provided
        if let prompt = prompt {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(prompt)\r\n".data(using: .utf8)!)
        }
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            print("❌ [OpenAI] Transcription failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [OpenAI] Error response: \(errorString)")
            }
            throw OpenAIError.badResponse
        }
        
        struct TranscriptionResponse: Decodable {
            let text: String
        }
        
        let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        print("✅ [OpenAI] Transcription: \(decoded.text)")
        return decoded.text
    }
    
    func parseFoodLog(transcript: String) async throws -> FoodAnalysisResult {
        // Use the existing estimateCalories method but with enhanced prompt
        return try await estimateCalories(for: transcript)
    }
}

