import Foundation

extension String {
    var localized: String {
        // Usar el lenguaje actual guardado en UserDefaults
        let currentLang = UserDefaults.standard.string(forKey: "userSelectedLanguage") ?? "en"
        let path = Bundle.main.path(forResource: currentLang, ofType: "lproj")
        let bundle = path != nil ? Bundle(path: path!) : Bundle.main
        
        return NSLocalizedString(self, tableName: "Localizable", bundle: bundle ?? Bundle.main, value: self, comment: "")
    }
    
    func localized(withComment comment: String) -> String {
        let currentLang = UserDefaults.standard.string(forKey: "userSelectedLanguage") ?? "en"
        let path = Bundle.main.path(forResource: currentLang, ofType: "lproj")
        let bundle = path != nil ? Bundle(path: path!) : Bundle.main
        
        return NSLocalizedString(self, tableName: "Localizable", bundle: bundle ?? Bundle.main, value: self, comment: comment)
    }
} 