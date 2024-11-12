import Foundation

class SoundManager: ObservableObject {
    static let defaultSounds = [
        "alarm", "anticipate", "bell", "birdsong", "bloom",
        "calypso", "chime", "choo", "descent", "electronic",
        "fanfare", "glass", "gotosleep", "healthnotification",
        "horn", "ladder", "mailsent", "minuet", "multiwayinvitation",
        "newmail", "newsflash", "noir", "paymentsuccess", "shake",
        "sherwoodforest", "silence", "spell", "suspense",
        "telegraph", "tiptoes", "typewriters", "update"
    ]
    
    @Published var recentSounds: [String] {
        didSet {
            UserDefaults.standard.set(recentSounds, forKey: "recentSounds")
        }
    }
    
    init() {
        self.recentSounds = UserDefaults.standard.stringArray(forKey: "recentSounds") ?? []
    }
    
    func addRecentSound(_ sound: String) {
        if let index = recentSounds.firstIndex(of: sound) {
            recentSounds.remove(at: index)
        }
        recentSounds.insert(sound, at: 0)
        if recentSounds.count > 5 {
            recentSounds = Array(recentSounds.prefix(5))
        }
        objectWillChange.send()
    }
    
    func clearHistory() {
        recentSounds.removeAll()
        objectWillChange.send()
    }
} 