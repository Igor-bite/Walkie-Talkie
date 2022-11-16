//
//  LocationManager.swift
//  Task1
//
//  Created by Игорь Клюжев on 16.11.2022.
//

import Foundation
import CoreLocation
import SPIndicator

final class LocationManager: NSObject {
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        return locationManager
    }()
    private(set) var currentLocation: CLLocation?
    var locationUpdated: ((CLLocation) -> Void)?

    private func requestAccess() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        requestAccess()
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch CLLocationManager.authorizationStatus() {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .notDetermined, .restricted:
            currentLocation = nil
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude

            let newLocation = CLLocation(latitude: latitude, longitude: longitude)
            currentLocation = newLocation
            locationUpdated?(newLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        SPIndicator.present(title: error.localizedDescription, preset: .error)
    }
}
