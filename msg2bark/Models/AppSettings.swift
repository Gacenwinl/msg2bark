import Foundation

class AppSettings: ObservableObject {
    @Published var pushKey: String {
        didSet {
            UserDefaults.standard.set(pushKey, forKey: "pushKey")
        }
    }
    
    @Published var isEncryptionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEncryptionEnabled, forKey: "isEncryptionEnabled")
        }
    }
    
    @Published var serverURL: String {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: "serverURL")
        }
    }
    
    init() {
        self.pushKey = UserDefaults.standard.string(forKey: "pushKey") ?? ""
        self.isEncryptionEnabled = UserDefaults.standard.bool(forKey: "isEncryptionEnabled")
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? "https://api.day.app"
    }
} 