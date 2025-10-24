//
//  GroceryCartGenerator.swift
//  Foodie
//
//

import Foundation
import CoreLocation

@MainActor
final class GroceryCartGenerator {
    static let shared = GroceryCartGenerator()
    
    private init() {}
    
    struct GroceryCart: Codable, Identifiable {
        let id: UUID
        let items: [GroceryItem]
        let generatedAt: Date
        let title: String
        
        init(id: UUID = UUID(), items: [GroceryItem], generatedAt: Date = Date(), title: String = "Weekly Groceries") {
            self.id = id
            self.items = items
            self.generatedAt = generatedAt
            self.title = title
        }
    }
    
    struct GroceryItem: Codable, Identifiable {
        let id: UUID
        let name: String
        let category: String
        let quantity: String
        let notes: String?
        var isChecked: Bool
        
        init(id: UUID = UUID(), name: String, category: String, quantity: String, notes: String? = nil, isChecked: Bool = false) {
            self.id = id
            self.name = name
            self.category = category
            self.quantity = quantity
            self.notes = notes
            self.isChecked = isChecked
        }
    }
    
    /// Generate a grocery cart based on user's eating history and preferences
    func generateCart(coordinate: CLLocationCoordinate2D? = nil) async throws -> GroceryCart {
        // 1. Get recent food logs (last 7 days)
        let logs = FoodLogStore.shared.load()
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentLogs = logs.filter { $0.date >= weekAgo }
        
        // 2. Get user preferences
        let profile = AppSession.shared.profile
        let dietaryPrefs = profile?.dietarySummary ?? ""
        let allergies = profile?.allergySummary ?? ""
        let cuisines = profile?.favoriteCuisinesSummary ?? ""
        let budgetNotes = profile?.groceryBudgetNotes ?? ""
        
        // 3. Build context for AI
        let logSummary = recentLogs.map { "\($0.summary) (\($0.estimatedCalories ?? 0) cal)" }.joined(separator: "\n")
        
        let prompt = """
        Generate a smart grocery list for the upcoming week based on this user's eating patterns and preferences.
        
        RECENT MEALS (last 7 days):
        \(logSummary.isEmpty ? "No recent meals logged - suggest balanced staples." : logSummary)
        
        USER PREFERENCES:
        - Dietary style: \(dietaryPrefs.isEmpty ? "None specified" : dietaryPrefs)
        - Allergies/avoidances: \(allergies.isEmpty ? "None specified" : allergies)
        - Favorite cuisines: \(cuisines.isEmpty ? "None specified" : cuisines)
        - Budget notes: \(budgetNotes.isEmpty ? "None specified" : budgetNotes)
        
        GUIDELINES:
        1. Include 20-25 items covering proteins, vegetables, fruits, grains, pantry staples
        2. Fill nutritional gaps from recent meals (e.g., if they ate lots of carbs, suggest more protein/veggies)
        3. Respect dietary restrictions and preferences
        4. Keep it practical: shelf-stable items, common ingredients
        5. Include quantities (e.g., "2 lbs", "1 bunch", "1 package")
        6. Add helpful notes when relevant (e.g., "for meal prep", "good protein source")
        
        Return JSON only:
        {
          "items": [
            {"name": "Chicken breast", "category": "Protein", "quantity": "2 lbs", "notes": "Lean protein for dinners"},
            {"name": "Spinach", "category": "Vegetables", "quantity": "1 bag", "notes": "High in iron"},
            ...
          ]
        }
        """
        
        // 4. Call OpenAI to generate cart
        let response = try await OpenAIClient().chatCompletion(prompt: prompt, temperature: 0.7)
        
        // 5. Parse response
        guard let jsonData = response.data(using: .utf8) else {
            throw GroceryCartError.invalidResponse
        }
        
        struct CartResponse: Codable {
            let items: [ItemResponse]
        }
        
        struct ItemResponse: Codable {
            let name: String
            let category: String
            let quantity: String
            let notes: String?
        }
        
        let decoded = try JSONDecoder().decode(CartResponse.self, from: jsonData)
        
        let groceryItems = decoded.items.map { item in
            GroceryItem(
                name: item.name,
                category: item.category,
                quantity: item.quantity,
                notes: item.notes
            )
        }
        
        return GroceryCart(items: groceryItems, title: "Weekly Groceries - \(formatDate(Date()))")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

enum GroceryCartError: LocalizedError {
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Failed to generate grocery list. Please try again."
        }
    }
}

// MARK: - OpenAI Chat Completion Extension
extension OpenAIClient {
    func chatCompletion(prompt: String, temperature: Double = 0.4) async throws -> String {
        guard let apiKey = ApiKeyStore.shared.getApiKey() else {
            throw OpenAIError.missingApiKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct RequestBody: Encodable {
            let model: String
            let temperature: Double
            let messages: [Message]
            let response_format: ResponseFormat
            
            struct Message: Encodable {
                let role: String
                let content: String
            }
            
            struct ResponseFormat: Encodable {
                let type: String
            }
        }
        
        let body = RequestBody(
            model: "gpt-4o-mini",
            temperature: temperature,
            messages: [
                .init(role: "system", content: "You are a helpful grocery planning assistant. Always respond with valid JSON only."),
                .init(role: "user", content: prompt)
            ],
            response_format: .init(type: "json_object")
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OpenAIError.badResponse
        }
        
        struct CompletionResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let decoded = try JSONDecoder().decode(CompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw OpenAIError.badResponse
        }
        
        return content
    }
}

