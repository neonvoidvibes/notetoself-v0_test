import SwiftUI
import Charts

struct MoodTrendsDetailContent: View {
    let entries: [JournalEntry]
    private let styles = UIStyles.shared

    var body: some View {
        VStack(spacing: styles.layout.spacingL) {
            if #available(iOS 16.0, *) {
                // Detailed mood chart
                DetailedMoodChart(entries: entries)
                    .frame(height: 250)
                    .padding(.vertical, styles.layout.paddingL)
            } else {
                Text("Detailed mood chart requires iOS 16 or later")
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
            }

            // Mood insights
            MoodInsightsView(entries: entries)
                .padding(.vertical, styles.layout.paddingL)
        }
    }
}

@available(iOS 16.0, *)
struct DetailedMoodChart: View {
    let entries: [JournalEntry]
    @State private var timeRange: TimeRange = .month
    private let styles = UIStyles.shared

    enum TimeRange: String, CaseIterable, Identifiable { // Add Identifiable
        case week = "Week"
        case month = "Month"
        case year = "Year"
        var id: String { self.rawValue } // Conform to Identifiable
    }


    private var filteredEntries: [JournalEntry] {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        switch timeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        }

        return entries
            .filter { $0.date >= startDate }
            .sorted { $0.date < $1.date }
    }

    private var moodData: [MoodDataPoint] { // Uses global MoodDataPoint
        let calendar = Calendar.current
        var result: [MoodDataPoint] = []

        // Create a dictionary to group entries by day
        var entriesByDay: [Date: JournalEntry] = [:]

        for entry in filteredEntries {
            let day = calendar.startOfDay(for: entry.date)
            entriesByDay[day] = entry
        }

        // Fill in the days based on selected time range
        let now = Date()
        let daysToFill: Int
        switch timeRange {
        case .week: daysToFill = 7
        case .month: daysToFill = 30
        case .year: daysToFill = 365
        }

        for dayOffset in (0..<daysToFill).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: now)) {
                let entry = entriesByDay[date]

                let moodValue: Double
                if let entry = entry {
                    switch entry.mood {
                    case .happy: moodValue = 4
                    case .excited: moodValue = 5
                    case .neutral: moodValue = 3
                    case .stressed: moodValue = 2
                    case .sad: moodValue = 1
                    // Add other moods if necessary
                    case .alert: moodValue = 4.5
                    case .content: moodValue = 4.2
                    case .relaxed: moodValue = 4.0
                    case .calm: moodValue = 3.8
                    case .bored: moodValue = 2.5
                    case .depressed: moodValue = 1.0
                    case .anxious: moodValue = 1.8
                    case .angry: moodValue = 1.5
                    }
                } else {
                    moodValue = 0 // No entry for this day
                }

                result.append(MoodDataPoint(date: date, value: moodValue))
            }
        }

        return result
    }


    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            // Time range selector
            Picker("Time Range", selection: $timeRange) {
                ForEach(TimeRange.allCases) { range in // Iterate over cases
                     Text(range.rawValue).tag(range)
                 }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, styles.layout.paddingL)

            // Chart
            Chart {
                ForEach(moodData) { dataPoint in // Use global MoodDataPoint (Identifiable)
                    if dataPoint.value > 0 {
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Mood", dataPoint.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [styles.colors.accent, styles.colors.accent.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Mood", dataPoint.value)
                        )
                        .foregroundStyle(styles.colors.accent)
                        .symbolSize(30)
                    }
                }
            }
            .chartYScale(domain: 1...5)
            .chartYAxis {
                AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                    AxisValueLabel {
                        switch value.index {
                        case 0: Text("Sad").font(styles.typography.caption)
                        case 1: Text("Anxious").font(styles.typography.caption) // Or Stressed
                        case 2: Text("Neutral").font(styles.typography.caption)
                        case 3: Text("Happy").font(styles.typography.caption) // Or Content
                        case 4: Text("Excited").font(styles.typography.caption)
                        default: Text("")
                        }
                    }
                }
            }
            .chartXAxis {
                let stride: Calendar.Component
                let count: Int

                switch timeRange {
                case .week:
                    stride = .day
                    count = 1
                case .month:
                    stride = .day
                    count = 5
                case .year:
                    stride = .month
                    count = 1
                }

                return AxisMarks(values: .stride(by: stride, count: count)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatDate(date, timeRange: timeRange))
                                .font(styles.typography.caption)
                        }
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date, timeRange: TimeRange) -> String {
        let formatter = DateFormatter()

        switch timeRange {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "d MMM"
        case .year:
            formatter.dateFormat = "MMM"
        }

        return formatter.string(from: date)
    }
}

