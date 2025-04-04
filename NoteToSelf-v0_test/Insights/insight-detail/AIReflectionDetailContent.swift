import SwiftUI

struct AIReflectionDetailContent: View {
    let insightMessage: String // The initial message from the collapsed view
    let reflectionPrompts: [String] // Pass in the generated prompts
     // Ensure styles are observed if passed down or used globally
     @ObservedObject private var styles = UIStyles.shared

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
     // Define mock prompts for preview
      let mockPrompts = [
          "Preview Prompt 1: What happened?",
          "Preview Prompt 2: How did it feel?",
          "Preview Prompt 3: What did you learn?"
      ]

    return AIReflectionDetailContent(
        insightMessage: "Sample insight message for preview.",
        reflectionPrompts: mockPrompts // Pass mock prompts
        )
        .padding()
        .environmentObject(AppState()) // Provide mock data if needed
        .environmentObject(UIStyles.shared)
        .environmentObject(ThemeManager.shared)
}