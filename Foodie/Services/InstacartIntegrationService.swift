//
//  InstacartIntegrationService.swift
//  Foodie
//
//

import Foundation
import CoreLocation

final class InstacartIntegrationService {
    static let shared = InstacartIntegrationService()

    private init() {}

    func createShoppingList(from recommendations: [FoodRecommendation],
                            title: String? = nil,
                            coordinate: CLLocationCoordinate2D?) async throws -> ShoppingList {
        guard let configuration = loadConfiguration() else {
            throw NSError(domain: "InstacartIntegration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Instacart API key not set. Add it in settings."])
        }

        let client = InstacartMCPClient(configuration: configuration)
        let payloadItems = recommendations.map { item in
            InstacartMCPClient.ShoppingListRequestItem(name: item.name,
                                                       quantity: item.quantityHint,
                                                       note: item.notes,
                                                       store: item.storeName)
        }

        let response = try await client.createShoppingList(items: payloadItems, title: title)

        let list = ShoppingList(title: title ?? "Instacart List",
                                storeName: response.storeName ?? "Instacart",
                                totalEstimate: recommendations.compactMap { $0.estimatedPrice }.reduce(0, +),
                                itemCount: response.itemCount,
                                link: response.shareURL,
                                source: .instacart,
                                items: recommendations.map { recommendation in
                                    ShoppingList.Item(name: recommendation.name,
                                                      quantity: recommendation.quantityHint,
                                                      note: recommendation.notes,
                                                      estimatedPrice: recommendation.estimatedPrice,
                                                      storeName: recommendation.storeName)
                                },
                                locationCoordinate: coordinate)

        return list
    }

    private func loadConfiguration() -> InstacartMCPClient.Configuration? {
        guard let apiKey = UserPreferencesStore.shared.loadInstacartApiKey(), apiKey.isEmpty == false else { return nil }
        let environment: InstacartMCPClient.Configuration.Environment = .development
        return InstacartMCPClient.Configuration(environment: environment, apiKey: apiKey)
    }
}
