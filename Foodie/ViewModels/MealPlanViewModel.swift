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
    @Published var selectedTab: Tab = .places
    @Published private(set) var phase: Phase = .idle

    enum Tab { case places, foods }

    private let locationProvider: LocationProvider
    private let placesService: PlacesService
    private let foodsService: FoodRecommendationService
    private var cancellables: Set<AnyCancellable> = []

    init(locationProvider: LocationProvider = .shared,
         placesService: PlacesService = MockPlacesService(),
         foodsService: FoodRecommendationService = MockFoodRecommendationService()) {
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
            async let placesResult = placesService.fetchPlaces(near: coordinate)
            async let foodsResult = foodsService.fetchFoodRecommendations(near: coordinate)

            let (places, foods) = try await (placesResult, foodsResult)
            self.places = places.sorted(by: { $0.distanceMeters < $1.distanceMeters })
            self.foods = foods
            phase = .ready
            selectedTab = .places
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

