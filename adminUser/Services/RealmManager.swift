//
//  RealmManager.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import Foundation
import RealmSwift
import Combine

final class RealmManager {
    static let shared = RealmManager()
    
    private init() {
        // Configuración básica de Realm
        do {
            let config = Realm.Configuration(
                schemaVersion: 1,
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 1 {
                        // Preparado para futuras migraciones
                    }
                },
                deleteRealmIfMigrationNeeded: true // Solo usar en desarrollo
            )
            
            // Establecer la configuración global
            Realm.Configuration.defaultConfiguration = config
        } catch {
            print("Error inicializando Realm: \(error)")
        }
    }
    
    // MARK: - Thread Safe Access
    
    /// Obtiene una instancia de Realm segura para el hilo actual
    func getRealm() -> Realm? {
        do {
            return try Realm()
        } catch {
            print("Error abriendo Realm: \(error)")
            return nil
        }
    }
    
    /// Ejecuta una acción con un objeto Realm en el hilo principal
    func executeOnMainThread<T>(action: @escaping (Realm) -> T) -> T? {
        if Thread.isMainThread {
            guard let realm = getRealm() else {
                return nil
            }
            return action(realm)
        } else {
            var result: T?
            let semaphore = DispatchSemaphore(value: 0)
            
            DispatchQueue.main.async {
                guard let realm = self.getRealm() else {
                    semaphore.signal()
                    return
                }
                result = action(realm)
                semaphore.signal()
            }
            
            semaphore.wait()
            return result
        }
    }
    
    /// Ejecuta una acción con un objeto Realm en el hilo principal de forma asíncrona
    func executeOnMainThreadAsync<T>(action: @escaping (Realm) -> T, completion: @escaping (T?) -> Void) {
        DispatchQueue.main.async {
            guard let realm = self.getRealm() else {
                completion(nil)
                return
            }
            let result = action(realm)
            completion(result)
        }
    }
    
    // MARK: - Users
    
    func saveUsers(_ users: [User]) {
        executeOnMainThreadAsync(action: { realm in
            var savedCount = 0
            
            do {
                try realm.write {
                    for user in users {
                        let existingUser = realm.object(ofType: User.self, forPrimaryKey: user.id)
                        if let existingUser = existingUser, !existingUser.isDeleted {
                            existingUser.username = user.username
                            if existingUser.company == nil {
                                existingUser.company = user.company
                            }
                            if existingUser.address == nil {
                                existingUser.address = user.address
                            }
                            if existingUser.website.isEmpty {
                                existingUser.website = user.website
                            }
                        } else if existingUser == nil {
                            realm.add(user)
                        }
                        savedCount += 1
                    }
                }
            } catch {
                print("Error saving users to Realm: \(error)")
            }
            
            return savedCount
        }) { count in
            if let count = count {
                print("Saved \(count) users")
            }
        }
    }
    
    func getAllUsers() -> [User] {
        return executeOnMainThread(action: { realm in
            let users = realm.objects(User.self).filter("isDeleted == false")
            return Array(users)
        }) ?? []
    }
    
    func getUser(byId id: Int) -> User? {
        return executeOnMainThread(action: { realm in
            return realm.object(ofType: User.self, forPrimaryKey: id)!
        })
    }
    
    func saveUser(_ user: User) {
        // Dado que el objeto ya está disponible, simplemente creamos una copia segura
        executeOnMainThreadAsync(action: { realm in
            do {
                // Crear una copia limpia del objeto para guardar
                let newUser = User()
                newUser.id = user.id
                newUser.name = user.name
                newUser.email = user.email
                newUser.username = user.username
                newUser.phone = user.phone
                newUser.website = user.website
                newUser.isDeleted = user.isDeleted
                newUser.isLocalOnly = user.isLocalOnly
                
                // Si el objeto original tiene address y company, también los copiamos
                if let address = user.address {
                    let newAddress = Address()
                    newAddress.street = address.street
                    newAddress.suite = address.suite
                    newAddress.city = address.city
                    newAddress.zipcode = address.zipcode
                    newAddress.lat = address.lat
                    newAddress.lng = address.lng
                    newUser.address = newAddress
                }
                
                if let company = user.company {
                    let newCompany = Company()
                    newCompany.name = company.name
                    newCompany.catchPhrase = company.catchPhrase
                    newCompany.bs = company.bs
                    newUser.company = newCompany
                }
                
                try realm.write {
                    realm.add(newUser, update: .modified)
                }
                return true
            } catch {
                print("Error saving user to Realm: \(error)")
                return false
            }
        }) { success in
            print("User save operation completed: \(success == true)")
        }
    }
    
    func updateUser(_ user: User) {
        executeOnMainThreadAsync(action: { realm in
            do {
                // Crear una copia limpia del objeto para actualizar
                let updatedUser = User()
                updatedUser.id = user.id
                updatedUser.name = user.name
                updatedUser.email = user.email
                updatedUser.username = user.username
                updatedUser.phone = user.phone
                updatedUser.website = user.website
                
                // Si el objeto original tiene address y company, también los copiamos
                if let address = user.address {
                    let newAddress = Address()
                    newAddress.street = address.street
                    newAddress.suite = address.suite
                    newAddress.city = address.city
                    newAddress.zipcode = address.zipcode
                    newAddress.lat = address.lat
                    newAddress.lng = address.lng
                    updatedUser.address = newAddress
                }
                
                if let company = user.company {
                    let newCompany = Company()
                    newCompany.name = company.name
                    newCompany.catchPhrase = company.catchPhrase
                    newCompany.bs = company.bs
                    updatedUser.company = newCompany
                }
                
                try realm.write {
                    realm.add(updatedUser, update: .modified)
                }
                return true
            } catch {
                print("Error updating user in Realm: \(error)")
                return false
            }
        }) { success in
            print("User update operation completed: \(success == true)")
        }
    }
    
    func deleteUser(_ user: User) {
        executeOnMainThreadAsync(action: { realm in
            do {
                // Asegurarnos de que obtenemos una referencia fresca de Realm al objeto
                guard let userToDelete = realm.object(ofType: User.self, forPrimaryKey: user.id) else {
                    print("No se pudo encontrar el usuario para eliminar")
                    return false
                }
                
                try realm.write {
                    userToDelete.isDeleted = true
                }
                return true
            } catch {
                print("Error deleting user from Realm: \(error)")
                return false
            }
        }) { success in
            print("User delete operation completed: \(success == true)")
        }
    }
    
    func getNextUserId() -> Int {
        return executeOnMainThread(action: { realm in
            if let maxIdUser = realm.objects(User.self).max(ofProperty: "id") as Int? {
                return maxIdUser + 1
            } else {
                return 1
            }
        }) ?? 1
    }
}
