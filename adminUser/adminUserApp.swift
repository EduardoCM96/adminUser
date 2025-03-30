//
//  adminUserApp.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import SwiftUI
import RealmSwift

@main
struct adminUserApp: SwiftUI.App {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    init() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // Preparado para futuras migraciones
                }
            },
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .environmentObject(localizationManager)
        }
    }
}
