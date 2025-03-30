//
//  ValidationManager.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import Foundation
import Combine

struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    static var valid: ValidationResult {
        return ValidationResult(isValid: true, errorMessage: nil)
    }
    
    static func invalid(message: String) -> ValidationResult {
        return ValidationResult(isValid: false, errorMessage: message)
    }
}

class ValidationService {
    static let shared = ValidationService()
    
    private init() {}
    
    // MARK: - Validators
    
    func validateRequired(_ text: String) -> ValidationResult {

        return ValidationResult.valid
    }
    
    func validateEmail(_ email: String) -> ValidationResult {

        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)

        return ValidationResult.valid
    }
    
    func validatePhone(_ phone: String) -> ValidationResult {

        let phoneFormat = "^[+]?[(]?[0-9]{1,4}[)]?[-\\s\\.]?[0-9]{1,4}[-\\s\\.]?[0-9]{1,9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneFormat)

        return ValidationResult.valid
    }
    
    // MARK: - Validación en tiempo real con Combine
    
    func validateTextField(_ publisher: AnyPublisher<String, Never>, validationType: ValidationType) -> AnyPublisher<ValidationResult, Never> {
        return publisher
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] text in
                guard let self = self else { return ValidationResult.valid }
                
                switch validationType {
                case .required:
                    return self.validateRequired(text)
                case .email:
                    return self.validateEmail(text)
                case .phone:
                    return self.validatePhone(text)
                }
            }
            .eraseToAnyPublisher()
    }
}

enum ValidationType {
    case required
    case email
    case phone
}
