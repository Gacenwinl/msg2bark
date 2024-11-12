import Foundation
import CryptoKit

enum CryptoError: Error {
    case invalidKey
    case encryptionFailed
}

class CryptoService {
    static let shared = CryptoService()
    private init() {}
    
    func encrypt(title: String, body: String, key: String) throws -> String {
        // 1. 构造 JSON 字符串
        let content = """
        {"title":"\(title.escaped)","body":"\(body.escaped)"}
        """
        
        guard let contentData = content.data(using: .utf8),
              let keyData = key.data(using: .utf8) else {
            throw CryptoError.invalidKey
        }
        
        // 2. 使用 key 的 SHA256 作为加密密钥
        let keyHash = SHA256.hash(data: keyData)
        let symmetricKey = SymmetricKey(data: keyHash)
        
        // 3. 使用 AES-GCM 加密，nonce 长度为 12
        let nonce = try AES.GCM.Nonce(data: Data(count: 12))
        let box = try AES.GCM.seal(contentData, using: symmetricKey, nonce: nonce)
        
        // 4. 拼接 nonce 和 密文
        guard let ciphertext = box.ciphertext.base64EncodedString()
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let tag = box.tag.base64EncodedString()
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let nonceString = nonce.withUnsafeBytes({ Data(Array($0)) }).base64EncodedString()
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw CryptoError.encryptionFailed
        }
        
        // 5. 返回 base64(nonce:tag:ciphertext)
        return "\(nonceString):\(tag):\(ciphertext)"
    }
}

// 处理 JSON 字符串中的特殊字符
extension String {
    var escaped: String {
        return self.replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
} 