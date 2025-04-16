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
            RoundedRectangle(cornerRadius: styles.layout.radiusM / 2) // Keep subtle rounding
                // Slightly more visible background than before
                .fill(styles.colors.secondaryBackground.opacity(isToday ? 0.5 : 0.3))
                .frame(width: cellSize, height: cellSize)

            // Display Mood Icon if entry exists
            if let mood = dayInfo.mood {
                 mood.icon // Use the mood's icon property
                     .resizable()
                     .scaledToFit()
                     .foregroundColor(mood.color) // Color the icon with the mood color
                     .frame(width: cellSize * 0.6, height: cellSize * 0.6) // Icon size relative to cell
                     .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1) // Subtle shadow for icon pop
            }

            // Today Indicator Border (subtle accent)
            if isToday {
                RoundedRectangle(cornerRadius: styles.layout.radiusM / 2)
                    .stroke(styles.colors.accent.opacity(0.8), lineWidth: 1.5) // Slightly thicker, less opaque
                    .frame(width: cellSize - 1, height: cellSize - 1) // Inset slightly
            }
        }
        .frame(width: cellSize, height: cellSize) // Ensure ZStack respects the size
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