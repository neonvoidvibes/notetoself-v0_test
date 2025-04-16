import SwiftUI

struct HeatmapDayCell: View {
    let dayInfo: HeatmapDayInfo // Use the shared struct
    @ObservedObject private var styles = UIStyles.shared

    private let cellSize: CGFloat = 36 // Increased size (2x of original 18)

    // Determine if the cell represents today
    private var isToday: Bool {
        Calendar.current.isDateInToday(dayInfo.date)
    }

    var body: some View {
        ZStack {
            // Base background/shape
            RoundedRectangle(cornerRadius: styles.layout.radiusM / 2)
                .fill(styles.colors.secondaryBackground.opacity(0.3)) // Standard background for all
                .frame(width: cellSize, height: cellSize)

            // Display Mood Icon if entry exists
            if let mood = dayInfo.mood {
                 mood.icon // Use the mood's icon property
                     .resizable()
                     .scaledToFit()
                     .foregroundColor(mood.journalColor) // Use journalColor
                     .frame(width: cellSize * 0.6, height: cellSize * 0.6) // Icon size relative to cell
                     .frame(width: cellSize * 0.6, height: cellSize * 0.6) // Icon size relative to cell
            }

            // REMOVED: Inner Ring Overlay for today indicator
        }
        .frame(width: cellSize, height: cellSize) // Ensure ZStack respects the size
        // REMOVED glow/shadow indicator

        // Day Number Overlay (dimmed, hidden if entry exists)
        .overlay(
             // Only show day number if there's NO entry for the day
             dayInfo.entry == nil ?
                 Text("\(Calendar.current.component(.day, from: dayInfo.date))")
                     .font(styles.typography.bodySmall) // Slightly smaller font
                     .foregroundColor(styles.colors.textSecondary.opacity(0.4)) // Dimmer text color
                     .frame(maxWidth: .infinity, maxHeight: .infinity) // Center it
                 : nil // Render nothing if there is an entry
         )
    }
}

#Preview {
    let styles = UIStyles.shared
    let today = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
    let mockEntryHappy = JournalEntry(text: "Happy day", mood: .happy, date: today)
    let mockEntrySad = JournalEntry(text: "Sad day", mood: .sad, date: yesterday)

    return HStack(spacing: 10) {
        HeatmapDayCell(dayInfo: HeatmapDayInfo(date: today, entry: mockEntryHappy))
        HeatmapDayCell(dayInfo: HeatmapDayInfo(date: yesterday, entry: mockEntrySad))
        HeatmapDayCell(dayInfo: HeatmapDayInfo(date: Calendar.current.date(byAdding: .day, value: -2, to: today)!, entry: nil)) // Empty
    }
    .padding()
    .background(styles.colors.appBackground)
    .environmentObject(styles)
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.dark)
}