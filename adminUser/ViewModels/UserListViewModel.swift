//
//  UserListViewModel.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import Foundation
import Combine
import SwiftUI

class UserListViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation: Bool = false
    @Published var userToDelete: User?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    private let realmManager = RealmManager.shared
    private let coordinator: AppCoordinator
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        loadUsers() // Cargar usuarios inmediatamente al inicializar
    }
    
    func loadUsers() {
        isLoading = true
        errorMessage = nil
        loadLocalUsers()
        apiService.getUsers()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] users in
                self?.realmManager.saveUsers(users)
                self?.loadLocalUsers()
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }
    
    func loadLocalUsers() {
        let localUsers = realmManager.getAllUsers()
        self.users = localUsers.filter { !$0.isDeleted }
    }
    
    func showUserDetail(_ user: User) {
        coordinator.navigate(to: .userDetail(user))
    }
    
    func navigateToCreateUser() {
        coordinator.navigate(to: .createUser)
    }
    
    func confirmDeleteUser(_ user: User) {
        self.userToDelete = user
        self.showDeleteConfirmation = true
    }
    
    func deleteUser() {
        guard let user = userToDelete else { return }
        
        isLoading = true
        
        apiService.deleteUser(userId: user.id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
                self?.showDeleteConfirmation = false
            }, receiveValue: { [weak self] success in
                if success {
                    self?.realmManager.deleteUser(user)
                    self?.loadLocalUsers()
                }
                self?.showDeleteConfirmation = false
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }
    
    func navigateToSettings() {
        coordinator.navigate(to: .settings)
    }
} 
