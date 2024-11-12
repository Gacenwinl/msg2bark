import Foundation

class GroupManager: ObservableObject {
    @Published var recentGroups: [String] {
        didSet {
            UserDefaults.standard.set(recentGroups, forKey: "recentGroups")
        }
    }
    
    init() {
        self.recentGroups = UserDefaults.standard.stringArray(forKey: "recentGroups") ?? []
    }
    
    func addRecentGroup(_ group: String) {
        guard !group.isEmpty else { return }
        if let index = recentGroups.firstIndex(of: group) {
            recentGroups.remove(at: index)
        }
        recentGroups.insert(group, at: 0)
        if recentGroups.count > 5 {
            recentGroups = Array(recentGroups.prefix(5))
        }
        objectWillChange.send()
    }
    
    func clearHistory() {
        recentGroups.removeAll()
        objectWillChange.send()
    }
} 