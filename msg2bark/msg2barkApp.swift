//
//  msg2barkApp.swift
//  msg2bark
//
//  Created by 王立程 on 2024/11/12.
//

import SwiftUI
import SwiftData

@main
struct MSG2BarkApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var storageManager = StorageManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .environmentObject(storageManager)
                .modelContainer(
                    for: [BarkConfig.self, PushHistoryItem.self],
                    inMemory: false,
                    isAutosaveEnabled: true
                ) { result in
                    switch result {
                    case .success(_):
                        print("Successfully initialized ModelContainer")
                    case .failure(let error):
                        print("Failed to initialize ModelContainer: \(error)")
                        // 删除现有的存储并重新创建
                        deleteStore()
                    }
                }
        }
    }
    
    private func deleteStore() {
        let url = URL.applicationSupportDirectory.appending(path: "default.store")
        try? FileManager.default.removeItem(at: url)
    }
}
