import SwiftUI

struct EntryPreviewPopupView: View {
    let entry: JournalEntry
    @Binding var isVisible: Bool // Binding to dismiss the popup

    @ObservedObject private var styles = UIStyles.shared
    @Environment(\.colorScheme) private var colorScheme // To adapt blur

    // Truncate text for preview
    private var truncatedText: String {
        let lines = entry.text.split(whereSeparator: \.isNewline)
        // Take first 5 lines, join them, then truncate to 250 chars
        return lines.prefix(5).joined(separator: "\n").prefix(250) + (entry.text.count > 250 || lines.count > 5 ? "..." : "")
    }

    var body: some View {
        VStack(spacing: 0) { // Use spacing 0 and manage padding internally
            // Header with Mood and Date
            HStack {
                // Mood Icon and Name
                HStack(spacing: styles.layout.spacingS) {
                    entry.mood.icon
                        .foregroundColor(entry.mood.color)
                        .font(.system(size: 20))
                    Text(entry.mood.name)
                        .font(styles.typography.bodyFont.weight(.medium))
                        .foregroundColor(styles.colors.text)
                }
                Spacer()
                // Date
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(styles.typography.caption)
                    .foregroundColor(styles.colors.textSecondary)
                // Close Button
                Button {
                    withAnimation { isVisible = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                }
            }
            .padding([.horizontal, .top], styles.layout.paddingL) // Padding for header
            .padding(.bottom, styles.layout.spacingM)

            // Divider
            Divider().background(styles.colors.divider.opacity(0.5))

            // Scrollable Text Preview
            ScrollView {
                Text(truncatedText)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(styles.layout.paddingL) // Padding for text
            }
            // Limit the height of the scroll view
            .frame(maxHeight: 200)

            // Divider
            Divider().background(styles.colors.divider.opacity(0.5))

            // Footer with Expand Button
            HStack {
                Spacer() // Push button to the right
                Button("View Full Entry") {
                    // TODO: Implement action to open full entry view
                    // This might involve:
                    // 1. Dismissing this popup (isVisible = false)
                    // 2. Communicating the entry ID back to JournalView (e.g., via @Binding, closure, or Notification)
                    // 3. JournalView then presents the FullscreenEntryView
                    print("Expand button tapped for entry: \(entry.id)")
                    withAnimation { isVisible = false } // Dismiss for now
                }
                .buttonStyle(UIStyles.SecondaryButtonStyle()) // Use secondary style
                .padding(styles.layout.paddingL) // Padding for footer
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.85, height: 350) // Fixed size for the popup
        .background(
            // Use theme-aware blur
            BlurView(style: colorScheme == .dark ? styles.currentTheme.blurStyleDark : styles.currentTheme.blurStyleLight)
                .overlay(styles.colors.secondaryBackground.opacity(0.5)) // Overlay with semi-transparent background
        )
        .cornerRadius(styles.layout.radiusL * 1.5) // More rounded corners
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .transition(.scale.combined(with: .opacity)) // Ensure transition is applied
    }
}

#Preview {
    let entry = JournalEntry(
        text: "This is the first line.\nThis is the second line, which might be a bit longer.\nThird line.\nFourth line.\nFifth line.\nSixth line should be truncated.\nAnd this definitely won't show.",
        mood: .happy,
        date: Date()
    )
    @State var isVisible = true

    return ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        EntryPreviewPopupView(entry: entry, isVisible: $isVisible)
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
}