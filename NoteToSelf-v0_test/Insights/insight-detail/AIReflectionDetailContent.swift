import SwiftUI

struct AIReflectionDetailContent: View {
    let insightMessage: String // The initial message from the collapsed view
    let reflectionPrompts: [String] // Pass in the generated prompts
    let generatedDate: Date? // Accept date
     // Ensure styles are observed if passed down or used globally
     @ObservedObject private var styles = UIStyles.shared

    var body: some View {
         ScrollView { // Wrap in ScrollView
             VStack(alignment: .leading, spacing: styles.layout.spacingXL) { // Keep XL spacing

                 // --- AI Thought Starter Section ---
                 VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     Text("AI Thought Starter")
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)
                     Text(insightMessage)
                         .font(styles.typography.bodyFont)
                         .foregroundColor(styles.colors.textSecondary)
                         .frame(maxWidth: .infinity, alignment: .leading)
                 }
                 .padding() // Apply styling to the section VStack
                 .background(styles.colors.secondaryBackground.opacity(0.5))
                 .cornerRadius(styles.layout.radiusM)


                 // --- Reflection Prompts Section ---
                 VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                      Text("Deeper Reflection Prompts")
                          .font(styles.typography.title3)
                          .foregroundColor(styles.colors.text)
                          .padding(.bottom, styles.layout.spacingS) // Space below header

                      ForEach(reflectionPrompts, id: \.self) { prompt in // Iterate over passed-in prompts
                          HStack(alignment: .top, spacing: styles.layout.spacingM) {
                              Image(systemName: "bubble.left.fill")
                                  .foregroundColor(styles.colors.accent.opacity(0.7))
                                  .font(.system(size: 16))
                                  .padding(.top, 4)

                              Text(prompt)
                                  .font(styles.typography.bodyFont)
                                  .foregroundColor(styles.colors.textSecondary)
                                  .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                                  .frame(maxWidth: .infinity, alignment: .leading)
                          }
                           // Add subtle divider between prompts if desired
                           if prompt != reflectionPrompts.last {
                               Divider().background(styles.colors.divider.opacity(0.3)).padding(.vertical, styles.layout.spacingS)
                           }
                      }
                 } // End Prompts VStack
                 .padding() // Apply styling to the section VStack
                 .background(styles.colors.secondaryBackground.opacity(0.5))
                 .cornerRadius(styles.layout.radiusM)


                 // --- Continue Chat Button ---
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
                 // No background needed for the button itself

                 Spacer(minLength: styles.layout.spacingXL) // Add spacer before timestamp

                 // Generated Date Timestamp
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
            } // End Main VStack
             .padding(.bottom, styles.layout.paddingL) // Bottom padding inside scrollview
         } // End ScrollView
    } // End body
} // End struct AIReflectionDetailContent

#Preview {
     // Define mock prompts for preview
      let mockPrompts = [
          "Preview Prompt 1: What happened?",
          "Preview Prompt 2: How did it feel?",
          "Preview Prompt 3: What did you learn?"
      ]

     // Wrap in InsightFullScreenView for accurate preview of padding/layout
     return InsightFullScreenView(title: "AI Insights") {
         AIReflectionDetailContent(
             insightMessage: "Sample insight message for preview, touching on recent events and asking an opening question.",
             reflectionPrompts: mockPrompts, // Pass mock prompts
             generatedDate: Date() // Pass date
         )
     }
     .environmentObject(AppState()) // Provide mock data if needed
     .environmentObject(UIStyles.shared)
     .environmentObject(ThemeManager.shared)
}