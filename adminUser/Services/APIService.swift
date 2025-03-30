//
//  APIService.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import Foundation
import Alamofire
import Combine

enum APIError: Error {
    case networkError
    case decodingError
    case invalidResponse
    case serverError(Int)
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Error decoding data"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

class APIService {
    static let shared = APIService()
    private let baseURL = "https://jsonplaceholder.typicode.com"
    
    private init() {}
    
    // MARK: - Users
    
    func getUsers() -> AnyPublisher<[User], APIError> {
        let url = "\(baseURL)/users"
        
        return AF.request(url, method: .get)
            .validate()
            .publishDecodable(type: [User].self)
            .map { response in
                return response.value ?? []
            }
            .mapError { error in
                if let afError = error as? AFError {
                    switch afError {
                    case .responseValidationFailed(let reason):
                        if case .unacceptableStatusCode(let statusCode) = reason {
                            return .serverError(statusCode)
                        }
                        return .invalidResponse
                    case .responseSerializationFailed:
                        return .decodingError
                    default:
                        return .networkError
                    }
                }
                return .unknown
            }
            .eraseToAnyPublisher()
    }
    
    func fetchUsers() async throws -> [User] {
        return try await withCheckedThrowingContinuation { continuation in
            let url = "\(baseURL)/users"
            
            AF.request(url, method: .get)
                .validate()
                .responseDecodable(of: [User].self) { response in
                    switch response.result {
                    case .success(let users):
                        continuation.resume(returning: users)
                    case .failure(let error):
                        var apiError: APIError = .unknown
                        if let afError = error as? AFError {
                            switch afError {
                            case .responseValidationFailed(let reason):
                                if case .unacceptableStatusCode(let statusCode) = reason {
                                    apiError = .serverError(statusCode)
                                } else {
                                    apiError = .invalidResponse
                                }
                            case .responseSerializationFailed:
                                apiError = .decodingError
                            default:
                                apiError = .networkError
                            }
                        }
                        continuation.resume(throwing: apiError)
                    }
                }
        }
    }
    
    func updateUser(_ user: User) -> AnyPublisher<User, APIError> {
        let url = "\(baseURL)/users/\(user.id)"
        
        return AF.request(url, method: .put, parameters: user, encoder: JSONParameterEncoder.default)
            .validate()
            .publishDecodable(type: User.self)
            .map { response in
                return response.value ?? user // En caso de simulación, devolvemos el usuario actualizado
            }
            .mapError { error in
                if let afError = error as? AFError {
                    switch afError {
                    case .responseValidationFailed(let reason):
                        if case .unacceptableStatusCode(let statusCode) = reason {
                            return .serverError(statusCode)
                        }
                        return .invalidResponse
                    case .responseSerializationFailed:
                        return .decodingError
                    default:
                        return .networkError
                    }
                }
                return .unknown
            }
            .eraseToAnyPublisher()
    }

    func createUser(_ user: User) -> AnyPublisher<User, APIError> {
        let url = "\(baseURL)/users"
        
        return AF.request(url, method: .post, parameters: user, encoder: JSONParameterEncoder.default)
            .validate()
            .publishDecodable(type: User.self)
            .map { response in
                return response.value ?? user
            }
            .mapError { error in
                if let afError = error as? AFError {
                    switch afError {
                    case .responseValidationFailed(let reason):
                        if case .unacceptableStatusCode(let statusCode) = reason {
                            return .serverError(statusCode)
                        }
                        return .invalidResponse
                    case .responseSerializationFailed:
                        return .decodingError
                    default:
                        return .networkError
                    }
                }
                return .unknown
            }
            .eraseToAnyPublisher()
    }
    
    func deleteUser(userId: Int) -> AnyPublisher<Bool, APIError> {
        let url = "\(baseURL)/users/\(userId)"
        
        return AF.request(url, method: .delete)
            .validate()
            .publishData()
            .map { _ in
                return true
            }
            .mapError { error in
                if let afError = error as? AFError {
                    switch afError {
                    case .responseValidationFailed(let reason):
                        if case .unacceptableStatusCode(let statusCode) = reason {
                            return .serverError(statusCode)
                        }
                        return .invalidResponse
                    default:
                        return .networkError
                    }
                }
                return .unknown
            }
            .eraseToAnyPublisher()
    }
}
