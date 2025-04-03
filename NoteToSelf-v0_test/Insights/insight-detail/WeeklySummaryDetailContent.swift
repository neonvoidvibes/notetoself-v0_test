import SwiftUI
// Removed Charts import as local charts are removed from this view

// This view now represents the EXPANDED content for the Weekly Summary card,
// displaying data SOLELY from the AI-generated WeeklySummaryResult.
struct WeeklySummaryDetailContent: View {
    // Input: Accept the decoded result and other necessary info
    let summaryResult: WeeklySummaryResult
    let summaryPeriod: String // Calculated period string passed from parent
    let generatedDate: Date? // Optional generation date passed from parent

    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        ScrollView { // Wrap in ScrollView for potentially long content
            VStack(alignment: .leading, spacing: styles.layout.spacingXL) { // Use larger spacing
                // Header with Period
                HStack {
                    Text("Weekly Summary")
                        .font(styles.typography.title1) // Use appropriate typography
                        .foregroundColor(styles.colors.text)
                    Spacer()
                    Text(summaryPeriod)
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(styles.colors.accent.opacity(0.1).clipShape(Capsule()))
                }

                // Main Summary Text (AI Generated)
                VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                    Text("AI Summary")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    Text(summaryResult.mainSummary)
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true) // Allow wrapping
                }


                // Key Themes (AI Generated)
                if !summaryResult.keyThemes.isEmpty {
                     VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                         Text("Key Themes")
                             .font(styles.typography.title3)
                             .foregroundColor(styles.colors.text)
                         // Use FlowLayout for better theme wrapping
                         FlowLayout(spacing: 10) {
                             ForEach(summaryResult.keyThemes, id: \.self) { theme in
                                 Text(theme)
                                     .font(styles.typography.bodySmall)
                                     .padding(.horizontal, 12)
                                     .padding(.vertical, 8)
                                     .background(styles.colors.secondaryBackground)
                                     .cornerRadius(styles.layout.radiusM)
                                     .foregroundColor(styles.colors.text)
                             }
                         }
                     }
                }

                // Mood Trend (AI Generated)
                 VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                     Text("Mood Trend")
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)
                     Text(summaryResult.moodTrend)
                         .font(styles.typography.bodyFont)
                         .foregroundColor(styles.colors.textSecondary)
                 }


                // Notable Quote (AI Generated)
                if !summaryResult.notableQuote.isEmpty {
                    VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                         Text("Notable Quote")
                             .font(styles.typography.title3)
                             .foregroundColor(styles.colors.text)
                         Text("\"\(summaryResult.notableQuote)\"")
                             .font(styles.typography.bodyFont.italic())
                             .foregroundColor(styles.colors.accent)
                             .padding()
                             .frame(maxWidth: .infinity, alignment: .leading)
                             .background(styles.colors.secondaryBackground.opacity(0.5))
                             .cornerRadius(styles.layout.radiusM)
                     }
                }

                 Spacer() // Push content towards top

                // Generation Date
                 if let date = generatedDate {
                     Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                         .font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                         .frame(maxWidth: .infinity, alignment: .center).padding(.top)
                 }
            }
             .padding(styles.layout.paddingL) // Add padding to the content
        }
    }
}

#Preview {
     let previewSummary = WeeklySummaryResult(
         mainSummary: "This week involved focusing on work projects and finding time for relaxation during the weekend. Mood was generally positive.",
         keyThemes: ["Work Stress", "Weekend Relaxation", "Project Deadline"],
         moodTrend: "Generally positive with a dip mid-week",
         notableQuote: "Felt a real sense of accomplishment today."
     )
     return WeeklySummaryDetailContent(
         summaryResult: previewSummary,
         summaryPeriod: "Oct 20 - Oct 26", // Example period
         generatedDate: Date()
     )
         .padding() // Add padding for preview container if needed
         .environmentObject(UIStyles.shared)
         .environmentObject(ThemeManager.shared)
}
