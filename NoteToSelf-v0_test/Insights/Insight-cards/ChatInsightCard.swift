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
                moodPhrase = "I notice you've been feeling \(mostRecent.mood.name.lowercased()). That's wonderful!"
            case .sad, .depressed, .anxious, .stressed:
                moodPhrase = "I see you've been feeling \(mostRecent.mood.name.lowercased()). Would you like to talk about it?"
            case .angry:
                moodPhrase = "I notice you expressed some anger in your recent entry. Would you like to explore what triggered this?"
            case .bored:
                moodPhrase = "You mentioned feeling bored. Would you like to discuss some activities that might energize you?"
            default:
                moodPhrase = "I noticed your recent journal entry. Would you like to reflect on it together?"
            }
            
            let wordCount = mostRecent.text.split(separator: " ").count
            let lengthPhrase = wordCount > 100 ? 
                "You wrote quite a detailed entry. I'd love to hear more about what's on your mind." : 
                "Would you like to expand on your thoughts from your recent entry?"
            
            return "\(moodPhrase) \(lengthPhrase)"
        } else {
            // No recent entries
            return "How are you feeling today? I'm here to help you reflect on your thoughts and emotions."
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
            styles.card(
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
                    }
                    
                    // Call-to-action
                    HStack {
                        Spacer()
                        
                        Text("Tap to continue this conversation")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.accent)
                            .padding(.top, styles.layout.spacingS)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: 14))
                    }
                }
                .padding(styles.layout.paddingL)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

