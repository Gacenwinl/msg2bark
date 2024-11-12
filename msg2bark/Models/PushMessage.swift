import Foundation

struct PushMessage: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let sound: String?
    let icon: String?
    let url: String?
    let group: String?
    let isArchive: Bool
    let timestamp: Date
    let badge: Int?
    let copy: String?
    let level: NotificationLevel?
    let autoCopy: Bool
    let isLoopSound: Bool
    let isArchiveMessage: Bool
    
    enum NotificationLevel: String, Codable {
        case active = "active"
        case timeSensitive = "timeSensitive"
        case passive = "passive"
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        sound: String? = nil,
        icon: String? = nil,
        url: String? = nil,
        group: String? = nil,
        isArchive: Bool? = nil,
        timestamp: Date = Date(),
        badge: Int? = nil,
        copy: String? = nil,
        level: NotificationLevel? = nil,
        autoCopy: Bool = false,
        isLoopSound: Bool = false,
        isArchiveMessage: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sound = sound
        self.icon = icon
        self.url = url
        self.group = group
        self.isArchive = isArchive ?? false
        self.timestamp = timestamp
        self.badge = badge
        self.copy = copy
        self.level = level
        self.autoCopy = autoCopy
        self.isLoopSound = isLoopSound
        self.isArchiveMessage = isArchiveMessage
    }
} 