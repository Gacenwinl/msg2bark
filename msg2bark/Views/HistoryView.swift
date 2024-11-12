import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \PushHistoryItem.timestamp, order: .reverse)
    private var historyItems: [PushHistoryItem]
    
    var body: some View {
        NavigationView {
            List {
                if historyItems.isEmpty {
                    Text("暂无历史记录")
                } else {
                    ForEach(historyItems) { item in
                        HistoryItemView(item: item)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("推送历史")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(historyItems[index])
            }
            try? modelContext.save()
        }
    }
}

struct HistoryItemView: View {
    let item: PushHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.headline)
                Spacer()
                Text(item.isArchiveInReceiver ? "接收端自动保存" : "接收端不保存")
                    .font(.caption)
                    .foregroundColor(item.isArchiveInReceiver ? .blue : .gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(item.isArchiveInReceiver ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    )
            }
            
            Text(item.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !item.configNames.isEmpty {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("发送给：")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(item.configNames.joined(separator: "、"))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 2)
            }
            
            if hasExtraInfo {
                VStack(alignment: .leading, spacing: 4) {
                    if let sound = item.sound {
                        extraInfoRow(icon: "speaker.wave.2", label: "提示音", value: sound)
                    }
                    if let url = item.url {
                        extraInfoRow(icon: "link", label: "链接", value: url)
                    }
                    if let group = item.group {
                        extraInfoRow(icon: "folder", label: "分组", value: group)
                    }
                }
                .padding(.top, 4)
            }
            
            Text(item.timestamp.formatted())
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
    
    private var hasExtraInfo: Bool {
        item.sound != nil || item.url != nil || item.group != nil
    }
    
    private func extraInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.gray)
            Text(label + ": ")
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: PushHistoryItem.self)
} 