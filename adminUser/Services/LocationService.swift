//
//  LocationService.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import Foundation
import CoreLocation
import Combine
import SwiftUI

enum LocationError: Error, LocalizedError {
    case denied
    case restricted
    case unknown
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .denied:
            return NSLocalizedString("location_permission_denied", tableName: "Localizable", bundle: Bundle.main, value: "Location access denied", comment: "")
        case .restricted:
            return NSLocalizedString("location_permission_denied", tableName: "Localizable", bundle: Bundle.main, value: "Location access denied", comment: "")
        case .unknown:
            return "Error getting location"
        case .timeout:
            return "Location request timed out. Please try again."
        }
    }
}

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private var locationSubject = PassthroughSubject<CLLocation, LocationError>()
    private var statusSubject = PassthroughSubject<CLAuthorizationStatus, Never>()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var locationError: LocationError?
    
    var locationPublisher: AnyPublisher<CLLocation, LocationError> {
        return locationSubject.eraseToAnyPublisher()
    }
    
    var statusPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    override private init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        DispatchQueue.global().async {
            if !CLLocationManager.locationServicesEnabled() {
                DispatchQueue.main.async {
                    self.locationError = .denied
                    self.locationSubject.send(completion: .failure(.denied))
                }
                return
            }
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            self.locationError = .denied
            self.locationSubject.send(completion: .failure(.denied))
        case .authorizedWhenInUse, .authorizedAlways:
            self.getCurrentLocation()
        @unknown default:
            self.locationError = .unknown
            self.locationSubject.send(completion: .failure(.unknown))
        }
    }
    
    func getCurrentLocation() {
        locationManager.requestLocation()
    }
    
    private var cancellables = Set<AnyCancellable>()
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
            self.locationSubject.send(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = .denied
                    self.locationSubject.send(completion: .failure(.denied))
                case .locationUnknown:
                    self.locationError = .unknown
                    self.locationSubject.send(completion: .failure(.unknown))
                default:
                    self.locationError = .unknown
                    self.locationSubject.send(completion: .failure(.unknown))
                }
            } else {
                self.locationError = .unknown
                self.locationSubject.send(completion: .failure(.unknown))
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            self.statusSubject.send(self.authorizationStatus)
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.getCurrentLocation()
            case .denied, .restricted:
                self.locationError = .denied
                self.locationSubject.send(completion: .failure(.denied))
            case .notDetermined:
                break
            @unknown default:
                self.locationError = .unknown
                self.locationSubject.send(completion: .failure(.unknown))
            }
        }
    }
} 
