//
//  AppCoordinator.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import Foundation
import SwiftUI

enum AppRoute {
    case userList
    case userDetail(User)
    case createUser
    case settings
}

class AppCoordinator: ObservableObject {
    @Published var route: AppRoute = .userList
    private var navigationStack: [AppRoute] = []
    
    func navigate(to route: AppRoute) {
        navigationStack.append(self.route)
        self.route = route
    }
    
    func navigateBack() {
        if let previousRoute = navigationStack.popLast() {
            self.route = previousRoute
        }
    }
    
    @objc func navigateToUserList() {
        navigate(to: .userList)
    }
    
    @ViewBuilder
    func view(for route: AppRoute) -> some View {
        switch route {
        case .userList:
            UserListView(viewModel: UserListViewModel(coordinator: self))
        case .userDetail(let user):
            UserDetailView(viewModel: UserDetailViewModel(user: user, coordinator: self))
        case .createUser:
            CreateUserView(viewModel: CreateUserViewModel(coordinator: self))
        case .settings:
            SettingsViewImplementation(coordinator: self)
        }
    }
}
