import SwiftUI

// Renamed from ChatInsightCard
struct AIReflectionInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager // Keep for potential context/history link

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    @State private var animateGradient: Bool = false // Keep animation

    @ObservedObject private var styles = UIStyles.shared

    // Insight message generation logic remains the same for now
    private var insightMessage: String {
        let calendar = Calendar.current
        let recentEntries = appState.journalEntries
            .filter { calendar.isDateInToday($0.date) || calendar.isDateInYesterday($0.date) }

        if let mostRecent = recentEntries.first {
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
            return "How are you feeling today? Taking a moment to check in with yourself can provide valuable insights."
        }
    }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: AI Avatar, Insight Snippet, Helping Text
                HStack(spacing: styles.layout.spacingM) {
                    // AI Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        styles.colors.accent,
                                        styles.colors.accent.opacity(0.7)
                                    ]),
                                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                                )
                            )
                            .frame(width: 50, height: 50) // Slightly larger avatar
                        Image(systemName: "sparkles") // Keep sparkles
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    .onAppear { // Keep animation logic
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            animateGradient.toggle()
                        }
                    }

                    // Insight Snippet & Helping Text
                    VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                        Text("AI Reflection") // Clearer title
                           .font(styles.typography.smallLabelFont)
                           .foregroundColor(styles.colors.textSecondary)

                        Text(insightMessage)
                            .font(styles.typography.bodyFont) // Main font for snippet
                            .foregroundColor(styles.colors.text)
                            .lineLimit(2) // Limit lines in collapsed view

                        Text("Tap to reflect deeper on today’s thoughts.") // Helping text
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.accent)
                    }
                    Spacer() // Push content left
                }
                .padding(.vertical, styles.layout.paddingS) // Add vertical padding
            },
            detailContent: {
                // Expanded View: Use AIReflectionDetailContent
                AIReflectionDetailContent(insightMessage: insightMessage) // Pass necessary data
            }
        )
    }
}

#Preview {
    ScrollView{
        AIReflectionInsightCard()
            .padding()
            .environmentObject(AppState()) // Provide mock data if needed
            .environmentObject(ChatManager(databaseService: DatabaseService(), llmService: LLMService.shared, subscriptionManager: SubscriptionManager.shared))
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}