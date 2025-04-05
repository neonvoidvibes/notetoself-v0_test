import SwiftUI
// Removed Charts import as local charts are removed from this view

// This view now represents the EXPANDED content for the Weekly Summary card,
// displaying data SOLELY from the AI-generated WeeklySummaryResult.
struct WeeklySummaryDetailContent: View {
    // Input: Accept the decoded result and other necessary info
    let summaryResult: WeeklySummaryResult
    let summaryPeriod: String // Calculated period string passed from parent
    let generatedDate: Date? // Optional generation date passed from parent

    // Ensure styles are observed if passed down or used globally
     @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        // Use the layout previously defined in WeeklySummaryDetailContentExpanded
        ScrollView { // Wrap in ScrollView for potentially long content
            VStack(alignment: .leading, spacing: styles.layout.spacingXL) { // Ensure XL spacing

                // --- AI Summary Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("AI Summary")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    Text(summaryResult.mainSummary)
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true) // Allow wrapping
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding() // Apply styling to the section VStack
                .background(styles.colors.secondaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)


                // --- Key Themes Section ---
                if !summaryResult.keyThemes.isEmpty {
                     // Wrap Key Themes section in a VStack and apply styling
                     VStack(alignment: .leading, spacing: styles.layout.spacingM) {
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
                                     .background(styles.colors.secondaryBackground) // Use secondary directly for tags
                                     .cornerRadius(styles.layout.radiusM)
                                     .foregroundColor(styles.colors.text)
                             }
                         }
                     }
                      .padding() // Apply styling to the section VStack
                      .background(styles.colors.secondaryBackground.opacity(0.5))
                      .cornerRadius(styles.layout.radiusM)
                }

                // --- Mood Trend Section ---
                 VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     Text("Mood Trend")
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)
                     Text(summaryResult.moodTrend)
                         .font(styles.typography.bodyFont)
                         .foregroundColor(styles.colors.textSecondary)
                         .frame(maxWidth: .infinity, alignment: .leading)
                 }
                 .padding() // Apply styling to the section VStack
                 .background(styles.colors.secondaryBackground.opacity(0.5))
                 .cornerRadius(styles.layout.radiusM)


                // --- Notable Quote Section ---
                if !summaryResult.notableQuote.isEmpty {
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                         Text("Notable Quote")
                             .font(styles.typography.title3)
                             .foregroundColor(styles.colors.text)
                         Text("\"\(summaryResult.notableQuote)\"")
                             .font(styles.typography.bodyFont.italic())
                             .foregroundColor(styles.colors.accent)
                             .frame(maxWidth: .infinity, alignment: .leading) // Ensure text takes width
                     }
                     .padding() // Apply styling to the section VStack
                     .background(styles.colors.secondaryBackground.opacity(0.5))
                     .cornerRadius(styles.layout.radiusM)
                }

                 Spacer(minLength: styles.layout.spacingXL) // Add spacer before timestamp

                 // Generation Date Timestamp (Outside styled sections)
                  if let date = generatedDate {
                      HStack {
                          Spacer() // Center align
                          Image(systemName: "clock")
                              .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                              .font(.system(size: 12))
                          Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                              .font(styles.typography.caption)
                              .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                          Spacer()
                      }
                      .padding(.top) // Padding above timestamp
                  }
            }
             .padding(.bottom, styles.layout.paddingL) // Add bottom padding inside scrollview
        } // End ScrollView
    } // End body
} // End struct WeeklySummaryDetailContent

#Preview {
     let previewSummary = WeeklySummaryResult(
         mainSummary: "This week involved focusing on work projects and finding time for relaxation during the weekend. Mood was generally positive.",
         keyThemes: ["Work Stress", "Weekend Relaxation", "Project Deadline", "Mindfulness Practice", "Family Visit"], // Added more themes for wrapping
         moodTrend: "Generally positive with a dip mid-week",
         notableQuote: "Felt a real sense of accomplishment today."
     )
      // Wrap in InsightFullScreenView for accurate preview of padding/layout
     return InsightFullScreenView(title: "Weekly Summary") {
         WeeklySummaryDetailContent(
             summaryResult: previewSummary,
             summaryPeriod: "Oct 20 - Oct 26", // Example period
             generatedDate: Date()
         )
     }
     .environmentObject(UIStyles.shared)
     .environmentObject(ThemeManager.shared)
}