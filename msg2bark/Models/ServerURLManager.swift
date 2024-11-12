import Foundation

class ServerURLManager: ObservableObject {
    @Published var recentURLs: [String] {
        didSet {
            UserDefaults.standard.set(recentURLs, forKey: "recentServerURLs")
        }
    }
    
    init() {
        self.recentURLs = UserDefaults.standard.stringArray(forKey: "recentServerURLs") ?? ["https://api.day.app"]
    }
    
    func addRecentURL(_ url: String) {
        guard !url.isEmpty else { return }
        if let index = recentURLs.firstIndex(of: url) {
            recentURLs.remove(at: index)
        }
        recentURLs.insert(url, at: 0)
        if recentURLs.count > 5 {
            recentURLs = Array(recentURLs.prefix(5))
        }
        objectWillChange.send()
    }
    
    func clearHistory() {
        recentURLs = ["https://api.day.app"]
        objectWillChange.send()
    }
} 