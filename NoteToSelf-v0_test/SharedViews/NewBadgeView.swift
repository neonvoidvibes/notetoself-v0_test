import SwiftUI

// MARK: - Reusable New Badge View
struct NewBadgeView: View {
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        Text("NEW")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(styles.colors.accentContrastText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(styles.colors.accent.opacity(0.9))
            .clipShape(Capsule())
    }
}

#Preview {
    NewBadgeView()
        .padding()
        .background(Color.gray)
        .environmentObject(UIStyles.shared)
        .environmentObject(ThemeManager.shared)
}