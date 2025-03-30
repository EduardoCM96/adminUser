//
//  UserDetailViewModel.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

class UserDetailViewModel: ObservableObject {
    // Propiedades publicadas
    @Published var userValues: (name: String, email: String, username: String, phone: String, website: String)
    @Published var isEditing: Bool = false
    @Published var editedName: String = ""
    @Published var editedEmail: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    @Published var showDeleteConfirmation: Bool = false
    
    // Validación
    @Published var emailValidation: ValidationResult = ValidationResult.valid
    
    // Propiedades públicas
    let userId: Int
    
    // Propiedades privadas
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    private let realmManager = RealmManager.shared
    private let validationService = ValidationService.shared
    private let coordinator: AppCoordinator
    
    // Constructor con safe thread handling
    init(user: User, coordinator: AppCoordinator) {
        // Extraer los valores inmediatamente para evitar referencias cruzadas de hilos
        self.userId = user.id
        
        // Copiar todos los valores fuera de Realm
        let name = user.name
        let email = user.email
        let username = user.username
        let phone = user.phone
        let website = user.website
        
        self.userValues = (
            name: name,
            email: email,
            username: username,
            phone: phone,
            website: website
        )
        
        self.coordinator = coordinator
        
        // Configuración inicial de datos a editar
        self.editedName = name
        self.editedEmail = email
        
        // Suscripción para validación
        $editedEmail
            .map { [weak self] email -> ValidationResult in
                guard let self = self else { return ValidationResult.valid }
                return self.validationService.validateEmail(email)
            }
            .assign(to: \.emailValidation, on: self)
            .store(in: &cancellables)
    }
    
    func toggleEditMode() {
        isEditing.toggle()
        
        if isEditing {
            editedName = userValues.name
            editedEmail = userValues.email
        }
    }
    
    func saveChanges() {
        // Validación antes de guardar
        let emailResult = validationService.validateEmail(editedEmail)
        if !emailResult.isValid {
            self.emailValidation = emailResult
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Capturar valores fuera del closure para evitar referencias de hilo
        let userId = self.userId
        let newName = self.editedName
        let newEmail = self.editedEmail
        
        // ⚠️ IMPORTANTE: Toda operación Realm debe estar dentro de un dispatch a main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Crear un nuevo Realm en este hilo específico
                let realm = try Realm()
                
                // Buscar el usuario
                guard let userToUpdate = realm.object(ofType: User.self, forPrimaryKey: userId) else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "No se pudo encontrar el usuario"
                    }
                    return
                }
                
                // Hacer cambios en una transacción
                try realm.write {
                    userToUpdate.name = newName
                    userToUpdate.email = newEmail
                }
                
                // Actualizar los valores locales (en el hilo principal)
                DispatchQueue.main.async {
                    self.userValues.name = newName
                    self.userValues.email = newEmail
                    
                    // Llamada a API simulada
                    self.simulateApiCall(userId: userId, name: newName, email: newEmail)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Error al guardar: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func simulateApiCall(userId: Int, name: String, email: String) {
        // Crear un objeto sin conexión a Realm para la API
        let updatedUser = User()
        updatedUser.id = userId
        updatedUser.name = name
        updatedUser.email = email
        updatedUser.username = self.userValues.username
        updatedUser.phone = self.userValues.phone
        updatedUser.website = self.userValues.website
        
        apiService.updateUser(updatedUser)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.isEditing = false
                self.showSuccessMessage = true
                self.successMessage = "user_updated".localized
                
                // Ocultar mensaje después de 2 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showSuccessMessage = false
                }
            })
            .store(in: &cancellables)
    }
    
    func confirmDelete() {
        showDeleteConfirmation = true
    }
    
    func deleteUser() {
        isLoading = true
        errorMessage = nil
        
        // Capturar el ID del usuario
        let userId = self.userId
        
        // Llamar a la API primero
        apiService.deleteUser(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showDeleteConfirmation = false
                }
            }, receiveValue: { [weak self] success in
                guard let self = self, success else {
                    self?.isLoading = false
                    self?.showDeleteConfirmation = false
                    return
                }
                
                // Si la API tiene éxito, actualizar localmente (en el hilo principal)
                DispatchQueue.main.async {
                    do {
                        // Crear un nuevo Realm en este hilo específico
                        let realm = try Realm()
                        
                        if let userToDelete = realm.object(ofType: User.self, forPrimaryKey: userId) {
                            try realm.write {
                                userToDelete.isDeleted = true
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.showDeleteConfirmation = false
                            self.navigateBack()
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = "Error al eliminar: \(error.localizedDescription)"
                            self.showDeleteConfirmation = false
                        }
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    func navigateBack() {
        coordinator.navigateBack()
    }
    
    func canSave() -> Bool {
        return emailValidation.isValid &&
               !editedName.isEmpty &&
               (editedName != userValues.name || editedEmail != userValues.email)
    }
} 
