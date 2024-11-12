import Foundation
import SwiftData

@Model
final class PushHistoryItem: Identifiable {
    var id: UUID
    var title: String
    var content: String
    var sound: String?
    var icon: String?
    var url: String?
    var group: String?
    var isArchiveInReceiver: Bool
    var timestamp: Date
    var configNamesString: String
    
    var configNames: [String] {
        get { configNamesString.split(separator: "、").map(String.init) }
        set { configNamesString = newValue.joined(separator: "、") }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        sound: String? = nil,
        icon: String? = nil,
        url: String? = nil,
        group: String? = nil,
        isArchiveInReceiver: Bool = false,
        timestamp: Date = Date(),
        configNames: [String] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sound = sound
        self.icon = icon
        self.url = url
        self.group = group
        self.isArchiveInReceiver = isArchiveInReceiver
        self.timestamp = timestamp
        self.configNamesString = configNames.joined(separator: "、")
    }
} 