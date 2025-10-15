//
//  MealPlanDataService.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation
import CoreLocation
import MapKit
import Contacts

struct Place: Identifiable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distanceMeters: Double
    let category: String
    let doorDashURL: URL?

    init(id: UUID = UUID(), name: String, address: String, coordinate: CLLocationCoordinate2D, distanceMeters: Double, category: String, doorDashURL: URL?) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.distanceMeters = distanceMeters
        self.category = category
        self.doorDashURL = doorDashURL
    }
}

extension Place {
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Place {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FoodRecommendation: Identifiable, Hashable {
    let id: UUID
    let name: String
    let estimatedPrice: Double?
    let storeName: String
    let notes: String
    let quantityHint: String?
    let doorDashURL: URL?

    init(id: UUID = UUID(),
         name: String,
         estimatedPrice: Double?,
         storeName: String,
         notes: String,
         quantityHint: String? = nil,
         doorDashURL: URL?) {
        self.id = id
        self.name = name
        self.estimatedPrice = estimatedPrice
        self.storeName = storeName
        self.notes = notes
        self.quantityHint = quantityHint
        self.doorDashURL = doorDashURL
    }
}

struct FoodRecommendationContext {
    let dietaryPreferences: String
    let favoriteCuisines: String
    let budgetNotes: String
    let recentMeals: [String]
    let nearbyPlaces: [Place]
}

protocol PlacesService {
    func fetchPlaces(near location: CLLocationCoordinate2D) async throws -> [Place]
}

protocol FoodRecommendationService {
    func fetchFoodRecommendations(near location: CLLocationCoordinate2D,
                                  context: FoodRecommendationContext) async throws -> [FoodRecommendation]
}

final class MockPlacesService: PlacesService {
    func fetchPlaces(near location: CLLocationCoordinate2D) async throws -> [Place] {
        try await Task.sleep(nanoseconds: 400_000_000)
        let baseURL = URL(string: "https://www.doordash.com/")
        return [
            Place(name: "Green Harvest Market", address: "123 Grove St", coordinate: location, distanceMeters: 250, category: "Grocery", doorDashURL: baseURL),
            Place(name: "Fresh Fare Co-op", address: "45 Willow Ave", coordinate: location, distanceMeters: 620, category: "Co-op", doorDashURL: baseURL),
            Place(name: "Budget Bites Market", address: "88 Oak Blvd", coordinate: location, distanceMeters: 1050, category: "Discount", doorDashURL: baseURL)
        ]
    }
}

final class MockFoodRecommendationService: FoodRecommendationService {
    func fetchFoodRecommendations(near location: CLLocationCoordinate2D,
                                  context: FoodRecommendationContext) async throws -> [FoodRecommendation] {
        try await Task.sleep(nanoseconds: 420_000_000)
        let baseURL = URL(string: "https://www.doordash.com/")
        return [
            FoodRecommendation(name: "Seasonal Veggie Box", estimatedPrice: 18.99, storeName: "Green Harvest Market", notes: "Local produce for 4 meals", quantityHint: "1 box", doorDashURL: baseURL),
            FoodRecommendation(name: "Lean Protein Pack", estimatedPrice: 24.49, storeName: "Fresh Fare Co-op", notes: "Chicken, tofu, beans assortment", quantityHint: "1 pack", doorDashURL: baseURL),
            FoodRecommendation(name: "Budget Pantry Essentials", estimatedPrice: 12.79, storeName: "Budget Bites Market", notes: "Whole grains, legumes, spices", quantityHint: "1 bundle", doorDashURL: baseURL)
        ]
    }
}

final class AIRecommendationService: FoodRecommendationService {
    private let client: OpenAIClient

    init(client: OpenAIClient = OpenAIClient()) {
        self.client = client
    }

    func fetchFoodRecommendations(near location: CLLocationCoordinate2D,
                                  context: FoodRecommendationContext) async throws -> [FoodRecommendation] {
        let prompt = Self.buildPrompt(context: context, location: location)
        let response = try await client.generateFoodRecommendations(prompt: prompt)

        return response.items.compactMap { item in
            let trimmedStore = item.store.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchedPlace = context.nearbyPlaces.first { place in
                place.name.localizedCaseInsensitiveContains(trimmedStore) ||
                trimmedStore.localizedCaseInsensitiveContains(place.name)
            }

            let coordinate = matchedPlace?.coordinate ?? location
            let link = matchedPlace?.doorDashURL ?? makeDoorDashURL(for: trimmedStore.isEmpty ? (matchedPlace?.name ?? "store") : trimmedStore,
                                                                   coordinate: coordinate)

            return FoodRecommendation(name: item.name,
                                      estimatedPrice: max(item.estimatedPrice ?? 0, 0),
                                      storeName: matchedPlace?.name ?? (trimmedStore.isEmpty ? "Nearby Store" : trimmedStore),
                                      notes: item.note,
                                      quantityHint: item.quantity,
                                      doorDashURL: link)
        }
    }

    private static func buildPrompt(context: FoodRecommendationContext,
                                    location: CLLocationCoordinate2D) -> String {
        var lines: [String] = []
        let lat = String(format: "%.4f", location.latitude)
        let lng = String(format: "%.4f", location.longitude)
        lines.append("User approximate location: latitude \(lat), longitude \(lng).")

        let dietary = context.dietaryPreferences.trimmingCharacters(in: .whitespacesAndNewlines)
        lines.append("Dietary preferences: \(dietary.isEmpty ? "none specified" : dietary)")

        let cuisines = context.favoriteCuisines.trimmingCharacters(in: .whitespacesAndNewlines)
        lines.append("Favorite cuisines: \(cuisines.isEmpty ? "none specified" : cuisines)")

        let budget = context.budgetNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        lines.append("Budget & time notes: \(budget.isEmpty ? "none provided" : budget)")

        if context.nearbyPlaces.isEmpty {
            lines.append("Nearby stores: none identified.")
        } else {
            lines.append("Nearby stores:")
            for place in context.nearbyPlaces.prefix(8) {
                let distance = place.distanceMeters >= 1000
                    ? String(format: "%.1f km", place.distanceMeters / 1000)
                    : "\(Int(place.distanceMeters)) m"
                lines.append("- \(place.name) (\(place.category)) • \(distance) • \(place.address)")
            }
        }

        if context.recentMeals.isEmpty {
            lines.append("Recent meals: none logged.")
        } else {
            lines.append("Recent meals:")
            for meal in context.recentMeals { lines.append("- \(meal)") }
        }

        lines.append("Task: Recommend 4-6 grocery items that align with the user's preferences, budget, and recent meals.")
        lines.append("For each item, choose a store from the nearby list when possible, provide a concise helpful note, and estimate the price in USD (if unknown, offer a reasonable estimate). Return JSON with items[].")

        return lines.joined(separator: "\n")
    }
}

extension OpenAIClient {
    struct FoodRecommendationResponse: Decodable {
        struct Item: Decodable {
            let name: String
            let estimatedPrice: Double?
            let store: String
            let note: String
            let quantity: String?
        }
        let items: [Item]
    }

    func generateFoodRecommendations(prompt: String) async throws -> FoodRecommendationResponse {
        guard let apiKey = ApiKeyStore.shared.getApiKey() else {
            throw OpenAIError.missingApiKey
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Message: Encodable { let role: String; let content: String }
        struct Body: Encodable {
            let model: String
            let temperature: Double
            let messages: [Message]
            let response_format: ResponseFormat
            struct ResponseFormat: Encodable { let type: String }
        }

        let body = Body(model: "gpt-4o-mini",
                        temperature: 0.2,
                        messages: [
                            Message(role: "system", content: "You create grocery recommendations. Return strict JSON only."),
                            Message(role: "user", content: prompt)
                        ],
                        response_format: .init(type: "json_object"))
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
        guard let content = decoded.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.badResponse
        }

        return try JSONDecoder().decode(FoodRecommendationResponse.self, from: jsonData)
    }
}

final class LocalSearchPlacesService: PlacesService {
    func fetchPlaces(near location: CLLocationCoordinate2D) async throws -> [Place] {
        let region = MKCoordinateRegion(center: location,
                                        span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18))

        let queries = ["grocery store", "supermarket", "organic market", "food market"]
        var mapItems: [MKMapItem] = []

        for query in queries {
            let request = MKLocalSearch.Request()
            request.region = region
            request.naturalLanguageQuery = query
            request.resultTypes = [.pointOfInterest]

            do {
                let response = try await MKLocalSearch(request: request).start()
                mapItems.append(contentsOf: response.mapItems)
            } catch {
                // Ignore individual query failures and continue to the next
                continue
            }
        }

        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)

        var uniquePlaces: [Place] = []
        var seenIdentifiers = Set<String>()

        for item in mapItems {
            guard let name = item.name else { continue }
            let key = [name, item.placemark.coordinate.latitude.description, item.placemark.coordinate.longitude.description].joined(separator: "|")
            guard seenIdentifiers.insert(key).inserted else { continue }

            let distance = item.placemark.location.map { $0.distance(from: userLocation) } ?? 0
            let address = formattedAddress(from: item.placemark)
            let category = displayName(for: item.pointOfInterestCategory)
            let doorDashURL = makeDoorDashURL(for: name, coordinate: item.placemark.coordinate)

            let place = Place(name: name,
                              address: address,
                              coordinate: item.placemark.coordinate,
                              distanceMeters: distance,
                              category: category,
                              doorDashURL: doorDashURL)
            uniquePlaces.append(place)
        }

        if uniquePlaces.isEmpty {
            return try await MockPlacesService().fetchPlaces(near: location)
        }

        return Array(uniquePlaces.sorted(by: { $0.distanceMeters < $1.distanceMeters }).prefix(12))
    }

