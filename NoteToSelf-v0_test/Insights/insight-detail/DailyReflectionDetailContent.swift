import SwiftUI

struct DailyReflectionDetailContent: View {
    let result: DailyReflectionResult
    let generatedDate: Date?
    @ObservedObject private var styles = UIStyles.shared
    @Environment(\.dismiss) private var dismiss // Add dismiss environment variable

    var body: some View {
        // Use GeometryReader to allow button to be pushed to bottom
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: styles.layout.spacingXL) {

                    // --- Daily Snapshot Section ---
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Today's Snapshot")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.accent) // Accent header

                        Text(result.snapshotText ?? "Reflection not available. Journal today to generate.")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(styles.layout.spacingXS)
                    }
                    .padding()
                    .background(styles.colors.secondaryBackground.opacity(0.5))
                    .cornerRadius(styles.layout.radiusM)

                    // --- Reflection Prompts Section ---
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                          Text("Reflection Prompts")
                              .font(styles.typography.title3)
                              .foregroundColor(styles.colors.accent) // Accent header
                              .padding(.bottom, styles.layout.spacingS)

                          if let prompts = result.reflectionPrompts, !prompts.isEmpty {
                              ForEach(prompts, id: \.self) { prompt in
                                  HStack(alignment: .top, spacing: styles.layout.spacingM) {
                                      Image(systemName: "bubble.left.fill")
                                          .foregroundColor(styles.colors.accent.opacity(0.7))
                                          .font(.system(size: 16))
                                          .padding(.top, 4)

                                      Text(prompt)
                                          .font(styles.typography.bodyFont)
                                          .foregroundColor(styles.colors.textSecondary)
                                          .fixedSize(horizontal: false, vertical: true)
                                          .frame(maxWidth: .infinity, alignment: .leading)
                                  }
                                   if prompt != prompts.last {
                                       Divider().background(styles.colors.divider.opacity(0.3)).padding(.vertical, styles.layout.spacingS)
                                   }
                              }
                          } else {
                               Text("No specific prompts generated for this reflection.")
                                    .font(styles.typography.bodySmall)
                                    .foregroundColor(styles.colors.textSecondary)
                          }
                     }
                     .padding()
                     .background(styles.colors.secondaryBackground.opacity(0.5))
                     .cornerRadius(styles.layout.radiusM)


                     // --- REMOVED Old Button ---
                     // Spacer(minLength: styles.layout.spacingXL) REMOVED

                     // Generated Date Timestamp - Moved slightly up
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

                     // Ensure content pushes button down
                     Spacer(minLength: geometry.size.height * 0.1) // Add dynamic spacer

                     // --- NEW Continue Chat Button ---
                     Button(action: {
                         // Post notification FIRST
                         NotificationCenter.default.post(
                             name: NSNotification.Name("SwitchToTab"),
                             object: nil,
                             userInfo: ["tabIndex": 2] // Index 2 should be Reflections tab
                         )
                         // THEN dismiss the modal
                         dismiss()
                     }) {
                         HStack {
                             Text("Continue Reflection in Chat") // Updated Text
                                 .font(styles.typography.bodyFont.weight(.medium))
                             Image(systemName: "arrow.right")
                                 .font(.system(size: 14, weight: .semibold))
                         }
                     }
                      // Use the PrimaryButtonStyle for full-width accent background
                     .buttonStyle(UIStyles.PrimaryButtonStyle())
                     .padding(.top, styles.layout.spacingL) // Space above button


                } // End Main VStack
                // Set minHeight to ensure ScrollView fills GeometryReader
                .frame(minHeight: geometry.size.height)
                .padding(.bottom, styles.layout.paddingL)
            } // End ScrollView
        } // End GeometryReader
    }
}

#Preview {
    let mockResult = DailyReflectionResult(
        snapshotText: "Preview: Today's entry highlights a sense of accomplishment regarding [Project], balanced with some underlying fatigue. Your energy seems highest mid-day.",
        reflectionPrompts: [
            "What specific part of [Project] felt most rewarding?",
            "How might you adjust your evening routine to combat the fatigue observed?"
        ]
    )

    return InsightFullScreenView(title: "Daily Reflection") {
        DailyReflectionDetailContent(result: mockResult, generatedDate: Date())
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .environmentObject(AppState()) // Added AppState
}