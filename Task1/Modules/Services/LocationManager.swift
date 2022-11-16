//
//  LocationManager.swift
//  Task1
//
//  Created by Игорь Клюжев on 16.11.2022.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject {
    private let locationManager = CLLocationManager()

    override init() {
        locationManager.delegate = self
    }

    func requestAccess() {
        locationManager.requestAlwaysAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
}