    private func formattedAddress(from placemark: MKPlacemark) -> String {
        if let postalAddress = placemark.postalAddress {
            return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress).replacingOccurrences(of: "\n", with: ", ")
        }
        var components: [String] = []
        if let street = placemark.thoroughfare { components.append(street) }
        if let city = placemark.locality { components.append(city) }
        if let state = placemark.administrativeArea { components.append(state) }
        return components.joined(separator: ", ")
    }

    private func displayName(for category: MKPointOfInterestCategory?) -> String {
        guard let category = category else { return "Grocery" }
        let identifier = category.rawValue.lowercased()

        if identifier.contains("supermarket") { return "Supermarket" }
        if identifier.contains("convenience") { return "Convenience Store" }
        if identifier.contains("bakery") { return "Bakery" }
        if identifier.contains("organic") { return "Organic Market" }
        if identifier.contains("market") { return "Market" }
        if identifier.contains("restaurant") { return "Restaurant" }

        let raw = category.rawValue
        return raw
            .replacingOccurrences(of: "MKPOICategory", with: "")
            .replacingOccurrences(of: "POICategory", with: "")
            .splitBeforeCapitals()
    }
}

private func makeDoorDashURL(for name: String, coordinate: CLLocationCoordinate2D) -> URL? {
    let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "store"
    let lat = String(format: "%.4f", coordinate.latitude)
    let lng = String(format: "%.4f", coordinate.longitude)
    return URL(string: "https://www.doordash.com/search/store/\(encodedName)?lat=\(lat)&lng=\(lng)")
}

private extension String {
    func splitBeforeCapitals() -> String {
        guard isEmpty == false else { return self }
        var result = ""
        for char in self {
            if char.isUppercase, result.isEmpty == false {
                result.append(" ")
            }
            result.append(char)
        }
        return result
    }
}
