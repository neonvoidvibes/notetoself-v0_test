import SwiftUI

struct LearnDetailContent: View {
    let result: LearnInsightResult
    let generatedDate: Date?
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: styles.layout.spacingXL) {

                // --- Takeaway Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     // Use accent color for sub-header
                    Text("Key Takeaway")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.accent) // Accent color for sub-header

                    Text(result.takeawayText ?? "Significant insights from the week will be highlighted here.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(styles.layout.spacingXS) // Add line spacing
                }
                .padding()
                .background(styles.colors.secondaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)

                // --- Before/After Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     // Use accent color for sub-header
                    Text("Before / After")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.accent) // Accent color for sub-header

                    Text(result.beforeAfterText ?? "Comparisons highlighting growth or shifts will appear here.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(styles.layout.spacingXS) // Add line spacing
                }
                .padding()
                .background(styles.colors.secondaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)

                // --- Next Step Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     // Use accent color for sub-header
                    Text("Suggested Next Step")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.accent) // Accent color for sub-header

                    Text(result.nextStepText ?? "Suggestions for applying learnings will be offered here.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(styles.layout.spacingXS) // Add line spacing
                }
                .padding()
                .background(styles.colors.secondaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)


                Spacer(minLength: styles.layout.spacingXL)

                // Generated Date Timestamp
                if let date = generatedDate {
                    HStack {
                        Spacer()
                        Image(systemName: "clock")
                            .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                            .font(.system(size: 12))
                        Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .padding(.bottom, styles.layout.paddingL)
        }
    }
}

#Preview {
    let mockResult = LearnInsightResult(
        takeawayText: "Preview: Recognizing the link between sleep quality and focus was a key learning this week.",
        beforeAfterText: "Preview: Previously, late nights led to scattered work; prioritizing sleep resulted in more productive mornings.",
        nextStepText: "Preview: How can you reinforce this sleep pattern next week, especially if deadlines loom?"
    )

    return InsightFullScreenView(title: "Learn Insights") {
        LearnDetailContent(result: mockResult, generatedDate: Date())
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
}