struct MoodInsightsView: View {
    let entries: [JournalEntry]
    private let styles = UIStyles.shared

    private var moodCounts: [Mood: Int] {
        entries.reduce(into: [Mood: Int]()) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
    }

    private var topMoods: [(mood: Mood, count: Int)] {
        moodCounts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }

    private var moodTrend: String {
        // Simple trend analysis based on recent entries
        let sortedEntries = entries.sorted { $0.date > $1.date }
        let recentEntries = sortedEntries.prefix(5)
        let oldEntries = sortedEntries.dropFirst(5).prefix(5)


        if recentEntries.isEmpty || oldEntries.isEmpty {
            return "Not enough data"
        }

        // Helper to convert mood to a numeric value for averaging
         func moodValue(_ mood: Mood) -> Double {
             switch mood {
             case .happy: return 4
             case .excited: return 5
             case .neutral: return 3
             case .stressed: return 2
             case .sad: return 1
             // Add other moods if necessary
             case .alert: return 4.5
             case .content: return 4.2
             case .relaxed: return 4.0
             case .calm: return 3.8
             case .bored: return 2.5
             case .depressed: return 1.0
             case .anxious: return 1.8
             case .angry: return 1.5
             }
         }


        let recentAvg = recentEntries.map { moodValue($0.mood) }.reduce(0.0, +) / Double(recentEntries.count)
        let oldAvg = oldEntries.map { moodValue($0.mood) }.reduce(0.0, +) / Double(oldEntries.count)


        if recentAvg > oldAvg + 0.5 { // Increased threshold for significance
            return "Improving"
        } else if recentAvg < oldAvg - 0.5 { // Increased threshold
            return "Declining"
        } else {
            return "Stable"
        }
    }


    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Mood Insights")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Top moods
            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                Text("Your Top Moods")
                    .font(styles.typography.bodyLarge)
                    .foregroundColor(styles.colors.text)

                HStack(spacing: styles.layout.spacingL) {
                    ForEach(topMoods, id: \.mood) { moodData in
                        VStack(spacing: 8) {
                            Image(systemName: moodData.mood.systemIconName)
                                .foregroundColor(moodData.mood.color)
                                .font(.system(size: 24))

                            Text(moodData.mood.name)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)

                            Text("\(moodData.count) entries")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    // Add placeholders if fewer than 3 top moods
                     ForEach(0..<(3 - topMoods.count), id: \.self) { _ in
                         VStack(spacing: 8) {
                             Image(systemName: "circle.dashed")
                                 .foregroundColor(styles.colors.textSecondary)
                                 .font(.system(size: 24))
                             Text("N/A")
                                 .font(styles.typography.bodyFont)
                                 .foregroundColor(styles.colors.textSecondary)
                             Text(" ") // Placeholder for count
                                 .font(styles.typography.caption)
                                 .foregroundColor(styles.colors.textSecondary)
                         }
                         .frame(maxWidth: .infinity)
                     }
                }
            }
            .padding(.vertical, styles.layout.paddingM)

            // Mood trend
            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                Text("Your Mood Trend")
                    .font(styles.typography.bodyLarge)
                    .foregroundColor(styles.colors.text)

                HStack {
                    Image(systemName: moodTrend == "Improving" ? "arrow.up.circle.fill" : 
                                     moodTrend == "Declining" ? "arrow.down.circle.fill" : "equal.circle.fill") // Use equal for stable
                        .foregroundColor(moodTrend == "Improving" ? Mood.happy.color : // Use Mood enum color
                                         moodTrend == "Declining" ? Mood.sad.color : Mood.neutral.color) // Use Mood enum color
                        .font(.system(size: 32))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(moodTrend)
                            .font(styles.typography.bodyLarge)
                            .foregroundColor(styles.colors.text)

                        Text("Based on recent vs. earlier entries") // Simplified description
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary)
                    }
                }
                .padding(.vertical, styles.layout.paddingM)
            }
        }
    }
}