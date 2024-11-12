import SwiftUI

struct ConfigEditView: View {
    enum Mode {
        case add
        case edit(BarkConfig)
        
        var title: String {
            switch self {
            case .add: return "添加配置"
            case .edit: return "编辑配置"
            }
        }
    }
    
    let mode: Mode
    let onSave: (String, String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var pushKey: String = ""
    @State private var serverURL: String = "https://api.day.app"
    
    @EnvironmentObject private var storageManager: StorageManager
    @State private var isShowingURLHistory = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("配置名称", text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                    
                    TextField("推送密钥", text: $pushKey)
                        .textContentType(.none)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    VStack(alignment: .leading) {
                        TextField("服务器地址", text: $serverURL)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        if !storageManager.serverURLManager.recentURLs.isEmpty {
                            DisclosureGroup("最近使用", isExpanded: $isShowingURLHistory) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(storageManager.serverURLManager.recentURLs, id: \.self) { recentURL in
                                            Button(action: {
                                                serverURL = recentURL
                                            }) {
                                                Text(recentURL)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 15)
                                                            .fill(serverURL == recentURL ? Color.blue : Color.gray.opacity(0.2))
                                                    )
                                                    .foregroundColor(serverURL == recentURL ? .white : .primary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button("保存") {
                        onSave(name, pushKey, serverURL)
                        dismiss()
                    }
                    .disabled(name.isEmpty || pushKey.isEmpty || serverURL.isEmpty)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if case .edit(let config) = mode {
                    name = config.name
                    pushKey = config.pushKey
                    serverURL = config.serverURL
                }
            }
            .onDisappear {
                if !serverURL.isEmpty {
                    storageManager.serverURLManager.addRecentURL(serverURL)
                }
            }
        }
    }
} 