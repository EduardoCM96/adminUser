//
//  UserListView.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import SwiftUI

struct UserListView: View {
    @ObservedObject var viewModel: UserListViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if viewModel.users.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("no_users_found".localized)
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                viewModel.navigateToCreateUser()
                            }) {
                                Text("add_user".localized)
                                    .fontWeight(.medium)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Lista de usuarios
                        List {
                            ForEach(viewModel.users) { user in
                                UserListItemView(user: user)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        viewModel.showUserDetail(user)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            viewModel.confirmDeleteUser(user)
                                        } label: {
                                            Label("delete".localized, systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                
                // Indicador de carga
                if viewModel.isLoading {
                    LoadingView()
                }
                
                // Mensaje de error
                if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
            }
            .navigationTitle("users_title".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.navigateToCreateUser()
                    }) {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.navigateToSettings()
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .onAppear {
                viewModel.loadUsers()
            }
            .alert("confirm".localized, isPresented: $viewModel.showDeleteConfirmation) {
                Button("cancel".localized, role: .cancel) { }
                Button("delete".localized, role: .destructive) {
                    viewModel.deleteUser()
                }
            } message: {
                Text("confirm_delete".localized)
            }
        }
    }
}

struct UserListItemView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(user.username)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(user.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Label(user.email, systemImage: "envelope")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 12) {
                Label(user.phone, systemImage: "phone")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if let address = user.address {
                    Label(address.city, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("loading".localized)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6).opacity(0.8))
            )
        }
    }
}

struct ErrorView: View {
    let message: String
    let dismissAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.red)
            .cornerRadius(8)
            .padding()
        }
    }
} 
