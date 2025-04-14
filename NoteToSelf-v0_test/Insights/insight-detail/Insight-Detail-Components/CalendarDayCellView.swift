import SwiftUI

struct CalendarDayCellView: View {
    let date: Date? // The actual date this cell represents
    let latestEntry: JournalEntry? // Pass the latest entry for the day
    let isToday: Bool

    @ObservedObject private var styles = UIStyles.shared
    private let cellSize: CGFloat = 36 // Adjust size as needed

    // Determine properties based on latestEntry
    private var hasEntry: Bool { latestEntry != nil }
    private var mood: Mood? { latestEntry?.mood }

    var body: some View {
        ZStack {
            // Base background/shape
            RoundedRectangle(cornerRadius: styles.layout.radiusM / 2)
                .fill(styles.colors.secondaryBackground.opacity(0.3)) // Subtle base fill
                .frame(width: cellSize, height: cellSize)

            // Fill indicating an entry exists
            if hasEntry {
                RoundedRectangle(cornerRadius: styles.layout.radiusM / 2)
                    .fill(styles.colors.accent.opacity(0.3)) // Slightly stronger fill for entries
                    .frame(width: cellSize, height: cellSize)
            }

            // Mood Indicator Dot (if entry exists)
            if hasEntry, let mood = mood {
                Circle()
                    .fill(mood.color) // Use mood color from the latest entry
                    .frame(width: 8, height: 8) // Small dot size
                    .offset(y: cellSize / 2 - 6) // Position near bottom-center
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 0.5) // Subtle shadow for dot
            }

            // Today Indicator Border
            if isToday {
                RoundedRectangle(cornerRadius: styles.layout.radiusM / 2)
                    .stroke(styles.colors.accent, lineWidth: 2)
                    .frame(width: cellSize, height: cellSize)
            }
        }
        .frame(width: cellSize, height: cellSize) // Ensure ZStack respects the size
        // The tap action is now handled by the Button wrapping this view in MiniCalendarHeatmapView
    }
}

#Preview {
    let styles = UIStyles.shared
    let today = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
    let mockEntryHappy = JournalEntry(text: "Happy day", mood: .happy, date: today)
    let mockEntrySad = JournalEntry(text: "Sad day", mood: .sad, date: yesterday)

    return HStack(spacing: 10) {
        CalendarDayCellView(date: today, latestEntry: mockEntryHappy, isToday: true)
        CalendarDayCellView(date: yesterday, latestEntry: mockEntrySad, isToday: false)
        CalendarDayCellView(date: Calendar.current.date(byAdding: .day, value: -2, to: today)!, latestEntry: nil, isToday: false)
        CalendarDayCellView(date: Calendar.current.date(byAdding: .day, value: -3, to: today)!, latestEntry: JournalEntry(text: "Neutral day", mood: .neutral, date: Calendar.current.date(byAdding: .day, value: -3, to: today)!), isToday: false)
    }
    .padding()
    .background(styles.colors.appBackground)
    .environmentObject(styles)
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.dark)
}