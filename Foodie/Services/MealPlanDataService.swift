//
//  MealPlanDataService.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation
import CoreLocation

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
    let price: Double
    let storeName: String
    let notes: String
    let doorDashURL: URL?

    init(id: UUID = UUID(), name: String, price: Double, storeName: String, notes: String, doorDashURL: URL?) {
        self.id = id
        self.name = name
        self.price = price
        self.storeName = storeName
        self.notes = notes
        self.doorDashURL = doorDashURL
    }
}

protocol PlacesService {
    func fetchPlaces(near location: CLLocationCoordinate2D) async throws -> [Place]
}

protocol FoodRecommendationService {
    func fetchFoodRecommendations(near location: CLLocationCoordinate2D) async throws -> [FoodRecommendation]
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
    func fetchFoodRecommendations(near location: CLLocationCoordinate2D) async throws -> [FoodRecommendation] {
        try await Task.sleep(nanoseconds: 420_000_000)
        let baseURL = URL(string: "https://www.doordash.com/")
        return [
            FoodRecommendation(name: "Seasonal Veggie Box", price: 18.99, storeName: "Green Harvest Market", notes: "Local produce for 4 meals", doorDashURL: baseURL),
            FoodRecommendation(name: "Lean Protein Pack", price: 24.49, storeName: "Fresh Fare Co-op", notes: "Chicken, tofu, beans assortment", doorDashURL: baseURL),
            FoodRecommendation(name: "Budget Pantry Essentials", price: 12.79, storeName: "Budget Bites Market", notes: "Whole grains, legumes, spices", doorDashURL: baseURL)
        ]
    }
}
