import SwiftUI

struct CalendarInsightCard: View {
    @Binding var selectedMonth: Date
    let entries: [JournalEntry]
    @State private var isExpanded: Bool = false

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    // Month navigation
                    HStack {

                        Spacer()

                        HStack(spacing: styles.layout.spacingM) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)!
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(styles.colors.accent)
                            }

                            Text(monthYearString(from: selectedMonth))
                                .font(styles.typography.label)
                                .foregroundColor(styles.colors.text)

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)!
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(styles.colors.accent)
                            }
                        }
                    }

                    // Weekday headers
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Calendar days
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(daysInMonth(), id: \.self) { day in
                            if day.day != 0 {
                                CalendarDayView(day: day, entries: entries)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                // Empty cell for days not in this month
                                Color.clear
                                    .frame(height: 40)
                            }
                        }
                    }

                    // Add a simple insight about the month's activity
                    Text(generateMonthlyInsight())
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, styles.layout.spacingS)
                        .lineLimit(2)
                }
            },
            detailContent: {
                // Expanded detail content
                VStack(spacing: styles.layout.spacingL) {
                    // Monthly statistics
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Monthly Statistics")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)

                        HStack(spacing: styles.layout.spacingXL) {
                            MonthlyStatItem(
                                title: "Total Entries",
                                value: "\(entriesInMonth().count)",
                                icon: "doc.text.fill",
                                styles: styles
                            )

                            MonthlyStatItem(
                                title: "Coverage",
                                value: "\(calculateCoverage())%",
                                icon: "calendar.badge.clock",
                                styles: styles
                            )

                            MonthlyStatItem(
                                title: "Avg. Words",
                                value: "\(calculateAverageWords())",
                                icon: "text.word.spacing",
                                styles: styles
                            )
                        }
                    }

                    // Mood distribution for the month
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Mood Distribution")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)

                        HStack(spacing: styles.layout.spacingM) {
                            ForEach(topMoodsInMonth(), id: \.mood) { moodData in
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(moodData.mood.color)
                                        .frame(width: 24, height: 24)

                                    Text(moodData.mood.name)
                                        .font(styles.typography.bodySmall)
                                        .foregroundColor(styles.colors.text)

                                    Text("\(moodData.percentage)%")
                                        .font(styles.typography.caption)
                                        .foregroundColor(styles.colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    // Monthly patterns
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Monthly Patterns")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)

                        Text(identifyMonthlyPatterns())
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        )
    }

    // Helper methods for expanded content
    private func entriesInMonth() -> [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            let entryComponents = calendar.dateComponents([.year, .month], from: entry.date)
            let selectedComponents = calendar.dateComponents([.year, .month], from: selectedMonth)
            return entryComponents.year == selectedComponents.year && entryComponents.month == selectedComponents.month
        }
    }

    private func calculateCoverage() -> Int {
        let calendar = Calendar.current
        guard let daysInMonthRange = calendar.range(of: .day, in: .month, for: selectedMonth) else { return 0 }
        let daysInMonth = daysInMonthRange.count
        guard daysInMonth > 0 else { return 0 }
        return Int(Double(entriesInMonth().count) / Double(daysInMonth) * 100)
    }


    private func calculateAverageWords() -> Int {
        let monthEntries = entriesInMonth()
        guard !monthEntries.isEmpty else { return 0 }

        let totalWords = monthEntries.reduce(0) { total, entry in
            total + entry.text.split(separator: " ").count
        }

        return totalWords / monthEntries.count
    }

    private func topMoodsInMonth() -> [(mood: Mood, percentage: Int)] {
        let monthEntries = entriesInMonth()
        guard !monthEntries.isEmpty else { return [] }

        // Count occurrences of each mood
        var moodCounts: [Mood: Int] = [:]
        for entry in monthEntries {
            moodCounts[entry.mood, default: 0] += 1
        }

        // Convert to percentages and sort
        let totalEntries = monthEntries.count
        let moodPercentages = moodCounts.map { mood, count in
            (mood: mood, percentage: Int(Double(count) / Double(totalEntries) * 100))
        }

        // Return top 3 moods
        return moodPercentages.sorted { $0.percentage > $1.percentage }.prefix(3).map { $0 }
    }

    private func identifyMonthlyPatterns() -> String {
        let monthEntries = entriesInMonth()
        if monthEntries.count < 5 {
            return "Add more entries this month to reveal patterns in your journaling habits and emotional experiences."
        }

        // Analyze weekly patterns
        let calendar = Calendar.current
        var entriesByWeekday: [Int: [JournalEntry]] = [:]

        for entry in monthEntries {
            let weekday = calendar.component(.weekday, from: entry.date)
            if entriesByWeekday[weekday] == nil {
                entriesByWeekday[weekday] = []
            }
            entriesByWeekday[weekday]?.append(entry)
        }

        // Find most and least active days
        let mostActiveDay = entriesByWeekday.max { $0.value.count < $1.value.count }
        let leastActiveDay = entriesByWeekday.min { $0.value.count < $1.value.count }

        var patternText = ""

        if let mostActiveDay = mostActiveDay, let leastActiveDay = leastActiveDay, mostActiveDay.key != leastActiveDay.key {
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEEE"

            let mostActiveDayName = weekdayFormatter.string(from: nextWeekday(weekday: mostActiveDay.key))
            let leastActiveDayName = weekdayFormatter.string(from: nextWeekday(weekday: leastActiveDay.key))

            patternText += "You tend to journal most often on \(mostActiveDayName)s and least often on \(leastActiveDayName)s. "
        }

        // Analyze time-of-month patterns
        let earlyMonthEntries = monthEntries.filter { entry in
            let day = calendar.component(.day, from: entry.date)
            return day <= 10
        }

        let midMonthEntries = monthEntries.filter { entry in
            let day = calendar.component(.day, from: entry.date)
            return day > 10 && day <= 20
        }

        let lateMonthEntries = monthEntries.filter { entry in
            let day = calendar.component(.day, from: entry.date)
            return day > 20
        }

        let maxEntries = max(earlyMonthEntries.count, midMonthEntries.count, lateMonthEntries.count)

        if earlyMonthEntries.count == maxEntries && maxEntries > 0 {
            patternText += "You tend to journal more at the beginning of the month. "
        } else if midMonthEntries.count == maxEntries && maxEntries > 0 {
            patternText += "You tend to journal more in the middle of the month. "
        } else if lateMonthEntries.count == maxEntries && maxEntries > 0 {
            patternText += "You tend to journal more at the end of the month. "
        }

        if patternText.isEmpty {
            patternText = "Your journaling pattern is fairly consistent throughout the month, without strong preferences for specific times."
        }

        return patternText.isEmpty ? "Your journaling shows a balanced pattern throughout the month." : patternText
    }

    private func nextWeekday(weekday: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today)

        let daysToAdd = (weekday - todayWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd, to: today)!
    }

    // Add this method to generate insights about the month's activity
    private func generateMonthlyInsight() -> String {
        let calendar = Calendar.current
        let monthEntries = entries.filter { entry in
            let entryComponents = calendar.dateComponents([.year, .month], from: entry.date)
            let selectedComponents = calendar.dateComponents([.year, .month], from: selectedMonth)
            return entryComponents.year == selectedComponents.year && entryComponents.month == selectedComponents.month
        }

        if monthEntries.isEmpty {
            return "No entries for this month yet. Each entry helps build your personal timeline."
        }

        guard let daysInMonthRange = calendar.range(of: .day, in: .month, for: selectedMonth) else {
             return "Could not determine days in month."
        }
        let daysInMonth = daysInMonthRange.count
        guard daysInMonth > 0 else { return "Invalid month data." }

        let percentage = Int(Double(monthEntries.count) / Double(daysInMonth) * 100)


        if calendar.isDateInToday(selectedMonth) || calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month) {
            // Current month
            return "You've journaled \(monthEntries.count) days this month (\(percentage)% coverage)."
        } else {
            // Past or future month
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            let monthName = formatter.string(from: selectedMonth)
            return "You journaled \(monthEntries.count) days in \(monthName) (\(percentage)% of the month)."
        }
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func daysInMonth() -> [CalendarDay] {
        let calendar = Calendar.current

        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        let firstDayOfMonth = calendar.date(from: components)!

        // Get the weekday of the first day (1 = Sunday, 2 = Monday, etc. based on locale)
        // Adjust to be 0-based for array indexing if needed, or handle 1-based directly.
        // Let's assume Calendar.current.firstWeekday defines the start.
        // We need the weekday of the *first day* of the month.
        let firstWeekdayOfMonth = calendar.component(.weekday, from: firstDayOfMonth)

        // Calculate the offset needed for the grid (e.g., if Sunday=1, Monday=2 and first day is Tuesday (3), offset is 2)
        // The offset is (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7
        let gridOffset = (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7


        // Get the number of days in the month
        guard let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else { return [] }
        let numDays = range.count

        var days: [CalendarDay] = []

        // Add empty cells for days before the first day of the month
        for _ in 0..<gridOffset {
            days.append(CalendarDay(day: 0, date: Date())) // Use 0 to represent empty days
        }


        // Add cells for each day of the month
        for day in 1...numDays {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)!
            days.append(CalendarDay(day: day, date: date))
        }

        return days
    }
}

