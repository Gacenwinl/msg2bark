import SwiftUI
import SwiftData

@MainActor
class PushMessageViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService.shared
    private var hasSavedHistory = false  // 添加标记，用于跟踪是否已保存历史记录
    
    func sendMessage(_ message: PushMessage, settings: AppSettings, modelContext: ModelContext, configNames: [String]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await networkService.sendPushMessage(message, settings: settings)
            
            // 只在第一次发送成功时保存历史记录
            if !hasSavedHistory {
                let historyItem = PushHistoryItem(
                    id: message.id,
                    title: message.title,
                    content: message.content,
                    sound: message.sound,
                    url: message.url,
                    group: message.group,
                    isArchiveInReceiver: message.isArchiveMessage,
                    configNames: configNames  // 包含所有接收端的名称
                )
                modelContext.insert(historyItem)
                try? modelContext.save()
                hasSavedHistory = true  // 标记已保存
            }
            
        } catch NetworkError.invalidURL {
            errorMessage = "无效的URL地址"
        } catch NetworkError.invalidResponse {
            errorMessage = "服务器响应无效"
        } catch NetworkError.requestFailed(let error) {
            errorMessage = "请求失败: \(error)"
        } catch NetworkError.encryptionFailed {
            errorMessage = "加密失败"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // 添加重置方法
    func reset() {
        hasSavedHistory = false
        errorMessage = nil
        isLoading = false
    }
} 