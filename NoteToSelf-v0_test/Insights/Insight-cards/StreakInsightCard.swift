import SwiftUI

// Renamed from StreakInsightCard
struct StreakNarrativeInsightCard: View {
    let streak: Int

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    @EnvironmentObject var appState: AppState

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared

    // Placeholder for AI-generated story snippet
    private var storySnippet: String {
        // TODO: Replace with actual AI-generated snippet based on recent entries
        if streak > 5 {
            return "You've been building momentum, exploring new themes..."
        } else if streak > 0 {
            return "Getting started on your reflection journey..."
        } else {
            return "Begin your story by journaling today."
        }
    }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            isPrimary: streak > 0, // Highlight if streak is active
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: Larger streak, fewer items, helping text
                HStack(alignment: .center, spacing: styles.layout.spacingL) {
                    // Large Flame Icon & Streak Number
                    VStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 36))
                            .foregroundColor(styles.colors.accent)
                        Text("\(streak)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced)) // Larger, bolder
                            .foregroundColor(styles.colors.text)
                        Text(streak == 1 ? "day" : "days")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary)
                    }
                    .frame(width: 60) // Fixed width for icon/number

                    // Story Snippet & Helping Text
                    VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                        Text("Your Journey") // Clearer title
                            .font(styles.typography.smallLabelFont)
                            .foregroundColor(styles.colors.textSecondary)

                        Text(storySnippet)
                            .font(styles.typography.bodyFont) // Main text for snippet
                            .foregroundColor(styles.colors.text)
                            .lineLimit(2)

                        Text("Tap to see your journey's turning points!") // Helping text
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.accent)
                    }
                    Spacer() // Push content to left
                }
                .padding(.vertical, styles.layout.paddingS) // Add some vertical padding
            },
            detailContent: {
                // Expanded View: Use StreakNarrativeDetailContent
                StreakNarrativeDetailContent(streak: streak, entries: appState.journalEntries) // Pass entries
            }
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// Preview remains similar, just update the name
#Preview {
    ScrollView {
        StreakNarrativeInsightCard(streak: 5)
            .padding()
            .environmentObject(AppState()) // Provide mock data if needed
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}