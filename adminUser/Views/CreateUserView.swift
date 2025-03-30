//
//  CreateUserView.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import SwiftUI
import UIKit

struct CreateUserView: View {
    @ObservedObject var viewModel: CreateUserViewModel
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("create_user".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    VStack(spacing: 20) {
                        FormFieldView(
                            title: "name".localized,
                            text: $viewModel.name,
                            isValid: viewModel.nameValidation.isValid,
                            errorMessage: viewModel.nameValidation.errorMessage
                        )
                        
                        FormFieldView(
                            title: "email".localized,
                            text: $viewModel.email,
                            isValid: viewModel.emailValidation.isValid,
                            errorMessage: viewModel.emailValidation.errorMessage
                        )
                        
                        FormFieldView(
                            title: "phone".localized,
                            text: $viewModel.phone,
                            isValid: viewModel.phoneValidation.isValid,
                            errorMessage: viewModel.phoneValidation.errorMessage
                        )
                        
                        Button(action: {
                            viewModel.requestLocation()
                        }) {
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundColor(.white)
                                Text("get_location".localized)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        
                        if viewModel.showLocationCoordinates, let location = viewModel.currentLocation {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.green)
                                
                                Text(String(format: "location_coordinates".localized,
                                            String(format: "%.4f", location.coordinate.latitude),
                                            String(format: "%.4f", location.coordinate.longitude)))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.vertical)
                    
                    Spacer(minLength: 40)
                    
                    // Botón de envío
                    Button(action: {
                        viewModel.createUser()
                    }) {
                        Text("save".localized)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canSubmit ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!viewModel.canSubmit)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            
            // Indicador de carga
            if viewModel.isLoading {
                LoadingView()
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
            
            // Mensaje de error
            if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
            }
        }
        .navigationTitle("create_user".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    viewModel.navigateBack()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("cancel".localized)
                    }
                }
            }
        }
        .alert(isPresented: $viewModel.showLocationAlert) {
            if viewModel.locationErrorMessage?.contains("denied") == true {
                // Alerta para permisos denegados, con botón para ir a Configuración
                return Alert(
                    title: Text("location_permission_title".localized),
                    message: Text(viewModel.locationErrorMessage ?? "location_permission_denied".localized),
                    primaryButton: .default(Text("openSettings".localized)) {
                        // Abrir configuración de la app
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel(Text("cancel".localized))
                )
            } else {
                // Alerta informativa normal
                return Alert(
                    title: Text("location_permission_title".localized),
                    message: Text(viewModel.locationErrorMessage ?? "location_permission_message".localized),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
} 
