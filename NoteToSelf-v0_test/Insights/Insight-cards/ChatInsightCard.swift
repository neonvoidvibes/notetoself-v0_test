import SwiftUI

struct ChatInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager
    private let styles = UIStyles.shared
    
    // This would ideally come from an AI model analyzing journal entries
    // For now, we'll use a simple algorithm to generate an insight
    private var insightMessage: String {
        let calendar = Calendar.current
        let recentEntries = appState.journalEntries
            .filter { calendar.isDateInToday($0.date) || calendar.isDateInYesterday($0.date) }
    
        if let mostRecent = recentEntries.first {
            // Generate insight based on most recent entry
            let moodPhrase: String
            switch mostRecent.mood {
            case .happy, .excited, .content, .relaxed, .calm:
                moodPhrase = "I notice you've been feeling \(mostRecent.mood.name.lowercased()) lately. That's wonderful! What's contributing to this positive state?"
            case .sad, .depressed, .anxious, .stressed:
                moodPhrase = "I see you've been feeling \(mostRecent.mood.name.lowercased()). I'm here to listen if you'd like to explore what might be affecting you."
            case .angry:
                moodPhrase = "I notice you expressed some frustration recently. Sometimes talking through what triggered this can help provide clarity."
            case .bored:
                moodPhrase = "You mentioned feeling bored. Would exploring some new activities or perspectives help energize you?"
            default:
                moodPhrase = "I noticed your recent journal entry. Let's reflect on what's been on your mind."
            }
        
            return moodPhrase
        } else {
            // No recent entries
            return "How are you feeling today? Taking a moment to check in with yourself can provide valuable insights."
        }
    }
    
    var body: some View {
        Button(action: {
            // Switch to the Reflections tab
            NotificationCenter.default.post(
                name: NSNotification.Name("SwitchToTab"),
                object: nil,
                userInfo: ["tabIndex": 2]
            )
        }) {
            styles.enhancedCard(
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Reflection Prompt")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                        
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: styles.layout.iconSizeL))
                    }
                    
                    // AI Assistant message with a unique styling
                    HStack(alignment: .top, spacing: styles.layout.spacingM) {
                        // Assistant avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            styles.colors.accent,
                                            styles.colors.accent.opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        }
                        
                        // Message bubble with gradient border
                        Text(insightMessage)
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.text)
                            .padding(styles.layout.paddingM)
                            .background(
                                RoundedRectangle(cornerRadius: styles.layout.radiusL)
                                    .fill(styles.colors.secondaryBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: styles.layout.radiusL)
                                            .strokeBorder(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        styles.colors.accent.opacity(0.7),
                                                        styles.colors.accent.opacity(0.3)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(3)
                    }
                    
                    // Call-to-action
                    HStack {
                        Spacer()
                        
                        Text("Continue this conversation")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.accent)
                            .padding(.top, styles.layout.spacingS)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: 14))
                    }
                }
                .padding(styles.layout.cardInnerPadding)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

