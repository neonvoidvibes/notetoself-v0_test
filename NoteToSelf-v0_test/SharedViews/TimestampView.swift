import SwiftUI

/// A reusable view to display an optional date as a relative timestamp.
struct TimestampView: View {
    let date: Date?
    @ObservedObject private var styles = UIStyles.shared // Observe styles

    // Initializer taking optional Date
    init(date: Date?) {
        self.date = date
    }

    var body: some View {
        if let date = date {
            HStack {
                Spacer() // Push to the right
                Text("Updated: \(date, style: .relative) ago")
                    .font(styles.typography.caption)
                    .foregroundColor(styles.colors.textSecondary.opacity(0.7))
            }
            .padding(.top, styles.layout.spacingS) // Consistent top padding
        } else {
            // Render nothing if date is nil, maintaining layout consistency elsewhere
            EmptyView()
        }
    }
}

#Preview {
    VStack {
        TimestampView(date: Date())
        TimestampView(date: Calendar.current.date(byAdding: .hour, value: -3, to: Date()))
        TimestampView(date: nil)
    }
    .padding()
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared) // Add ThemeManager for UIStyles dependency
    .background(Color.gray.opacity(0.1))
}