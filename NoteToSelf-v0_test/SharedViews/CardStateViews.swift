import SwiftUI

// Shared view for displaying a locked content message (Premium Feature)
struct LockedContentView: View {
    let message: String
    @ObservedObject var styles = UIStyles.shared // Observe styles

    init(message: String) { self.message = message }

    var body: some View {
         Text(message)
             .font(styles.typography.bodySmall)
             .foregroundColor(styles.colors.textSecondary)
             .frame(maxWidth: .infinity, minHeight: 80, alignment: .center) // Standard min height
             .multilineTextAlignment(.center)
             .padding(.vertical, styles.layout.paddingS)
    }
}

// Shared view for displaying an error message
struct ErrorView: View {
    let message: String
    @ObservedObject var styles = UIStyles.shared // Observe styles

    init(message: String) { self.message = message }

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(styles.colors.error)
            Text(message)
                .font(styles.typography.bodySmall)
                .foregroundColor(styles.colors.error)
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .center) // Standard min height
        .padding(.vertical, styles.layout.paddingS)
    }
}

// Shared view for displaying an empty state message (e.g., not enough data)
struct EmptyStateView: View {
    let message: String
    @ObservedObject var styles = UIStyles.shared // Observe styles

    init(message: String) { self.message = message }

    var body: some View {
         Text(message)
             .font(styles.typography.bodyFont)
             .foregroundColor(styles.colors.textSecondary)
             .frame(maxWidth: .infinity, minHeight: 80, alignment: .center) // Standard min height
             .multilineTextAlignment(.center)
             .padding(.vertical, styles.layout.paddingS)
    }
}

#Preview {
    VStack(spacing: 20) {
        LockedContentView(message: "Unlock with Premium.")
        ErrorView(message: "Could not load data.")
        EmptyStateView(message: "Journal more to see insights.")
    }
    .padding()
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .background(Color.gray.opacity(0.1))

}