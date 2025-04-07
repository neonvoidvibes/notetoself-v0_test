import SwiftUI

struct DailyReflectionDetailContent: View {
    let result: DailyReflectionResult
    let generatedDate: Date?
    @ObservedObject private var styles = UIStyles.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: styles.layout.spacingXL) {
                // Add debug background
                // .background(Color.blue.opacity(0.2)) // <-- TEMPORARY DEBUG: Add this line locally if needed

                // --- Daily Snapshot Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Today's Snapshot")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.accent)

                    if let snapshot = result.snapshotText, !snapshot.isEmpty {
                        Text(snapshot)
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(styles.layout.spacingXS)
                    } else {
                        Text("Reflection not available. Journal today to generate.")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(styles.layout.spacingXS)
                    }
                }
                .padding()
                .background(styles.colors.secondaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)
                .frame(minHeight: 80) // Ensure section itself has minimum height

                // --- Reflection Prompts Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                      Text("Reflection Prompts")
                          .font(styles.typography.title3)
                          .foregroundColor(styles.colors.accent)
                          .padding(.bottom, styles.layout.spacingS)

                      if let prompts = result.reflectionPrompts, !prompts.isEmpty {
                          // Use index for stable IDs if prompts can be identical
                          ForEach(Array(prompts.enumerated()), id: \.offset) { index, prompt in
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
                               // Use index check for divider
                               if index < prompts.count - 1 {
                                   Divider().background(styles.colors.divider.opacity(0.3)).padding(.vertical, styles.layout.spacingS)
                               }
                          }
                      } else {
                           Text("No specific prompts generated for this reflection.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                      }
                 }
                 .padding()
                 .background(styles.colors.secondaryBackground.opacity(0.5))
                 .cornerRadius(styles.layout.radiusM)
                 .frame(minHeight: 80) // Ensure section itself has minimum height


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

                 // Spacer to push content up and button down
                 Spacer()

                 // Continue Chat Button
                 Button(action: {
                     NotificationCenter.default.post(
                         name: NSNotification.Name("SwitchToTab"),
                         object: nil,
                         userInfo: ["tabIndex": 2]
                     )
                     dismiss()
                 }) {
                     HStack {
                         Text("Continue Reflection in Chat")
                             .font(styles.typography.bodyFont.weight(.medium))
                         Image(systemName: "arrow.right")
                             .font(.system(size: 14, weight: .semibold))
                     }
                 }
                 .buttonStyle(UIStyles.PrimaryButtonStyle())
                 .padding(.top, styles.layout.spacingL) // Keep space above button

            } // End Main VStack
            .padding(.horizontal, styles.layout.paddingXL) // Re-add horizontal padding here
            .padding(.vertical, styles.layout.paddingL) // Re-add vertical padding here
        } // End ScrollView
    }
}

// Preview with mock data
#Preview("With Data") {
    let mockResult = DailyReflectionResult(
        snapshotText: "Preview: Today's entry highlights a sense of accomplishment regarding [Project], balanced with some underlying fatigue. Your energy seems highest mid-day.",
        reflectionPrompts: [
            "What specific part of [Project] felt most rewarding?",
            "How might you adjust your evening routine to combat the fatigue observed?"
        ]
    )
    return InsightFullScreenView(title: "Daily Reflection (Data)") {
        DailyReflectionDetailContent(result: mockResult, generatedDate: Date())
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .environmentObject(AppState())
}

// Preview with empty data
#Preview("Empty Data") {
    let emptyResult = DailyReflectionResult.empty()
    return InsightFullScreenView(title: "Daily Reflection (Empty)") {
        DailyReflectionDetailContent(result: emptyResult, generatedDate: nil)
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .environmentObject(AppState())
}