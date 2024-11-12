import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = PushMessageViewModel()
    
    var body: some View {
        TabView {
            PushMessageView(viewModel: viewModel)
                .tabItem {
                    Label("推送", systemImage: "paperplane.fill")
                }
            
            HistoryView()
                .tabItem {
                    Label("历史", systemImage: "clock.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
        .modelContainer(for: PushHistoryItem.self)
} 