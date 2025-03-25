import SwiftUI

struct ChatHistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled: Bool
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            styles.colors.menuBackground
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: styles.layout.spacingXL) {
                    // Chat history items will go here
                    ForEach(appState.chatMessages) { message in
                        ChatHistoryItem(message: message)
                    }
                    
                    if appState.chatMessages.isEmpty {
                        Text("No chat history yet")
                            .foregroundColor(styles.colors.textSecondary)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, styles.layout.paddingL)
                .padding(.top, styles.headerPadding.top)
            }
            .disabled(mainScrollingDisabled)
        }
    }
}

struct ChatHistoryItem: View {
    let message: ChatMessage
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message.isUser ? "You" : "AI")
                    .font(styles.typography.bodySmall)
                    .foregroundColor(message.isUser ? styles.colors.accent : styles.colors.textSecondary)
                
                Spacer()
                
                Text(formatDate(message.date))
                    .font(styles.typography.caption)
                    .foregroundColor(styles.colors.textSecondary)
            }
            
            Text(message.text)
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.text)
                .lineLimit(2)
                .truncationMode(.tail)
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

