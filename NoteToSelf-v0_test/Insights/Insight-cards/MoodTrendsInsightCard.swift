import SwiftUI
import Charts

struct MoodTrendsInsightCard: View {
    let entries: [JournalEntry]
    @State private var isExpanded: Bool = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    private var lastTwoWeeksEntries: [JournalEntry] {
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date())!
        
        return entries
            .filter { $0.date >= twoWeeksAgo }
            .sorted { $0.date < $1.date }
    }
    
    private var moodData: [MoodDataPoint] {
        let calendar = Calendar.current
        var result: [MoodDataPoint] = []
        
        // Create a dictionary to group entries by day
        var entriesByDay: [Date: JournalEntry] = [:]
        
        for entry in lastTwoWeeksEntries {
            let day = calendar.startOfDay(for: entry.date)
            entriesByDay[day] = entry
        }
        
        // Fill in the last 14 days
        for dayOffset in (0..<14).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: Date()))!
            let entry = entriesByDay[date]
            
            let moodValue: Double
            if let entry = entry {
                switch entry.mood {
                case .happy: moodValue = 4
                case .excited: moodValue = 5
                case .neutral: moodValue = 3
                case .stressed: moodValue = 2
                case .sad: moodValue = 1
                default: moodValue = 3 // Default to neutral for other moods
                }
            } else {
                moodValue = 0 // No entry for this day
            }
            
            result.append(MoodDataPoint(date: date, value: moodValue))
        }
        
        return result
    }
    
    // Update the MoodTrendsInsightCard to use the expandable card system
    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Mood Trends")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                    }
                    
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(moodData, id: \.date) { dataPoint in
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
                            AxisMarks(values: [1, 3, 5]) { value in
                                AxisValueLabel {
                                    switch value.index {
                                    case 0: Text("Low").font(styles.typography.caption)
                                    case 1: Text("Neutral").font(styles.typography.caption)
                                    case 2: Text("High").font(styles.typography.caption)
                                    default: Text("")
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 4)) { value in
                                AxisValueLabel {
                                    if let date = value.as(Date.self) {
                                        Text(formatDate(date))
                                            .font(styles.typography.caption)
                                    }
                                }
                            }
                        }
                        .frame(height: 180)
                    } else {
                        // Fallback for iOS 15
                        Text("Mood chart requires iOS 16 or later")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // More conversational and focused insight text
                    Text(generateTrendInsight())
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
                    Divider()
                        .background(styles.colors.tertiaryBackground)
                        .padding(.vertical, 8)
                    
                    // Mood breakdown
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Mood Breakdown")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        HStack(spacing: styles.layout.spacingL) {
                            MoodStatItem(
                                title: "Highest",
                                value: highestMoodDay(),
                                icon: "arrow.up.circle.fill",
                                color: .green
                            )
                            
                            MoodStatItem(
                                title: "Lowest",
                                value: lowestMoodDay(),
                                icon: "arrow.down.circle.fill",
                                color: .red
                            )
                            
                            MoodStatItem(
                                title: "Average",
                                value: averageMoodText(),
                                icon: "equal.circle.fill",
                                color: styles.colors.accent
                            )
                        }
                    }
                    
                    // Mood patterns
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Patterns & Insights")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Text(detailedMoodAnalysis())
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Mood triggers
                    if let triggers = identifyPossibleTriggers() {
                        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                            Text("Possible Mood Triggers")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)
                            
                            Text(triggers)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        )
    }
    
    // Helper methods for expanded content
    private func highestMoodDay() -> String {
        let validPoints = moodData.filter { $0.value > 0 }
        if let highest = validPoints.max(by: { $0.value < $1.value }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return formatter.string(from: highest.date)
        }
        return "N/A"
    }
    
    private func lowestMoodDay() -> String {
        let validPoints = moodData.filter { $0.value > 0 }
        if let lowest = validPoints.min(by: { $0.value < $1.value }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return formatter.string(from: lowest.date)
        }
        return "N/A"
    }
    
    private func averageMoodText() -> String {
        let validPoints = moodData.filter { $0.value > 0 }
        if validPoints.isEmpty {
            return "N/A"
        }
        
        let sum = validPoints.reduce(0) { $0 + $1.value }
        let avg = sum / Double(validPoints.count)
        
        if avg >= 4.5 {
            return "Excited"
        } else if avg >= 3.5 {
            return "Happy"
        } else if avg >= 2.5 {
            return "Neutral"
        } else if avg >= 1.5 {
            return "Stressed"
        } else {
            return "Sad"
        }
    }
    
    private func detailedMoodAnalysis() -> String {
        let validPoints = moodData.filter { $0.value > 0 }
        if validPoints.count < 3 {
            return "Add more entries to see a detailed analysis of your mood patterns. With more data, we can identify trends and potential triggers."
        }
        
        // Check for trends
        var isUpward = true
        var isDownward = true
        var isStable = true
        
        for i in 1..<validPoints.count {
            if validPoints[i].value <= validPoints[i-1].value {
                isUpward = false
            }
            if validPoints[i].value >= validPoints[i-1].value {
                isDownward = false
            }
            if abs(validPoints[i].value - validPoints[i-1].value) > 1 {
                isStable = false
            }
        }
        
        if isUpward {
            return "Your mood has been steadily improving over the past two weeks. This positive trend suggests that recent changes in your life or environment may be having a beneficial effect on your well-being."
        } else if isDownward {
            return "Your mood has been gradually declining over the past two weeks. This might indicate increasing stress or challenges. Consider what factors might be contributing to this trend and whether there are steps you can take to address them."
        } else if isStable {
            return "Your mood has been remarkably stable over the past two weeks, with minimal fluctuations. This emotional consistency can provide a solid foundation for well-being and productivity."
        } else {
            // Look for patterns
            let weekdayMoods = analyzeWeekdayPatterns()
            if weekdayMoods.hasPattern {
                return weekdayMoods.description
            } else {
                return "Your mood has varied naturally over the past two weeks without a clear pattern. This is completely normal and reflects the natural ebbs and flows of daily life and emotional experience."
            }
        }
    }
    
    private func analyzeWeekdayPatterns() -> (hasPattern: Bool, description: String) {
        let calendar = Calendar.current
        var weekdayMoods: [Int: [Double]] = [:]
        
        // Group mood values by weekday
        for point in moodData where point.value > 0 {
            let weekday = calendar.component(.weekday, from: point.date)
            if weekdayMoods[weekday] == nil {
                weekdayMoods[weekday] = []
            }
            weekdayMoods[weekday]?.append(point.value)
        }
        
        // Calculate average mood for each weekday
        var weekdayAverages: [Int: Double] = [:]
        for (weekday, moods) in weekdayMoods where moods.count > 0 {
            let sum = moods.reduce(0, +)
            weekdayAverages[weekday] = sum / Double(moods.count)
        }
        
        // Find highest and lowest weekdays
        if let highest = weekdayAverages.max(by: { $0.value < $1.value }),
           let lowest = weekdayAverages.min(by: { $0.value < $1.value }),
           highest.key != lowest.key,
           abs(highest.value - lowest.value) >= 1.0 {
            
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEEE"
            
            let highestDate = nextWeekday(weekday: highest.key)
            let lowestDate = nextWeekday(weekday: lowest.key)
            
            let highestDay = weekdayFormatter.string(from: highestDate)
            let lowestDay = weekdayFormatter.string(from: lowestDate)
            
            return (true, "Your mood tends to be highest on \(highestDay)s and lowest on \(lowestDay)s. This pattern might reflect your weekly schedule, work demands, or social activities. Understanding these patterns can help you plan activities and self-care strategically.")
        }
        
        return (false, "")
    }
    
    private func nextWeekday(weekday: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today)
        
        let daysToAdd = (weekday - todayWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd, to: today)!
    }
    
    private func identifyPossibleTriggers() -> String? {
        let validPoints = moodData.filter { $0.value > 0 }
        if validPoints.count < 5 {
            return nil
        }
        
        // Look for significant drops in mood
        var significantDrops: [(from: MoodDataPoint, to: MoodDataPoint)] = []
        
        for i in 0..<validPoints.count-1 {
            if validPoints[i+1].value <= validPoints[i].value - 2.0 {
                significantDrops.append((from: validPoints[i], to: validPoints[i+1]))
            }
        }
        
        if !significantDrops.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            
            let dropDate = formatter.string(from: significantDrops[0].to.date)
            return "There was a significant mood drop on \(dropDate). Reflecting on what happened around this time might help identify potential triggers. Common triggers include work stress, sleep changes, social conflicts, or health issues."
        }
        
        // Check for weekend vs. weekday patterns
        let calendar = Calendar.current
        var weekdayMoods: [Double] = []
        var weekendMoods: [Double] = []
        
        for point in validPoints where point.value > 0 {
            let weekday = calendar.component(.weekday, from: point.date)
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                weekendMoods.append(point.value)
            } else {
                weekdayMoods.append(point.value)
            }
        }
        
        if !weekdayMoods.isEmpty && !weekendMoods.isEmpty {
            let weekdayAvg = weekdayMoods.reduce(0, +) / Double(weekdayMoods.count)
            let weekendAvg = weekendMoods.reduce(0, +) / Double(weekendMoods.count)
            
            if abs(weekendAvg - weekdayAvg) >= 1.0 {
                if weekendAvg > weekdayAvg {
                    return "Your mood tends to be higher on weekends compared to weekdays. This might suggest work-related stress or that you benefit from the freedom and social connections of weekend activities."
                } else {
                    return "Your mood tends to be lower on weekends compared to weekdays. This could indicate that you thrive on structure, or possibly that weekends involve different social dynamics or activities that affect your mood."
                }
            }
        }
        
        return nil
    }
    
    // Generate trend insight for preview
    private func generateTrendInsight() -> String {
        let validPoints = moodData.filter { $0.value > 0 }
        
        if validPoints.count < 3 {
            return "Add more entries to reveal your mood patterns over time."
        }
        
        // Check for upward trend
        var isUpward = true
        var isDownward = true
        var isStable = true
        
        for i in 1..<validPoints.count {
            if validPoints[i].value <= validPoints[i-1].value {
                isUpward = false
            }
            if validPoints[i].value >= validPoints[i-1].value {
                isDownward = false
            }
            if abs(validPoints[i].value - validPoints[i-1].value) > 1 {
                isStable = false
            }
        }
        
        if isUpward {
            return "Your mood has been improving recently. What positive changes have you made?"
        } else if isDownward {
            return "Your mood has been trending downward. Consider what factors might be affecting you."
        } else if isStable {
            return "Your mood has been relatively stable. This consistency can help you feel grounded."
        } else {
            // Calculate average mood
            let sum = validPoints.reduce(0) { $0 + $1.value }
            let avg = sum / Double(validPoints.count)
            
            if avg > 3.5 {
                return "Your overall mood has been positive, with some natural variations."
            } else if avg < 2.5 {
                return "Your overall mood has been lower recently. Self-care might be helpful."
            } else {
                return "Your mood has varied naturally around a balanced center."
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// Helper view for mood stats in expanded view
struct MoodStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(styles.typography.caption)
                .foregroundColor(styles.colors.textSecondary)
            
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 24))
            
            Text(value)
                .font(styles.typography.bodyLarge)
                .foregroundColor(styles.colors.text)
        }
        .frame(maxWidth: .infinity)
    }
}

