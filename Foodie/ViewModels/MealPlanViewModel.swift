//
//  MealPlanViewModel.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation
import Combine
import CoreLocation
import MapKit

@MainActor
final class MealPlanViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case requestingLocation
        case loading
        case ready
        case failed(String)
        case permissionDenied
    }

    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @Published private(set) var places: [Place] = []
    @Published private(set) var foods: [FoodRecommendation] = []
    @Published var selectedTab: Tab = .places {
        didSet { tabDidChange(oldValue: oldValue, newValue: selectedTab) }
    }
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var isLoadingFoods = false

    enum Tab { case places, foods }

    private let locationProvider: LocationProvider
    private let placesService: PlacesService
    private let foodsService: FoodRecommendationService
    private var cancellables: Set<AnyCancellable> = []
    private var lastFoodFetchCoordinate: CLLocationCoordinate2D?

    init(locationProvider: LocationProvider = .shared,
         placesService: PlacesService = LocalSearchPlacesService(),
         foodsService: FoodRecommendationService = AIRecommendationService()) {
        self.locationProvider = locationProvider
        self.placesService = placesService
        self.foodsService = foodsService

        locationProvider.$status
            .sink { [weak self] newStatus in
                self?.handleAuthorizationChange(newStatus)
            }
            .store(in: &cancellables)

        locationProvider.$lastKnownLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
    }

    @discardableResult
    func startSearching() -> Phase {
        switch locationProvider.status {
        case .authorized:
            phase = .loading
            if let location = locationProvider.lastKnownLocation {
                Task { await fetchData(for: location.coordinate) }
            } else {
                locationProvider.startUpdating()
            }
        case .denied, .restricted:
            phase = .permissionDenied
        case .notDetermined:
            phase = .requestingLocation
            locationProvider.requestWhenInUseAuthorization()
        }
        return phase
    }

    func refreshData() {
        guard let location = locationProvider.lastKnownLocation else { return }
        Task { await fetchData(for: location.coordinate) }
    }

    private func tabDidChange(oldValue: Tab, newValue: Tab) {
        guard newValue == .foods,
              let location = locationProvider.lastKnownLocation else { return }

        let needsFetch = foods.isEmpty || coordinateDistance(lastFoodFetchCoordinate, location.coordinate) > 200
        if needsFetch && isLoadingFoods == false {
            Task { await fetchFoods(for: location.coordinate) }
        }
    }

    private func handleAuthorizationChange(_ status: LocationProvider.AuthorizationStatus) {
        switch status {
        case .authorized:
            if case .requestingLocation = phase {
                phase = .loading
                if let coordinate = locationProvider.lastKnownLocation?.coordinate {
                    Task { await fetchData(for: coordinate) }
                } else {
                    locationProvider.startUpdating()
                }
            }
        case .denied, .restricted:
            if phase != .idle {
                phase = .permissionDenied
            }
        case .notDetermined:
            break
        }
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        region = MKCoordinateRegion(center: location.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        Task { await fetchData(for: location.coordinate) }
    }

    private func fetchData(for coordinate: CLLocationCoordinate2D) async {
        phase = .loading
        do {
            let places = try await placesService.fetchPlaces(near: coordinate)
            self.places = places.sorted(by: { $0.distanceMeters < $1.distanceMeters })
            phase = .ready
            selectedTab = .places
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func fetchFoods(for coordinate: CLLocationCoordinate2D) async {
        isLoadingFoods = true
        do {
            let context = FoodRecommendationContext(
                dietaryPreferences: UserPreferencesStore.shared.loadDietaryPreferences(),
                favoriteCuisines: UserPreferencesStore.shared.loadFavoriteCuisines(),
                budgetNotes: UserPreferencesStore.shared.loadBudgetPreferences(),
                recentMeals: loadRecentMealSummaries(),
                nearbyPlaces: places
            )
            let foods = try await foodsService.fetchFoodRecommendations(near: coordinate, context: context)
            await MainActor.run {
                self.foods = foods
                self.isLoadingFoods = false
                self.lastFoodFetchCoordinate = coordinate
            }
        } catch {
            await MainActor.run {
                self.isLoadingFoods = false
            }
        }
    }

    private func loadRecentMealSummaries() -> [String] {
        let logs = FoodLogStore.shared.load().sorted(by: { $0.date > $1.date })
        return logs.prefix(5).map { entry in
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: entry.date)): \(entry.summary)"
        }
    }

    private func coordinateDistance(_ lhs: CLLocationCoordinate2D?, _ rhs: CLLocationCoordinate2D) -> CLLocationDistance {
        guard let lhs else { return .infinity }
        let first = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
        let second = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude)
        return first.distance(from: second)
    }
}

