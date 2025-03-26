import SwiftUI
import Charts

struct WeeklySummaryDetailContent: View {
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    
    private var weeklyEntries: [JournalEntry] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        return entries.filter { entry in
            let entryDate = entry.date
            return entryDate >= startOfWeek && entryDate <= today
        }.sorted(by: { $0.date < $1.date })
    }
    
    private var summaryPeriod: String {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate the start of the current week (Sunday)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        // Calculate the end of the week (Saturday)
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        // Format the dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        
        return "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endOfWeek))"
    }
    
    private var dominantMood: Mood? {
        let moodCounts = weeklyEntries.reduce(into: [Mood: Int]()) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private var moodDistribution: [(mood: Mood, count: Int)] {
        let moodCounts = weeklyEntries.reduce(into: [Mood: Int]()) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
        
        return moodCounts.map { (mood: $0.key, count: $0.value) }
            .sorted(by: { $0.count > $1.count })
    }
    
    private var entryCount: Int {
        return weeklyEntries.count
    }
    
    private var averageWordCount: Int {
        guard !weeklyEntries.isEmpty else { return 0 }
        
        let totalWords = weeklyEntries.reduce(0) { total, entry in
            total + entry.text.split(separator: " ").count
        }
        
        return totalWords / weeklyEntries.count
    }
    
    private var weekdayMoodData: [(weekday: String, mood: Double)] {
        let calendar = Calendar.current
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var result: [(weekday: String, mood: Double)] = []
        
        // Group entries by weekday
        var entriesByWeekday: [Int: [JournalEntry]] = [:]
        
        for entry in weeklyEntries {
            let weekday = calendar.component(.weekday, from: entry.date) - 1 // 0-based index
            if entriesByWeekday[weekday] == nil {
                entriesByWeekday[weekday] = []
            }
            entriesByWeekday[weekday]?.append(entry)
        }
        
        // Calculate average mood value for each weekday
        for weekdayIndex in 0..<7 {
            let entries = entriesByWeekday[weekdayIndex] ?? []
            let moodValue: Double
            
            if entries.isEmpty {
                moodValue = 0 // No entry
            } else {
                // Calculate average mood value
                let total = entries.reduce(0.0) { sum, entry in
                    let value: Double
                    switch entry.mood {
                    case .happy: value = 4
                    case .excited: value = 5
                    case .neutral: value = 3
                    case .stressed: value = 2
                    case .sad: value = 1
                    default: value = 3 // Default to neutral for other moods
                    }
                    return sum + value
                }
                moodValue = total / Double(entries.count)
            }
            
            result.append((weekday: weekdays[weekdayIndex], mood: moodValue))
        }
        
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: styles.layout.spacingXL) {
                // Header section
                VStack(spacing: styles.layout.spacingM) {
                    Text(summaryPeriod)
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    // Summary stats
                    HStack(spacing: styles.layout.spacingXL) {
                        StatItem(
                            value: "\(entryCount)",
                            label: "Entries",
                            icon: "doc.text.fill"
                        )
                        
                        StatItem(
                            value: dominantMood?.name ?? "N/A",
                            label: "Dominant Mood",
                            icon: "face.smiling.fill",
                            color: dominantMood?.color ?? styles.colors.textSecondary
                        )
                        
                        StatItem(
                            value: "\(averageWordCount)",
                            label: "Avg. Words",
                            icon: "text.word.spacing"
                        )
                    }
                }
                .padding(.bottom, styles.layout.spacingL)
                
                // Mood distribution
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Mood Distribution")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    if moodDistribution.isEmpty {
                        Text("No entries this week")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, styles.layout.paddingL)
                    } else {
                        ForEach(moodDistribution, id: \.mood) { item in
                            HStack(spacing: styles.layout.spacingM) {
                                // Mood icon and name
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(item.mood.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(item.mood.name)
                                        .font(styles.typography.bodyFont)
                                        .foregroundColor(styles.colors.text)
                                        .frame(width: 80, alignment: .leading)
                                }
                                
                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        Rectangle()
                                            .fill(styles.colors.tertiaryBackground)
                                            .cornerRadius(4)
                                        
                                        // Fill
                                        Rectangle()
                                            .fill(item.mood.color)
                                            .cornerRadius(4)
                                            .frame(width: calculateWidth(for: item.count, in: geometry))
                                    }
                                }
                                .frame(height: 12)
                                
                                // Count
                                Text("\(item.count)")
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .frame(width: 30, alignment: .trailing)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.bottom, styles.layout.spacingL)
                
                // Weekly mood chart
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Mood by Day of Week")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(weekdayMoodData, id: \.weekday) { dataPoint in
                                if dataPoint.mood > 0 {
                                    BarMark(
                                        x: .value("Weekday", dataPoint.weekday),
                                        y: .value("Mood", dataPoint.mood)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [styles.colors.accent, styles.colors.accent.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(4)
                                }
                            }
                        }
                        .chartYScale(domain: 0...5)
                        .chartYAxis {
                            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                                AxisValueLabel {
                                    switch value.index {
                                    case 0: Text("Sad").font(styles.typography.caption)
                                    case 1: Text("Anxious").font(styles.typography.caption)
                                    case 2: Text("Neutral").font(styles.typography.caption)
                                    case 3: Text("Happy").font(styles.typography.caption)
                                    case 4: Text("Excited").font(styles.typography.caption)
                                    default: Text("")
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                    } else {
                        // Fallback for iOS 15
                        Text("Weekly mood chart requires iOS 16 or later")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, styles.layout.spacingL)
                
                // Weekly insights
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Weekly Insights")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        ForEach(generateInsights(), id: \.self) { insight in
                            HStack(alignment: .top, spacing: styles.layout.spacingM) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(styles.colors.accent)
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                Text(insight)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                            }
                        }
                    }
                }
            }
            .padding(styles.layout.paddingXL)
        }
    }
    
    private func calculateWidth(for count: Int, in geometry: GeometryProxy) -> CGFloat {
        let maxCount = moodDistribution.map { $0.count }.max() ?? 1
        let percentage = CGFloat(count) / CGFloat(maxCount)
        return geometry.size.width * percentage
    }
    
    private func generateInsights() -> [String] {
        var insights: [String] = []
        
        if weeklyEntries.isEmpty {
            insights.append("No journal entries this week. Start journaling to see your weekly insights.")
            return insights
        }
        
        // Consistency insight
        if entryCount >= 5 {
            insights.append("You've been very consistent with your journaling this week, which is excellent for building a lasting habit.")
        } else if entryCount >= 3 {
            insights.append("You've journaled \(entryCount) times this week. Try to increase your consistency to see more patterns.")
        } else {
            insights.append("You've journaled \(entryCount) times this week. Aim for at least 3-4 entries per week to build a consistent habit.")
        }
        
        // Mood insight
        if let mood = dominantMood {
            switch mood {
            case .happy, .excited, .content, .relaxed, .calm:
                insights.append("Your dominant mood this week has been \(mood.name.lowercased()), which suggests you're experiencing positive emotions.")
            case .sad, .depressed, .anxious, .stressed:
                insights.append("You've been experiencing \(mood.name.lowercased()) feelings this week. Consider what might be contributing to this.")
            case .angry:
                insights.append("Anger has been a prominent emotion for you this week. Reflect on potential triggers and healthy ways to process this feeling.")
            case .bored:
                insights.append("You've mentioned feeling bored several times. Consider introducing new activities or challenges into your routine.")
            default:
                insights.append("Your mood has been mixed this week, with \(mood.name.lowercased()) being most common.")
            }
        }
        
        // Word count insight
        if averageWordCount > 100 {
            insights.append("Your entries are quite detailed (averaging \(averageWordCount) words), which provides rich material for reflection.")
        } else if averageWordCount > 50 {
            insights.append("Your entries average \(averageWordCount) words, providing a good balance of detail and conciseness.")
        } else {
            insights.append("Your entries are brief (averaging \(averageWordCount) words). Consider expanding on your thoughts for deeper insights.")
        }
        
        // Day of week insight
        let validMoodData = weekdayMoodData.filter { $0.mood > 0 }
        if let bestDay = validMoodData.max(by: { $0.mood < $1.mood }) {
            insights.append("Your mood tends to be highest on \(bestDay.weekday)s. Consider what makes this day special.")
        }
        
        if let worstDay = validMoodData.min(by: { $0.mood < $1.mood }) {
            insights.append("You typically feel less positive on \(worstDay.weekday)s. Reflect on what challenges you might face on this day.")
        }
        
        return insights
    }
}

