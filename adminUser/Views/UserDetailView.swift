//
//  UserDetailView.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import SwiftUI
import RealmSwift

struct UserDetailView: View {
    @ObservedObject var viewModel: UserDetailViewModel
    @State private var addressValues: (street: String, suite: String, city: String, zipcode: String, lat: String, lng: String)?
    @State private var companyValues: (name: String, catchPhrase: String, bs: String)?
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Foto de perfil
                    HStack {
                        Spacer()
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.blue)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                        Spacer()
                    }
                    .padding(.top)
                    
                    // Información básica
                    InfoSectionView(title: "") {
                        if viewModel.isEditing {
                            // Campos editables
                            VStack(alignment: .leading, spacing: 16) {
                                FormFieldView(
                                    title: "name".localized,
                                    text: $viewModel.editedName,
                                    isValid: true,
                                    errorMessage: nil
                                )
                                
                                FormFieldView(
                                    title: "email".localized,
                                    text: $viewModel.editedEmail,
                                    isValid: viewModel.emailValidation.isValid,
                                    errorMessage: viewModel.emailValidation.errorMessage
                                )
                            }
                        } else {
                            // Vista de solo lectura - usando valores del ViewModel
                            InfoRowView(title: "username".localized, value: viewModel.userValues.username)
                            InfoRowView(title: "name".localized, value: viewModel.userValues.name)
                            InfoRowView(title: "email".localized, value: viewModel.userValues.email)
                            InfoRowView(title: "phone".localized, value: viewModel.userValues.phone)
                            InfoRowView(title: "website".localized, value: viewModel.userValues.website)
                        }
                    }
                    
                    // Dirección - Datos extraídos de Realm de forma segura
                    if !viewModel.isEditing, let address = addressValues {
                        InfoSectionView(title: "address".localized) {
                            InfoRowView(title: "street".localized, value: address.street)
                            InfoRowView(title: "suite".localized, value: address.suite)
                            InfoRowView(title: "city".localized, value: address.city)
                            InfoRowView(title: "zipcode".localized, value: address.zipcode)
                            
                            if !address.lat.isEmpty && !address.lng.isEmpty {
                                InfoRowView(
                                    title: "location_coordinates".localized,
                                    value: String(format: "(%@, %@)", address.lat, address.lng)
                                )
                            }
                        }
                    }
                    
                    // Empresa - Datos extraídos de Realm de forma segura
                    if !viewModel.isEditing, let company = companyValues {
                        InfoSectionView(title: "company".localized) {
                            InfoRowView(title: "company_name".localized, value: company.name)
                            InfoRowView(title: "company_catchphrase".localized, value: company.catchPhrase)
                            InfoRowView(title: "company_bs".localized, value: company.bs)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            
            // Barra de botones
            VStack {
                Spacer()
                
                HStack {
                    // Botón para eliminar
                    if !viewModel.isEditing {
                        Button(action: {
                            viewModel.confirmDelete()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("delete".localized)
                            }
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                    
                    // Botón para editar o guardar
                    if viewModel.isEditing {
                        // Botón de cancelar
                        Button(action: {
                            viewModel.toggleEditMode()
                        }) {
                            Text("cancel".localized)
                                .padding()
                                .foregroundColor(.blue)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        // Botón de guardar
                        Button(action: {
                            viewModel.saveChanges()
                        }) {
                            Text("save".localized)
                                .padding()
                                .foregroundColor(.white)
                                .background(viewModel.canSave() ? Color.blue : Color.gray)
                                .cornerRadius(10)
                        }
                        .disabled(!viewModel.canSave())
                    } else {
                        // Botón de editar
                        Button(action: {
                            viewModel.toggleEditMode()
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("edit".localized)
                            }
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -5)
                )
            }
            
            // Mensaje de éxito
            if viewModel.showSuccessMessage {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        
                        Text(viewModel.successMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
                    .padding()
                    
                    Spacer().frame(height: 60)
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
        .navigationTitle("user_details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isEditing)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.isEditing {
                    Button("cancel".localized) {
                        viewModel.toggleEditMode()
                    }
                } else {
                    Button(action: {
                        viewModel.navigateBack()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("back".localized)
                        }
                    }
                }
            }
        }
        .alert("confirm".localized, isPresented: $viewModel.showDeleteConfirmation) {
            Button("cancel".localized, role: .cancel) { }
            Button("delete".localized, role: .destructive) {
                viewModel.deleteUser()
            }
        } message: {
            Text("confirm_delete".localized)
        }
        .onAppear {
            loadUserDetails()
        }
    }
    
    private func loadUserDetails() {
        // Cargar los detalles adicionales del usuario desde el ViewModel de forma segura (en hilo principal)
        DispatchQueue.main.async {
            do {
                // Crear un nuevo Realm en el hilo principal
                let realm = try Realm()
                
                // Usar autoreleasepool para liberar objetos después de usarlos
                autoreleasepool {
                    // Buscar el usuario por ID
                    guard let user = realm.object(ofType: User.self, forPrimaryKey: viewModel.userId) else {
                        print("No se encontró el usuario con ID: \(viewModel.userId)")
                        return
                    }
                    
                    // Extraer valores de address y company para evitar referencias persistentes
                    if let address = user.address {
                        // Crear una copia de los valores
                        self.addressValues = (
                            street: address.street,
                            suite: address.suite,
                            city: address.city,
                            zipcode: address.zipcode,
                            lat: address.lat,
                            lng: address.lng
                        )
                    }
                    
                    if let company = user.company {
                        // Crear una copia de los valores
                        self.companyValues = (
                            name: company.name,
                            catchPhrase: company.catchPhrase,
                            bs: company.bs
                        )
                    }
                }
            } catch {
                print("Error al cargar detalles: \(error.localizedDescription)")
            }
        }
    }
}

struct InfoSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            content
                .padding(.leading, 8)
            
            Divider()
        }
    }
}

struct InfoRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value.isEmpty ? "-" : value)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct FormFieldView: View {
    let title: String
    @Binding var text: String
    let isValid: Bool
    let errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField(title, text: $text)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
                )
            
            if let errorMessage = errorMessage, !isValid {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}
