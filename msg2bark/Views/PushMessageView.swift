import SwiftUI
import SwiftData

struct PushMessageView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PushMessageViewModel
    @EnvironmentObject private var storageManager: StorageManager
    
    @State private var message: String = ""
    @State private var title: String = ""
    @State private var sound: String = ""
    @State private var url: String = ""
    @State private var group: String = ""
    @State private var isShowingAdvancedOptions = false
    @State private var autoClearEnabled = true
    @FocusState private var focusedField: Field?
    @State private var showAllSounds = false
    @State private var isShowingSoundPicker = false
    @State private var isShowingURLHistory = false
    @State private var badge: String = ""
    @State private var copy: String = ""
    @State private var selectedLevel: PushMessage.NotificationLevel?
    @State private var autoCopy = false
    @State private var isLoopSound = false
    @State private var isArchiveMessage = false
    @State private var isShowingNotificationSettings = false
    @State private var isBottomButtonVisible = true
    
    // 添加一个 ScrollView 的 GeometryReader 引用
    @State private var scrollViewHeight: CGFloat = 0
    @State private var bottomButtonFrame: CGRect = .zero
    
    @Query private var configs: [BarkConfig]  // 添加配置查询
    
    enum Field: Hashable {
        case title, message, sound, url, group, badge, copyText
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("消息内容")) {
                    TextField("标题", text: $title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled()
                    
                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("请输入要推送的消息内容...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        TextEditor(text: $message)
                            .frame(height: 100)
                            .focused($focusedField, equals: .message)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                
                DisclosureGroup("高级选项", isExpanded: $isShowingAdvancedOptions) {
                    soundPickerSection
                    
                    urlSection
                    
                    groupSection
                }
                
                DisclosureGroup("通知设置", isExpanded: $isShowingNotificationSettings) {
                    TextField("角标数字", text: $badge)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .badge)
                        .submitLabel(.next)
                    
                    TextField("复制内容", text: $copy)
                        .textContentType(.none)
                        .focused($focusedField, equals: .copyText)
                        .submitLabel(.done)
                    
                    Picker("通知级别", selection: $selectedLevel) {
                        Text("默认").tag(Optional<PushMessage.NotificationLevel>.none)
                        Text("活跃").tag(Optional(PushMessage.NotificationLevel.active))
                        Text("时效性").tag(Optional(PushMessage.NotificationLevel.timeSensitive))
                        Text("被动").tag(Optional(PushMessage.NotificationLevel.passive))
                    }
                    
                    Toggle("自动复制内容", isOn: $autoCopy)
                        .tint(.blue)
                    
                    Toggle("自动保存消息通知", isOn: $isArchiveMessage)
                        .tint(.blue)
                }
                
                Section {
                    Toggle("发送后自动清除内容", isOn: $autoClearEnabled)
                        .tint(.blue)
                }
                
                Section {
                    Button(action: sendPushMessage) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("发送推送")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(message.isEmpty || viewModel.isLoading)
                }
                .id("bottomButton")
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ButtonFramePreferenceKey.self,
                            value: geometry.frame(in: .global)
                        )
                    }
                )
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollViewHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            )
            .onPreferenceChange(ButtonFramePreferenceKey.self) { frame in
                bottomButtonFrame = frame
            }
            .onPreferenceChange(ScrollViewHeightPreferenceKey.self) { height in
                scrollViewHeight = height
            }
            .onChange(of: isShowingAdvancedOptions) { oldValue, newValue in
                updateBottomButtonVisibility()
            }
            .onChange(of: isShowingNotificationSettings) { oldValue, newValue in
                updateBottomButtonVisibility()
            }
            .navigationTitle("发送推送")
            .alert("提示", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("确定", role: .cancel) { }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Button(action: moveToPreviousField) {
                            Image(systemName: "chevron.up")
                        }
                        .disabled(!hasPreviousField)
                        
                        Button(action: moveToNextField) {
                            Image(systemName: "chevron.down")
                        }
                        .disabled(!hasNextField)
                        
                        Spacer()
                        
                        Button("完成") {
                            focusedField = nil
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isBottomButtonVisible {
                        Button(action: sendPushMessage) {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .disabled(message.isEmpty || viewModel.isLoading)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private var hasPreviousField: Bool {
        guard let currentField = focusedField else { return false }
        return Field.allCases.firstIndex(of: currentField) != 0
    }
    
    private var hasNextField: Bool {
        guard let currentField = focusedField else { return false }
        return Field.allCases.firstIndex(of: currentField) != Field.allCases.count - 1
    }
    
    private func moveToPreviousField() {
        guard let currentIndex = Field.allCases.firstIndex(of: focusedField!),
              currentIndex > 0 else { return }
        focusedField = Field.allCases[currentIndex - 1]
    }
    
    private func moveToNextField() {
        guard let currentIndex = Field.allCases.firstIndex(of: focusedField!),
              currentIndex < Field.allCases.count - 1 else { return }
        focusedField = Field.allCases[currentIndex + 1]
    }
    
    private func sendPushMessage() {
        focusedField = nil
        
        // 获取所有选中的配置
        let selectedConfigs = configs.filter { $0.isSelected }
        
        // 如果没有选中的配置，显示提示
        guard !selectedConfigs.isEmpty else {
            viewModel.errorMessage = "请至少选择一个推送配置"
            return
        }
        
        // 创建消息
        let pushMessage = PushMessage(
            title: title,
            content: message,
            sound: sound.isEmpty ? nil : sound,
            url: url.isEmpty ? nil : url,
            group: group.isEmpty ? nil : group,
            isArchive: nil,
            badge: Int(badge),
            copy: copy.isEmpty ? nil : copy,
            level: selectedLevel,
            autoCopy: autoCopy,
            isLoopSound: isLoopSound,
            isArchiveMessage: isArchiveMessage
        )
        
        // 获取选中的配置名称
        let configNames = selectedConfigs.map { $0.name }
        
        // 重置 ViewModel 状态
        viewModel.reset()
        
        // 使用 Task Group 行发送消息
        Task { @MainActor in
            // 在主线程上获取加密设置
            let isEncryptionEnabled = appSettings.isEncryptionEnabled
            
            // 创建一个数组来存储所有的发送任务
            var sendTasks: [Task<Void, Never>] = []
            
            // 为每个配置创建一个发送任务
            for config in selectedConfigs {
                let task = Task { @MainActor in
                    // 为每个配置创建新的 AppSettings 实例
                    let settings = AppSettings()
                    settings.pushKey = config.pushKey
                    settings.serverURL = config.serverURL
                    settings.isEncryptionEnabled = isEncryptionEnabled
                    
                    // 发送消息
                    await viewModel.sendMessage(
                        pushMessage,
                        settings: settings,
                        modelContext: modelContext,
                        configNames: configNames
                    )
                }
                sendTasks.append(task)
            }
            
            // 等待所有任务完成
            for task in sendTasks {
                await task.value
            }
            
            // 所有消息发送完成后的处理
            if viewModel.errorMessage == nil {
                if !url.isEmpty {
                    storageManager.urlManager.addRecentURL(url)
                }
                if !group.isEmpty {
                    storageManager.groupManager.addRecentGroup(group)
                }
                
                // 如果启用了自动清除，清空输入
                if autoClearEnabled {
                    withAnimation {
                        title = ""
                        message = ""
                        sound = ""
                        url = ""
                        group = ""
                        badge = ""
                        copy = ""
                    }
                }
            }
        }
    }
    
    private var soundPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("提示音")
                Spacer()
                
                // 使用 ZStack 和 opacity 来处理切换动画
                ZStack(alignment: .trailing) {
                    // 选择提示音按钮
                    Group {
                        if sound.isEmpty {
                            Button(action: { isShowingSoundPicker = true }) {
                                HStack {
                                    Text("选择提示音")
                                        .foregroundColor(.gray)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.animation(.easeIn.delay(0.2)),
                                removal: .opacity.animation(.easeOut)
                            ))
                        }
                        
                        // 已选择状态
                        if !sound.isEmpty {
                            HStack(spacing: 12) {
                                Text(sound)
                                    .foregroundColor(.primary)
                                
                                // 清除按钮
                                Button(action: { 
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        sound = ""
                                        isLoopSound = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .frame(width: 20, height: 20)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                // 选择按钮
                                Button(action: { isShowingSoundPicker = true }) {
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.animation(.easeIn),
                                removal: .opacity.animation(.easeOut.delay(0.2))
                            ))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            if !sound.isEmpty {
                Toggle("持续响铃", isOn: $isLoopSound)
                    .tint(.blue)
            }
            
            if !storageManager.soundManager.recentSounds.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(storageManager.soundManager.recentSounds, id: \.self) { recentSound in
                            Button(action: {
                                sound = recentSound
                                storageManager.soundManager.addRecentSound(recentSound)
                            }) {
                                Text(recentSound)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(sound == recentSound ? Color.blue : Color.gray.opacity(0.2))
                                    )
                                    .foregroundColor(sound == recentSound ? .white : .primary)
                            }
                            .fixedSize()
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 40)
            }
        }
        .sheet(isPresented: $isShowingSoundPicker) {
            NavigationView {
                List {
                    Section(header: Text("最近使用")) {
                        ForEach(storageManager.soundManager.recentSounds, id: \.self) { sound in
                            soundPickerRow(sound)
                        }
                    }
                    
                    Section(header: Text("所有提示音")) {
                        ForEach(SoundManager.defaultSounds, id: \.self) { sound in
                            soundPickerRow(sound)
                        }
                    }
                }
                .navigationTitle("选择提示音")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            isShowingSoundPicker = false
                        }
                    }
                }
            }
        }
    }
    
    private func soundPickerRow(_ soundName: String) -> some View {
        Button(action: {
            sound = soundName
            storageManager.soundManager.addRecentSound(soundName)
            isShowingSoundPicker = false
        }) {
            HStack {
                Text(soundName)
                Spacer()
                if sound == soundName {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .foregroundColor(.primary)
    }
    
    private var groupSection: some View {
        VStack(alignment: .leading) {
            TextField("分组", text: $group)
                .focused($focusedField, equals: .group)
                .submitLabel(.done)
            
            if !storageManager.groupManager.recentGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(storageManager.groupManager.recentGroups, id: \.self) { recentGroup in
                            Button(action: {
                                group = recentGroup
                            }) {
                                Text(recentGroup)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(group == recentGroup ? Color.blue : Color.gray.opacity(0.2))
                                    )
                                    .foregroundColor(group == recentGroup ? .white : .primary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var urlSection: some View {
        VStack(alignment: .leading) {
            TextField("跳转链接", text: $url)
                .focused($focusedField, equals: .url)
                .submitLabel(.next)
                .keyboardType(.URL)
                .autocapitalization(.none)
            
            if !storageManager.urlManager.recentURLs.isEmpty {
                DisclosureGroup("最近使用", isExpanded: $isShowingURLHistory) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(storageManager.urlManager.recentURLs, id: \.self) { recentURL in
                                Button(action: {
                                    url = recentURL
                                }) {
                                    Text(recentURL)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(url == recentURL ? Color.blue : Color.gray.opacity(0.2))
                                        )
                                        .foregroundColor(url == recentURL ? .white : .primary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private func updateBottomButtonVisibility() {
        let screenHeight = UIScreen.main.bounds.height
        
        // 使用新的 API 获取窗口
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let safeAreaInsets = window.safeAreaInsets
            
            let visibleHeight = screenHeight - safeAreaInsets.top - safeAreaInsets.bottom
            isBottomButtonVisible = bottomButtonFrame.maxY <= visibleHeight
            
            if isShowingAdvancedOptions || isShowingNotificationSettings {
                let contentHeight = scrollViewHeight
                if contentHeight > visibleHeight {
                    isBottomButtonVisible = false
                }
            }
        }
    }
}

extension PushMessageView.Field: CaseIterable {
    static var allCases: [PushMessageView.Field] = [
        .title, .message, .sound, .url, .group, .badge, .copyText
    ]
}

// 添加 PreferenceKey 用于传递按钮框架
private struct ButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// 添加 PreferenceKey 用于传递滚动视图高度
private struct ScrollViewHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
