//
//  LocationProvider.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation
import CoreLocation
import Combine

final class LocationProvider: NSObject, ObservableObject {
    enum AuthorizationStatus {
        case notDetermined
        case denied
        case restricted
        case authorized
    }

    static let shared = LocationProvider()

    @Published private(set) var lastKnownLocation: CLLocation?
    @Published private(set) var status: AuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var cancellables: Set<AnyCancellable> = []

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100
        updateStatus(from: manager.authorizationStatus)
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    private func updateStatus(from authorizationStatus: CLAuthorizationStatus) {
        switch authorizationStatus {
        case .notDetermined:
            status = .notDetermined
        case .denied:
            status = .denied
        case .restricted:
            status = .restricted
        case .authorizedAlways, .authorizedWhenInUse:
            status = .authorized
        @unknown default:
            status = .restricted
        }
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateStatus(from: manager.authorizationStatus)
        if status == .authorized {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastKnownLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }
}
