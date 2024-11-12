import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var storageManager: StorageManager
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        sort: [SortDescriptor(\BarkConfig.createdAt, order: .reverse)],
        animation: .default
    ) private var configs: [BarkConfig]
    
    @State private var showingAddConfig = false
    @State private var showingEditConfig = false
    @State private var selectedConfig: BarkConfig?
    @State private var showingClearHistoryAlert = false
    @State private var clearHistoryType: HistoryType?
    
    enum HistoryType {
        case sounds, urls, groups, configs, serverURLs
        var title: String {
            switch self {
            case .sounds: return "提示音"
            case .urls: return "链接"
            case .groups: return "分组"
            case .configs: return "推送配置"
            case .serverURLs: return "服务器地址"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("推送配置")) {
                    if configs.isEmpty {
                        Text("尚未添加推送配置")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(configs) { config in
                            configRow(config)
                        }
                        .onDelete(perform: deleteConfigs)
                    }
                    
                    Button(action: { showingAddConfig = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加新配置")
                        }
                    }
                }
                
                Section(header: Text("安全设置")) {
                    Toggle("启用加密传输", isOn: $appSettings.isEncryptionEnabled)
                }
                
                DisclosureGroup("数据管理") {
                    Button(role: .destructive, action: { showClearHistory(.configs) }) {
                        Text("清空推送配置")
                    }
                    Button(role: .destructive, action: { showClearHistory(.sounds) }) {
                        Text("清除提示音历史")
                    }
                    Button(role: .destructive, action: { showClearHistory(.urls) }) {
                        Text("清除链接历史")
                    }
                    Button(role: .destructive, action: { showClearHistory(.groups) }) {
                        Text("清除分组历史")
                    }
                    Button(role: .destructive, action: { showClearHistory(.serverURLs) }) {
                        Text("清除服务器地址历史")
                    }
                }
                
                Section {
                    Link("访问Bark官网", destination: URL(string: "https://bark.day.app")!)
                    Link("访问作者主页", destination: URL(string: "https://gacenwinl.cn")!)
                } header: {
                    Text("关于")
                } footer: {
                    VStack(alignment: .center) {
                        Text("作者：DawnCity")
                        Text("https://gacenwinl.cn")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingAddConfig) {
                ConfigEditView(mode: .add) { name, key, url in
                    addConfig(name: name, pushKey: key, serverURL: url)
                }
            }
            .sheet(item: $selectedConfig) { config in
                ConfigEditView(mode: .edit(config)) { name, key, url in
                    updateConfig(config, name: name, pushKey: key, serverURL: url)
                }
            }
            .alert("确认清除", isPresented: $showingClearHistoryAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    clearHistory()
                }
            } message: {
                if let type = clearHistoryType {
                    Text("是否确认清除所有\(type.title)历史记录？此操作不可撤销。")
                }
            }
        }
    }
    
    private func configRow(_ config: BarkConfig) -> some View {
        HStack {
            Toggle(isOn: Binding(
                get: { config.isSelected },
                set: { newValue in
                    config.isSelected = newValue
                    try? modelContext.save()
                }
            )) { }
            .labelsHidden()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(config.name)
                    .font(.headline)
                Text(config.serverURL)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Menu {
                Button(action: { selectedConfig = config }) {
                    Label("编辑", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: { deleteConfig(config) }) {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func addConfig(name: String, pushKey: String, serverURL: String) {
        withAnimation {
            let config = BarkConfig(
                name: name,
                pushKey: pushKey,
                serverURL: serverURL,
                isSelected: configs.isEmpty
            )
            modelContext.insert(config)
            
            do {
                try modelContext.save()
            } catch {
                print("Error saving config: \(error)")
            }
        }
    }
    
    private func updateConfig(_ config: BarkConfig, name: String, pushKey: String, serverURL: String) {
        config.name = name
        config.pushKey = pushKey
        config.serverURL = serverURL
        try? modelContext.save()
    }
    
    private func deleteConfig(_ config: BarkConfig) {
        modelContext.delete(config)
        try? modelContext.save()
    }
    
    private func deleteConfigs(at offsets: IndexSet) {
        for index in offsets {
            let config = configs[index]
            deleteConfig(config)
        }
    }
    
    private func showClearHistory(_ type: HistoryType) {
        clearHistoryType = type
        showingClearHistoryAlert = true
    }
    
    private func clearHistory() {
        switch clearHistoryType {
        case .configs:
            for config in configs {
                modelContext.delete(config)
            }
            appSettings.pushKey = ""
            appSettings.serverURL = "https://api.day.app"
            try? modelContext.save()
        case .sounds:
            storageManager.clearSoundHistory()
        case .urls:
            storageManager.clearURLHistory()
        case .groups:
            storageManager.clearGroupHistory()
        case .serverURLs:
            storageManager.clearServerURLHistory()
        case .none:
            break
        }
    }
}
