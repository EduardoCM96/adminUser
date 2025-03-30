import SwiftUI

// Hacemos un alias temporal para los tipos que necesitamos
typealias AppSettingsView = SettingsViewImplementation

struct SettingsViewImplementation: View {
    let coordinator: AppCoordinator
    @State private var currentLanguage: String = UserDefaults.standard.string(forKey: "userSelectedLanguage") ?? "en"
    
    var body: some View {
        Form {
            Section(header: Text("Idioma".localized)) {
                Button(action: {
                    let newLanguage = currentLanguage == "en" ? "es" : "en"
                    UserDefaults.standard.set(newLanguage, forKey: "userSelectedLanguage")
                    UserDefaults.standard.synchronize()
                    
                    NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
                    
                    currentLanguage = newLanguage
                }) {
                    HStack {
                        Text(currentLanguage == "en" ? "English" : "Español")
                        Spacer()
                        Image(systemName: "arrow.left.arrow.right")
                        Text(currentLanguage == "en" ? "Español" : "English")
                    }
                    .padding()
                }
                
                Text("language_restart_notice".localized)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("about".localized)) {
                HStack {
                    Text("version".localized)
                    Spacer()
                    Text("1.0.0")
                }
                
                HStack {
                    Text("developer".localized)
                    Spacer()
                    Text("Eduardo Carranza Maqueda")
                }
            }
            
            Section {
                Button(action: {
                    coordinator.navigate(to: .userList)
                }) {
                    HStack {
                        Spacer()
                        Text("back_to_users".localized)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("settings".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    coordinator.navigate(to: .userList)
                }) {
                    Image(systemName: "chevron.left")
                    Text("back".localized)
                }
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsViewImplementation(coordinator: AppCoordinator())
        }
    }
}
#endif 
