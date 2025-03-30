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
    @Published var searchText: String = ""
    @Published var showDeleteConfirmation: Bool = false
    @Published var userToDelete: User?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    private let realmManager = RealmManager.shared
    private let coordinator: AppCoordinator
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterUsers()
            }
            .store(in: &cancellables)
    }
    
    func loadUsers() {
        isLoading = true
        errorMessage = nil
        
        apiService.getUsers()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    // En caso de error, intentamos cargar desde local
                    self?.loadLocalUsers()
                }
            }, receiveValue: { [weak self] users in
                self?.realmManager.saveUsers(users)
                self?.loadLocalUsers()
            })
            .store(in: &cancellables)
    }
    
    func loadLocalUsers() {
        let localUsers = realmManager.getAllUsers()
        self.users = localUsers.filter { !$0.isDeleted }
    }
    
    func filterUsers() {
        if searchText.isEmpty {
            loadLocalUsers()
        } else {
            let filteredUsers = realmManager.getAllUsers().filter { user in
                let searchLowercased = searchText.lowercased()
                return user.name.lowercased().contains(searchLowercased) ||
                       user.username.lowercased().contains(searchLowercased) ||
                       user.email.lowercased().contains(searchLowercased)
            }
            self.users = filteredUsers
        }
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
            })
            .store(in: &cancellables)
    }
    
    func navigateToSettings() {
        coordinator.navigate(to: .settings)
    }
} 
