import Foundation
import CryptoKit

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(String)
    case encryptionFailed
}

class NetworkService {
    static let shared = NetworkService()
    private let cryptoService = CryptoService.shared
    
    func sendPushMessage(_ message: PushMessage, settings: AppSettings) async throws {
        guard var urlComponents = URLComponents(string: "\(settings.serverURL)/\(settings.pushKey)") else {
            throw NetworkError.invalidURL
        }
        
        var queryItems: [URLQueryItem] = []
        
        // 处理加密
        if settings.isEncryptionEnabled {
            let encryptedData = try cryptoService.encrypt(
                title: message.title,
                body: message.content,
                key: settings.pushKey
            )
            queryItems.append(URLQueryItem(name: "encrypt", value: "1"))
            queryItems.append(URLQueryItem(name: "data", value: encryptedData))
        } else {
            queryItems = [
                URLQueryItem(name: "title", value: message.title),
                URLQueryItem(name: "body", value: message.content)
            ]
        }
        
        // 添加其他参数
        if let sound = message.sound {
            queryItems.append(URLQueryItem(name: "sound", value: sound))
        }
        if let url = message.url {
            queryItems.append(URLQueryItem(name: "url", value: url))
        }
        if let group = message.group {
            queryItems.append(URLQueryItem(name: "group", value: group))
        }
        if let badge = message.badge {
            queryItems.append(URLQueryItem(name: "badge", value: String(badge)))
        }
        if let copy = message.copy {
            queryItems.append(URLQueryItem(name: "copy", value: copy))
        }
        if let level = message.level {
            queryItems.append(URLQueryItem(name: "level", value: level.rawValue))
        }
        if message.autoCopy {
            queryItems.append(URLQueryItem(name: "autoCopy", value: "1"))
        }
        if message.isLoopSound {
            queryItems.append(URLQueryItem(name: "isLoopSound", value: "1"))
        }
        
        // 设置是否在接收端保存消息
        queryItems.append(URLQueryItem(name: "isArchive", value: message.isArchiveMessage ? "1" : "0"))
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NetworkError.requestFailed(errorMessage)
        }
    }
} 