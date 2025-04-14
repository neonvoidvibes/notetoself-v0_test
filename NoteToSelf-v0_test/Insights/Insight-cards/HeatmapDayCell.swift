import SwiftUI

struct HeatmapDayCell: View {
    let dayInfo: HeatmapDayInfo
    let onTap: (JournalEntry) -> Void // Callback with the entry when tapped

    @ObservedObject private var styles = UIStyles.shared
    private let cellSize: CGFloat = 18 // Size of the cell

    var body: some View {
        ZStack {
            // Background for the cell area
            RoundedRectangle(cornerRadius: 3)
                 // Very faint background, slightly more visible if it's today
                .fill(styles.colors.secondaryBackground.opacity(isToday() ? 0.3 : 0.15))
                .frame(width: cellSize, height: cellSize)

            // Mood Dot if entry exists
            if let moodColor = dayInfo.moodColor {
                Circle()
                    .fill(moodColor)
                    // Make dot slightly smaller than the cell
                    .frame(width: cellSize * 0.7, height: cellSize * 0.7)
            }
        }
        .frame(width: cellSize, height: cellSize) // Ensure ZStack respects the cell size
        .contentShape(Rectangle()) // Define tappable area
        .onTapGesture {
            if let entry = dayInfo.entry {
                onTap(entry) // Trigger callback only if there's an entry
            }
        }
        // Add a subtle border if it's today for extra emphasis
        .overlay(
             RoundedRectangle(cornerRadius: 3)
                 .stroke(isToday() ? styles.colors.accent : Color.clear, lineWidth: 1)
         )
    }

    private func isToday() -> Bool {
        Calendar.current.isDateInToday(dayInfo.date)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    let yesterdayEntry = JournalEntry(text: "Yesterday", mood: .calm, date: calendar.date(byAdding: .day, value: -1, to: today)!)
    let emptyDay = Date()

    return HStack(spacing: 10) {
        // Day with entry
        HeatmapDayCell(dayInfo: HeatmapDayInfo(date: yesterdayEntry.date, entry: yesterdayEntry)) { _ in }
        // Empty day
        HeatmapDayCell(dayInfo: HeatmapDayInfo(date: emptyDay, entry: nil)) { _ in }
        // Today with entry
        HeatmapDayCell(dayInfo: HeatmapDayInfo(date: today, entry: yesterdayEntry)) { _ in }

    }
    .padding()
    .background(Color.black)
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.dark)
}