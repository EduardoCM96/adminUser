//
//  LocalizationManager.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import Foundation
import Combine

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: Language = Language.getPreferredLanguage()
    
    static let shared = LocalizationManager()
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "userSelectedLanguage"),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            currentLanguage = Language.getPreferredLanguage()
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "userSelectedLanguage")
        }
        
        applyLanguage(currentLanguage)
    }
    
    func string(for key: String) -> String {
        let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj")
        let bundle = path != nil ? Bundle(path: path!) : Bundle.main
        
        return NSLocalizedString(key, tableName: "Localizable", bundle: bundle ?? Bundle.main, value: key, comment: "")
    }
    
    // Método estático para ser usado por la extensión String+Localized
    static func localizedString(for key: String) -> String {
        return shared.string(for: key)
    }
    
    func changeLanguage(to language: Language) {
        guard language != currentLanguage else { return }
        
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "userSelectedLanguage")
        UserDefaults.standard.synchronize()
        
        applyLanguage(language)
        
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)

        objectWillChange.send()
    }
    
    private func applyLanguage(_ language: Language) {
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        Bundle.setLanguage(language.rawValue)
    }
}

enum Language: String, CaseIterable {
    case english = "en"
    case spanish = "es"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
    
    static func getPreferredLanguage() -> Language {
        if let preferredLanguage = UserDefaults.standard.array(forKey: "AppleLanguages")?.first as? String {
            if preferredLanguage.starts(with: "es") {
                return .spanish
            }
        }
        
        let preferredLocale = Locale.preferredLanguages.first ?? "en"
        if preferredLocale.starts(with: "es") {
            return .spanish
        }
        
        return .english
    }
}

// Extensión para forzar el cambio de idioma en el Bundle
extension Bundle {
    private static var bundle: Bundle?
    
    static func setLanguage(_ language: String) {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else {
            bundle = Bundle.main
            return
        }
        bundle = Bundle(path: path)
    }
} 
