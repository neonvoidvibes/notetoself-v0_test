import SwiftUI

struct AIReflectionDetailContent: View {
    let insightMessage: String // The initial message from the collapsed view
    @EnvironmentObject var appState: AppState // Access journal entries for prompt generation
    @ObservedObject private var styles = UIStyles.shared

    // Helper method to generate reflection prompts based on recent entries (Copied from old ChatInsightCard)
    private func generateReflectionPrompts() -> [String] {
        let calendar = Calendar.current
        let recentEntries = appState.journalEntries
            .filter { calendar.isDateInToday($0.date) || calendar.isDateInYesterday($0.date) }

        if let mostRecent = recentEntries.first {
            // Generate prompts based on most recent entry mood
            switch mostRecent.mood {
            case .happy, .excited, .content, .relaxed, .calm:
                return [
                    "What specific events or factors contributed to your positive mood?",
                    "How might you intentionally create more moments like this in the future?",
                    "What strengths or resources are you drawing on during this positive period?"
                ]
            case .sad, .depressed:
                return [
                    "What thoughts or situations might be contributing to these feelings?",
                    "What has helped you navigate similar feelings in the past?",
                    "What small step could you take today to support your well-being?"
                ]
            case .anxious, .stressed:
                return [
                    "What specific concerns or uncertainties are you facing right now?",
                    "What aspects of the situation are within your control, and which aren't?",
                    "What coping strategies have been effective for you in the past?"
                ]
            case .angry:
                return [
                    "What underlying needs or values might this frustration be pointing to?",
                    "How might you address this situation in a way that aligns with your values?",
                    "What perspective might help you view this situation differently?"
                ]
            case .bored:
                return [
                    "What activities have engaged you deeply in the past?",
                    "What new skill or interest have you been curious about exploring?",
                    "How might this feeling of boredom be guiding you toward something important?"
                ]
            default:
                return [
                    "What patterns have you noticed in your thoughts or feelings lately?",
                    "What would be most supportive for you right now?",
                    "What insights from past experiences might be relevant to your current situation?"
                ]
            }
        } else {
            // General prompts if no recent entries
            return [
                "What's been on your mind lately that might be worth exploring?",
                "What patterns have you noticed in your mood or energy levels?",
                "What would you like to focus on or prioritize in the coming days?"
            ]
        }
    }


    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingL) {
            // Display the initial insight message clearly
            Text("AI's Thought Starter")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
            Text(insightMessage)
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.textSecondary)
                .padding(.bottom)

            // List reflection prompts
            Text("Deeper Reflection Prompts")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)

            ForEach(generateReflectionPrompts(), id: \.self) { prompt in
                HStack(alignment: .top, spacing: styles.layout.spacingM) {
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(styles.colors.accent.opacity(0.7))
                        .font(.system(size: 16))
                        .padding(.top, 4)

                    Text(prompt)
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                }
                .padding(.vertical, 4)
            }

            // Call-to-action button to open chat
            Button(action: {
                // Switch to the Reflections tab
                NotificationCenter.default.post(
                    name: NSNotification.Name("SwitchToTab"),
                    object: nil,
                    userInfo: ["tabIndex": 2]
                )
            }) {
                HStack {
                    Text("Continue in Chat")
                        .font(styles.typography.bodyFont.weight(.medium))
                        .foregroundColor(styles.colors.primaryButtonText)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(styles.colors.primaryButtonText)
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(styles.colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: styles.layout.radiusM))
                .shadow(color: styles.colors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(.top)
        }
    }
}

#Preview {
    AIReflectionDetailContent(insightMessage: "Sample insight message for preview.")
        .padding()
        .environmentObject(AppState()) // Provide mock data if needed
        .environmentObject(UIStyles.shared)
        .environmentObject(ThemeManager.shared)
}