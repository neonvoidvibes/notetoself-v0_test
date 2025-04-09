import SwiftUI

struct DailyTaglineView: View {
    let tagline: String

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var styles = UIStyles.shared

    // Removed computed color logic

     // State for persistent pulse animation
     @State private var pulsing: Bool = false

     // Define the gradient
     private var textGradient: LinearGradient {
         LinearGradient(
             gradient: Gradient(colors: [
                 styles.colors.accent, // Start with accent
                 colorScheme == .dark ? styles.colors.secondaryAccent : styles.colors.accent.opacity(0.7) // End with secondaryAccent (dark) or lighter accent (light)
             ]),
             startPoint: .topLeading,
             endPoint: .bottomTrailing
         )
     }

     var body: some View {
         ZStack {
             // Subtle background glow elements
             Circle()
                 .fill(styles.colors.accent.opacity(0.08))
                 .blur(radius: 30)
                 .frame(width: 150, height: 150)
                 .offset(x: -50, y: -20)

             Circle()
                  .fill(styles.colors.secondaryAccent.opacity(0.06))
                  .blur(radius: 40)
                  .frame(width: 180, height: 180)
                  .offset(x: 60, y: 30)

             // Tagline Text
             Text(tagline)
                 .font(styles.typography.largeTitle)
                 // Apply gradient using foregroundStyle
                 .foregroundStyle(textGradient)
                 .multilineTextAlignment(.center)
                 .frame(maxWidth: .infinity, alignment: .center)
                 .padding(.vertical, styles.layout.spacingXL * 2) // Double vertical padding
                 .padding(.horizontal, styles.layout.paddingL) // Horizontal padding
                 // Persistent Pulse Animation
                 .scaleEffect(pulsing ? 1.02 : 1.0) // Subtle scale change
                 .onAppear {
                     // Start the continuous animation
                     withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                         pulsing = true
                     }
                 }
         }
         // Clip the ZStack to prevent glow from extending too far if needed
         // .clipShape(Rectangle())
     }
 }

#Preview {
    VStack {
        DailyTaglineView(tagline: "Keep showing up.")
            .background(Color.gray.opacity(0.1))

        DailyTaglineView(tagline: "See yourself clearer.")
            .background(Color.gray.opacity(0.1))

        DailyTaglineView(tagline: "Turn emotion into insight.")
            .background(Color.gray.opacity(0.1))
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.light) // Preview light mode
}

#Preview("Dark Mode") {
    VStack {
        DailyTaglineView(tagline: "Keep showing up.")
            .background(Color.black)

        DailyTaglineView(tagline: "See yourself clearer.")
            .background(Color.black)

        DailyTaglineView(tagline: "Turn emotion into insight.")
            .background(Color.black)
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.dark) // Preview dark mode
}