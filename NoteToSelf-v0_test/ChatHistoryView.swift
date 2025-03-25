import SwiftUI

struct ChatHistoryView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var chatManager: ChatManager
    var onSelectChat: (Chat) -> Void
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            styles.colors.menuBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Extra top padding
                        Spacer()
                            .frame(height: 30)
                        
                        // Group chats by time period
                        let groupedChats = chatManager.groupChatsByTimePeriod()
                        
                        if groupedChats.isEmpty {
                            Text("No chat history yet")
                                .foregroundColor(styles.colors.textSecondary)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(groupedChats, id: \.0) { section, chats in
                                // Section header - aligned with text inside cards
                                Text(section)
                                    .font(styles.typography.title3)
                                    .foregroundColor(styles.colors.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, styles.layout.paddingL + styles.layout.paddingM) // Align with text inside cards
                                    .padding(.trailing, styles.layout.paddingL)
                                    .padding(.top, 20)
                                    .padding(.bottom, 10)
                                
                                // Chats in this section
                                ForEach(chats) { chat in
                                    Button(action: {
                                        onSelectChat(chat)
                                    }) {
                                        ChatHistoryItem(chat: chat)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, styles.layout.paddingL)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top, styles.headerPadding.top)
                }
            }
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
        .padding(styles.layout.paddingM) // Restored original padding
        .background(styles.colors.secondaryBackground)
        .cornerRadius(styles.layout.radiusM)
        .overlay(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .stroke(Color(hex: "#222222"), lineWidth: 1) // Same border as JournalView
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

