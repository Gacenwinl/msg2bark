import Foundation
import SwiftData

@Model
final class BarkConfig {
    @Attribute(.unique) var id: UUID
    var name: String
    var pushKey: String
    var serverURL: String
    @Attribute(.externalStorage) var isSelected: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        pushKey: String,
        serverURL: String,
        isSelected: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.pushKey = pushKey
        self.serverURL = serverURL
        self.isSelected = isSelected
        self.createdAt = createdAt
    }
} 