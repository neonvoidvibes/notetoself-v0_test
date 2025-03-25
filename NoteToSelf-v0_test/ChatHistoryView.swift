import SwiftUI

struct ChatHistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled: Bool
    @ObservedObject var chatManager: ChatManager
    var onSelectChat: (Chat) -> Void
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            styles.colors.menuBackground
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    // Extra top padding
                    Spacer()
                        .frame(height: 30)
                    
                    // Group chats by time period
                    let groupedChats = chatManager.groupChatsByTimePeriod()
                    
                    if groupedChats.isEmpty {
                        Text("No chat history yet")
                            .foregroundColor(styles.colors.textSecondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(groupedChats, id: \.0) { section, chats in
                            // Section header
                            HStack {
                                Text(section)
                                    .font(styles.typography.title3)
                                    .foregroundColor(styles.colors.text)
                                    .padding(.vertical, 10)
                                
                                Spacer()
                            }
                            .padding(.horizontal, styles.layout.paddingL)
                            .padding(.top, 20)
                            .padding(.bottom, 4)
                            
                            // Chats in this section
                            ForEach(chats) { chat in
                                ChatHistoryItem(chat: chat)
                                    .padding(.horizontal, styles.layout.paddingL)
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onSelectChat(chat)
                                    }
                            }
                        }
                    }
                }
                .padding(.top, styles.headerPadding.top)
            }
            .disabled(mainScrollingDisabled)
        }
    }
}

struct ChatHistoryItem: View {
    let chat: Chat
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(chat.title)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.text)
                    .lineLimit(1)
                
                Spacer()
                
                Text(formatDate(chat.lastUpdatedAt))
                    .font(styles.typography.caption)
                    .foregroundColor(styles.colors.textSecondary)
            }
            
            // Show the last message if available
            if let lastMessage = chat.messages.last {
                HStack(spacing: 2) {
                    Text(lastMessage.isUser ? "You: " : "AI: ")
                        .font(styles.typography.bodySmall)
                        .foregroundColor(lastMessage.isUser ? styles.colors.accent : styles.colors.textSecondary)
                    
                    Text(lastMessage.text)
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.textSecondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(styles.layout.paddingM)
        .background(styles.colors.secondaryBackground)
        .cornerRadius(styles.layout.radiusM)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

