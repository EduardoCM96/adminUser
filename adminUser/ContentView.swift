//
//  ContentView.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationView {
            coordinator.view(for: coordinator.route)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppCoordinator())
            .environmentObject(LocalizationManager.shared)
    }
}
#endif
