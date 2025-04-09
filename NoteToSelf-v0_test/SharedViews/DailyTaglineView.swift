import SwiftUI

struct DailyTaglineView: View {
    let tagline: String
    let iconName: String // Add parameter for icon name

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var styles = UIStyles.shared

    // Removed computed color logic

     // Removed pulsing state variable

     // Removed textGradient definition

     var body: some View {
         ZStack { // Use ZStack to layer icon behind text
             // Background Icon
             Image(systemName: iconName) // Use the parameter here
                 .resizable()
                 .scaledToFit()
                 .frame(width: 120, height: 120) // Large size
                 .foregroundColor(styles.colors.textSecondary.opacity(0.1)) // Adaptive gray (light/dark) via textSecondary, very low opacity

             // Tagline Text
             Text(tagline)
                 .font(styles.typography.largeTitle)
                 .foregroundColor(styles.colors.accent) // Use accent color directly
                 .multilineTextAlignment(.center)
                 .frame(maxWidth: .infinity, alignment: .center)
                 .padding(.vertical, styles.layout.spacingXL * 3) // Keep increased vertical padding
                 .padding(.horizontal, styles.layout.paddingL) // Horizontal padding
                 // Removed animation modifiers
                 // Removed background capsule
         }
     }
 }

#Preview {
    VStack {
        DailyTaglineView(tagline: "Keep showing up.", iconName: "book.closed.fill") // Journal icon
            .background(Color.gray.opacity(0.1))

        DailyTaglineView(tagline: "See yourself clearer.", iconName: "puzzlepiece.extension.fill") // Insights icon
            .background(Color.gray.opacity(0.1))

        DailyTaglineView(tagline: "Turn emotion into insight.", iconName: "bubble.left.and.bubble.right.fill") // Reflect icon
            .background(Color.gray.opacity(0.1))
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.light) // Preview light mode
}

 #Preview("Dark Mode") {
     VStack {
         DailyTaglineView(tagline: "Keep showing up.", iconName: "book.closed.fill") // Journal icon
             .background(Color.black)

         DailyTaglineView(tagline: "See yourself clearer.", iconName: "puzzlepiece.extension.fill") // Insights icon
             .background(Color.black)

         DailyTaglineView(tagline: "Turn emotion into insight.", iconName: "bubble.left.and.bubble.right.fill") // Reflect icon
             .background(Color.black)
     }
     .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.dark) // Preview dark mode
}