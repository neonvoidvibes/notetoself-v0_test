import SwiftUI

// MARK: - Reusable Pro Badge View
struct ProBadgeView: View {
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold))
            // Use secondary accent (yellow) for background, primary text for contrast
            .foregroundColor(styles.colors.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(styles.colors.secondaryAccent.opacity(0.9)) // Use yellow
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        ProBadgeView()
        NewBadgeView()
    }
    .padding()
    .background(Color.gray)
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
}