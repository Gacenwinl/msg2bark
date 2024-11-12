import Foundation

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    // 使用 StateObject 来确保实例的唯一性和状态的持久性
    private let _soundManager = SoundManager()
    private let _urlManager = URLManager()
    private let _groupManager = GroupManager()
    private let _serverURLManager = ServerURLManager()
    
    var soundManager: SoundManager { _soundManager }
    var urlManager: URLManager { _urlManager }
    var groupManager: GroupManager { _groupManager }
    var serverURLManager: ServerURLManager { _serverURLManager }
    
    // 添加通知方法来触发更新
    func notifyUpdate() {
        objectWillChange.send()
    }
    
    private init() {}
    
    // 清除历史记录的方法
    func clearSoundHistory() {
        _soundManager.clearHistory()
        notifyUpdate()
    }
    
    func clearURLHistory() {
        _urlManager.clearHistory()
        notifyUpdate()
    }
    
    func clearGroupHistory() {
        _groupManager.clearHistory()
        notifyUpdate()
    }
    
    func clearServerURLHistory() {
        _serverURLManager.clearHistory()
        notifyUpdate()
    }
} 