// Helper view for monthly stats in expanded view
struct MonthlyStatItem: View {
    let title: String
    let value: String
    let icon: String
    // Pass styles if used independently, otherwise remove. Assume parent passes or use ObservedObject.
    // Let's add ObservedObject for robustness.
    @ObservedObject var styles = UIStyles.shared

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(styles.colors.accent)
                .font(.system(size: 24))

            Text(value)
                .font(styles.typography.insightValue)
                .foregroundColor(styles.colors.text)

            Text(title)
                .font(styles.typography.caption)
                .foregroundColor(styles.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Renamed CalendarDayView from InsightsView to avoid name conflict
// This view is specific to the CalendarInsightCard
struct CalendarDayView: View {
    let day: CalendarDay
    let entries: [JournalEntry]

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    private var hasEntry: Bool {
        let calendar = Calendar.current
        return entries.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: day.date)
        }
    }

    private var entryMood: Mood? {
        let calendar = Calendar.current
        return entries.first { entry in
            calendar.isDate(entry.date, inSameDayAs: day.date)
        }?.mood
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }

    var body: some View {
        ZStack {
            // Background circle with subtle gradient for depth
            if hasEntry {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    entryMood?.color.opacity(0.4) ?? styles.colors.accent.opacity(0.4),
                                    entryMood?.color.opacity(0.2) ?? styles.colors.accent.opacity(0.2)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
            }

            if isToday {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    styles.colors.accent,
                                    styles.colors.accent.opacity(0.7)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 40, height: 40)
            }

            Text("\(day.day)")
                .font(styles.typography.bodyFont)
                .foregroundColor(hasEntry ? styles.colors.text : styles.colors.textSecondary)
        }
        .frame(height: 40)
    }
}