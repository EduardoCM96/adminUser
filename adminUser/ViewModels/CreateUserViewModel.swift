//
//  CreateUserViewModel.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI

class CreateUserViewModel: ObservableObject {
    // Datos del formulario
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    
    // Estado de UI
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    @Published var canSubmit: Bool = false
    
    // Location
    @Published var showLocationAlert: Bool = false
    @Published var locationErrorMessage: String?
    @Published var currentLocation: CLLocation?
    @Published var showLocationCoordinates: Bool = false
    @Published var coordinatesText: String = ""
    
    // Validaciones
    @Published var nameValidation: ValidationResult = ValidationResult.valid
    @Published var emailValidation: ValidationResult = ValidationResult.valid
    @Published var phoneValidation: ValidationResult = ValidationResult.valid
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    private let realmManager = RealmManager.shared
    private let locationService = LocationService.shared
    private let validationService = ValidationService.shared
    private let coordinator: AppCoordinator
    
    private func monitorLocationAuthorizationStatus() {
        // Suscribirse a los cambios de estado de autorización
        locationService.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    self.showLocationAlert = false
                    
                case .denied, .restricted:
                    self.locationErrorMessage = NSLocalizedString("location_permission_denied", 
                                                                 tableName: "Localizable", 
                                                                 bundle: Bundle.main, 
                                                                 value: "Location access denied", 
                                                                 comment: "")
                    self.showLocationAlert = true
                    
                case .notDetermined:
                    self.locationErrorMessage = NSLocalizedString("location_permission_message", 
                                                                 tableName: "Localizable", 
                                                                 bundle: Bundle.main, 
                                                                 value: "Esta aplicación necesita acceder a tu ubicación para obtener tus coordenadas actuales.", 
                                                                 comment: "")
                    self.showLocationAlert = true
                    
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
            
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    if case .failure(let error) = completion {
                        self.locationErrorMessage = error.localizedDescription
                        self.showLocationAlert = true
                        self.showLocationCoordinates = false
                    }
                },
                receiveValue: { [weak self] location in
                    guard let self = self else { return }
                    self.currentLocation = location
                    self.showLocationCoordinates = true
                    self.showLocationAlert = false
                    self.coordinatesText = String(format: "Lat: %.4f, Long: %.4f",
                                                location.coordinate.latitude,
                                                location.coordinate.longitude)
                }
            )
            .store(in: &cancellables)
    }
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        
        setupValidations()
        Publishers.CombineLatest3($nameValidation, $emailValidation, $phoneValidation)
            .map { nameValidation, emailValidation, phoneValidation in
                return nameValidation.isValid && emailValidation.isValid && phoneValidation.isValid
                    && !self.name.isEmpty && !self.email.isEmpty && !self.phone.isEmpty
            }
            .assign(to: \.canSubmit, on: self)
            .store(in: &cancellables)

        monitorLocationAuthorizationStatus()
    }
    
    private func setupValidations() {
        $name
            .map { [weak self] name -> ValidationResult in
                guard let self = self else { return ValidationResult.valid }
                return self.validationService.validateRequired(name)
            }
            .assign(to: \.nameValidation, on: self)
            .store(in: &cancellables)
        
        $email
            .map { [weak self] email -> ValidationResult in
                guard let self = self else { return ValidationResult.valid }
                return self.validationService.validateEmail(email)
            }
            .assign(to: \.emailValidation, on: self)
            .store(in: &cancellables)
        
        $phone
            .map { [weak self] phone -> ValidationResult in
                guard let self = self else { return ValidationResult.valid }
                return self.validationService.validatePhone(phone)
            }
            .assign(to: \.phoneValidation, on: self)
            .store(in: &cancellables)
    }
    
    func createUser() {
        if !canSubmit {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let newUser = createUserObject()
        
        realmManager.saveUser(newUser)
        
        apiService.createUser(newUser)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] _ in
                self?.showSuccessMessage = true
                self?.successMessage = "user_created".localized
                
                self?.resetForm()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.showSuccessMessage = false
                    self?.navigateBack()
                }
            })
            .store(in: &cancellables)
    }
    
    private func createUserObject() -> User {
        let user = User()
        user.id = realmManager.getNextUserId()
        user.name = name
        user.username = name.lowercased().replacingOccurrences(of: " ", with: ".")
        user.email = email
        user.phone = phone
        user.website = ""
        user.isLocalOnly = true
        
        let address = Address()
        address.street = ""
        address.suite = ""
        address.city = ""
        address.zipcode = ""
        
        if let location = currentLocation {
            address.lat = String(location.coordinate.latitude)
            address.lng = String(location.coordinate.longitude)
        } else {
            address.lat = "0"
            address.lng = "0"
        }
        user.address = address
        
        let company = Company()
        company.name = ""
        company.catchPhrase = ""
        company.bs = ""
        user.company = company
        
        return user
    }
    
    func resetForm() {
        name = ""
        email = ""
        phone = ""
        currentLocation = nil
        showLocationCoordinates = false
    }
    
    func requestLocation() {
        showLocationCoordinates = false
        locationService.requestLocationPermission()
    }
    
    func navigateBack() {
        coordinator.navigateBack()
    }
}
