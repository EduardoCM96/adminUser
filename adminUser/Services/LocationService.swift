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
        print("📱 Solicitando permisos de localización...")
        
        if !CLLocationManager.locationServicesEnabled() {
            locationError = .denied
            locationSubject.send(completion: .failure(.denied))
            return
        }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = .denied
            locationSubject.send(completion: .failure(.denied))
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        @unknown default:
            locationError = .unknown
            locationSubject.send(completion: .failure(.unknown))
        }
    }
    
    func getCurrentLocation() -> AnyPublisher<CLLocation, LocationError> {
        let publisher = PassthroughSubject<CLLocation, LocationError>()
        
        if !CLLocationManager.locationServicesEnabled() {
            publisher.send(completion: .failure(.denied))
            return publisher.eraseToAnyPublisher()
        }
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            publisher.send(completion: .failure(.denied))
        @unknown default:
            publisher.send(completion: .failure(.unknown))
        }
        
        locationSubject
            .sink(
                receiveCompletion: { completion in
                    publisher.send(completion: completion)
                },
                receiveValue: { location in
                    publisher.send(location)
                }
            )
            .store(in: &cancellables)
        
        return publisher.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationSubject.send(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        locationError = .unknown
        locationSubject.send(completion: .failure(.unknown))
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        statusSubject.send(authorizationStatus)
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            locationError = .denied
            locationSubject.send(completion: .failure(.denied))
        case .notDetermined:
            break
        @unknown default:
            locationError = .unknown
            locationSubject.send(completion: .failure(.unknown))
        }
    }
} 
