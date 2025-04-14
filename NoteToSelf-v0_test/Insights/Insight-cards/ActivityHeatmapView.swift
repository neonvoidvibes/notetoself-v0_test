import SwiftUI

// RENAMED struct
struct ActivityHeatmapView: View {
    let data: [HeatmapDayInfo] // Expects 35 days, ordered chronologically
    let onTapDay: (JournalEntry) -> Void // Callback when a day with an entry is tapped

    @ObservedObject private var styles = UIStyles.shared
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7) // 7 columns for days

    // Helper to get weekday symbols starting from the system's first day of the week
    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        // Use veryShortWeekdaySymbols ("S", "M", "T", etc.)
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1 // 0-based index (0=Sun for US)

        // Ensure we have 7 symbols
        guard symbols.count == 7 else { return ["S","M","T","W","T","F","S"] } // Fallback

        // Reorder symbols based on the system's first day of the week
        let reorderedSymbols = Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
        return reorderedSymbols
    }

    // Explicit Initializer
    internal init(data: [HeatmapDayInfo], onTapDay: @escaping (JournalEntry) -> Void) {
        self.data = data
        self.onTapDay = onTapDay
    }

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingS) {
            // Weekday Labels
            HStack(spacing: 4) { // Match grid spacing
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .medium)) // Small, medium weight
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity) // Distribute labels evenly
                }
            }

            // Heatmap Grid
            LazyVGrid(columns: columns, spacing: 4) { // Minimal spacing
                ForEach(data) { dayInfo in
                    HeatmapDayCell(dayInfo: dayInfo, onTap: onTapDay)
                }
            }
        }
        // Add horizontal padding to align with card content if needed,
        // or let the parent container handle padding.
        // .padding(.horizontal, styles.layout.paddingL)
    }
}

#Preview {
    // Create mock data for preview
    let calendar = Calendar.current
    let today = Date()
    let mockEntries = (0..<20).map { i -> JournalEntry in
        let date = calendar.date(byAdding: .day, value: -i * 2, to: today)!
        let mood = Mood.allCases.randomElement() ?? .neutral
        return JournalEntry(text: "Entry \(i)", mood: mood, date: date)
    } + [JournalEntry(text: "Today", mood: .happy, date: today)]

    // Use static helper from JourneyInsightCard for consistency
    let data = JourneyInsightCard.prepareHeatmapData(for: today, using: mockEntries)

    // Use RENAMED struct in preview
    ActivityHeatmapView(data: data) { entry in
        print("Tapped entry: \(entry.id)")
    }
    .padding()
    .background(Color.black)
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.dark)
}