import SwiftUI

struct BreathingDotIndicator: View {
    @State private var isAnimating: Bool = false
    private let styles = UIStyles.shared

    var body: some View {
        HStack { // Use HStack to align left, similar to old indicator
            Circle()
                .fill(styles.colors.accent)
                .frame(width: 15, height: 15) // Base size of the dot
                .scaleEffect(isAnimating ? 1.35 : 0.8) // Pulse between smaller and larger
                .opacity(isAnimating ? 1.0 : 0.7) // Subtle opacity change
                .animation(
                    Animation.easeInOut(duration: 1.0) // Smooth animation duration
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true // Start animation on appear
                }
                .padding(.vertical, styles.layout.paddingM) // Use standard padding
                .padding(.leading, styles.layout.paddingM) // Align with assistant bubbles

            Spacer() // Push dot to the left
        }
        // Remove any background or container
    }
}

#Preview {
    BreathingDotIndicator()
        .background(Color.black)
}