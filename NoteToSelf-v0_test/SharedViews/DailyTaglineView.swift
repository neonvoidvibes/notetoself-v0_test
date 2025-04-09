import SwiftUI

struct DailyTaglineView: View {
    let tagline: String

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var styles = UIStyles.shared

    // Computed color based on color scheme
    private var taglineColor: Color {
        colorScheme == .dark ? styles.colors.secondaryAccent : styles.colors.accent
    }

    var body: some View {
         Text(tagline)
             .font(styles.typography.largeTitle) // Use largest predefined title size
             .foregroundColor(taglineColor) // Adaptive color
             .multilineTextAlignment(.center)
             .frame(maxWidth: .infinity, alignment: .center)
             .padding(.vertical, styles.layout.spacingXL * 2) // Double vertical padding
             .padding(.horizontal, styles.layout.paddingL) // Horizontal padding
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