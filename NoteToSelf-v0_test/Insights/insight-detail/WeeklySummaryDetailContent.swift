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
                // Header with Period
                HStack {
                    // Text("Weekly Summary") // Title is handled by InsightFullScreenView now
                    //     .font(styles.typography.title1) // Use appropriate typography
                    //     .foregroundColor(styles.colors.text)
                    Spacer() // Push period to the right if title removed
                    Text(summaryPeriod)
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(styles.colors.accent.opacity(0.1).clipShape(Capsule()))
                }

                // Main Summary Text (AI Generated)
                // REMOVED: Text("AI Summary") header
                 Text(summaryResult.mainSummary)
                     .font(styles.typography.bodyFont)
                     .foregroundColor(styles.colors.textSecondary)
                     .fixedSize(horizontal: false, vertical: true) // Allow wrapping
                     .padding(.bottom) // Keep padding


                // Key Themes (AI Generated)
                if !summaryResult.keyThemes.isEmpty {
                     VStack(alignment: .leading, spacing: styles.layout.spacingM) { // Use spacingM here
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
                     .padding(.bottom, styles.layout.spacingL) // Add padding after section
                }

                // Mood Trend (AI Generated)
                 VStack(alignment: .leading, spacing: styles.layout.spacingM) { // Use spacingM here
                     Text("Mood Trend")
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)
                     Text(summaryResult.moodTrend)
                         .font(styles.typography.bodyFont)
                         .foregroundColor(styles.colors.textSecondary)
                 }
                 .padding(.bottom, styles.layout.spacingL) // Add padding after section

                // Notable Quote (AI Generated)
                if !summaryResult.notableQuote.isEmpty {
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) { // Use spacingM here
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
                     .padding(.bottom, styles.layout.spacingL) // Add padding after section
                }

                 Spacer(minLength: styles.layout.spacingXL) // Add spacer before timestamp

                 // Generation Date Timestamp
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
        // Padding is now handled by InsightFullScreenView
        // .padding(styles.layout.paddingL)
    } // End body
} // End struct WeeklySummaryDetailContent

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