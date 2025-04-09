import SwiftUI

struct DailyTaglineView: View {
    let tagline: String

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var styles = UIStyles.shared

    // Removed computed color logic

     // State for animation
     @State private var appeared: Bool = false

     var body: some View {
         Text(tagline)
             .font(styles.typography.largeTitle) // Use largest predefined title size
             .foregroundColor(styles.colors.textSecondary) // Use textSecondary color directly
             .multilineTextAlignment(.center)
             .frame(maxWidth: .infinity, alignment: .center)
             .padding(.vertical, styles.layout.spacingXL * 2) // Double vertical padding
             .padding(.horizontal, styles.layout.paddingL) // Horizontal padding
             // Animation modifiers
             .scaleEffect(appeared ? 1.0 : 0.95)
             .opacity(appeared ? 1.0 : 0.0)
             .onAppear {
                 // Use a slight delay for a nicer effect
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                     withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                         appeared = true
                     }
                 }
             }
             // Reset on disappear if desired, otherwise it stays revealed
             // .onDisappear { appeared = false }
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