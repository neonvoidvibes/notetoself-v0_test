import SwiftUI
import Charts

struct WeeklyPatternsDetailContent: View {
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
    
    private var timeOfDayMoodData: [(timeOfDay: String, mood: Double)] {
        let timeSlots = ["Morning", "Afternoon", "Evening", "Night"]
        var result: [(timeOfDay: String, mood: Double)] = []
        
        // Group entries by time of day
        var entriesByTimeSlot: [Int: [JournalEntry]] = [:]
        
        for entry in weeklyEntries {
            let hour = Calendar.current.component(.hour, from: entry.date)
            let timeSlot: Int
            
            if hour >= 5 && hour < 12 {
                timeSlot = 0 // Morning
            } else if hour >= 12 && hour < 17 {
                timeSlot = 1 // Afternoon
            } else if hour >= 17 && hour < 22 {
                timeSlot = 2 // Evening
            } else {
                timeSlot = 3 // Night
            }
            
            if entriesByTimeSlot[timeSlot] == nil {
                entriesByTimeSlot[timeSlot] = []
            }
            entriesByTimeSlot[timeSlot]?.append(entry)
        }
        
        // Calculate average mood value for each time slot
        for timeSlotIndex in 0..<4 {
            let entries = entriesByTimeSlot[timeSlotIndex] ?? []
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
            
            result.append((timeOfDay: timeSlots[timeSlotIndex], mood: moodValue))
        }
        
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: styles.layout.spacingXL) {
                // Mood by day of week
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
                    
                    // Day of week insights
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Insights")
                            .font(styles.typography.bodyLarge)
                            .foregroundColor(styles.colors.text)
                        
                        ForEach(generateDayOfWeekInsights(), id: \.self) { insight in
                            HStack(alignment: .top, spacing: styles.layout.spacingM) {
                                Image(systemName: "calendar.day.timeline.left")
                                    .foregroundColor(styles.colors.accent)
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                Text(insight)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                            }
                        }
                    }
                    .padding(.top, styles.layout.spacingM)
                }
                .padding(.bottom, styles.layout.spacingL)
                
                // Mood by time of day
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Mood by Time of Day")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(timeOfDayMoodData, id: \.timeOfDay) { dataPoint in
                                if dataPoint.mood > 0 {
                                    BarMark(
                                        x: .value("Time of Day", dataPoint.timeOfDay),
                                        y: .value("Mood", dataPoint.mood)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [styles.colors.moodHappy, styles.colors.moodHappy.opacity(0.7)],
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
                        Text("Time of day chart requires iOS 16 or later")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Time of day insights
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Insights")
                            .font(styles.typography.bodyLarge)
                            .foregroundColor(styles.colors.text)
                        
                        ForEach(generateTimeOfDayInsights(), id: \.self) { insight in
                            HStack(alignment: .top, spacing: styles.layout.spacingM) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(styles.colors.accent)
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                Text(insight)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                            }
                        }
                    }
                    .padding(.top, styles.layout.spacingM)
                }
                .padding(.bottom, styles.layout.spacingL)
                
                // Pattern recommendations
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Recommendations")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    ForEach(generateRecommendations(), id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: styles.layout.spacingM) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(styles.colors.accent)
                                .font(.system(size: 16))
                                .frame(width: 24)
                            
                            Text(recommendation)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                        }
                    }
                }
            }
            .padding(styles.layout.paddingXL)
        }
    }
    
    private func generateDayOfWeekInsights() -> [String] {
        var insights: [String] = []
        
        if weeklyEntries.isEmpty {
            insights.append("No journal entries this week. Start journaling to see patterns by day of week.")
            return insights
        }
        
        let validMoodData = weekdayMoodData.filter { $0.mood > 0 }
        
        if let bestDay = validMoodData.max(by: { $0.mood < $1.mood }) {
            insights.append("Your mood tends to be highest on \(bestDay.weekday)s (average mood: \(String(format: "%.1f", bestDay.mood)) out of 5).")
        }
        
        if let worstDay = validMoodData.min(by: { $0.mood < $1.mood }) {
            insights.append("You typically feel less positive on \(worstDay.weekday)s (average mood: \(String(format: "%.1f", worstDay.mood)) out of 5).")
        }
        
        // Check for patterns
        let weekdayValues = weekdayMoodData.map { $0.mood }
        let weekdayIndices = weekdayMoodData.indices.filter { weekdayMoodData[$0].mood > 0 }
        
        if weekdayIndices.count >= 3 {
            // Check for upward trend
            var isUpwardTrend = true
            for i in 1..<weekdayIndices.count {
                if weekdayValues[weekdayIndices[i]] <= weekdayValues[weekdayIndices[i-1]] {
                    isUpwardTrend = false
                    break
                }
            }
            
            // Check for downward trend
            var isDownwardTrend = true
            for i in 1..<weekdayIndices.count {
                if weekdayValues[weekdayIndices[i]] >= weekdayValues[weekdayIndices[i-1]] {
                    isDownwardTrend = false
                    break
                }
            }
            
            if isUpwardTrend {
                insights.append("Your mood has been improving throughout the week, which suggests a positive trajectory.")
            } else if isDownwardTrend {
                insights.append("Your mood has been declining throughout the week. Consider what factors might be contributing to this pattern.")
            }
        }
        
        // Check for weekend vs. weekday pattern
        let weekdayMoods = weekdayMoodData.filter { $0.mood > 0 && ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"].contains($0.weekday) }
        let weekendMoods = weekdayMoodData.filter { $0.mood > 0 && ["Saturday", "Sunday"].contains($0.weekday) }
        
        if !weekdayMoods.isEmpty && !weekendMoods.isEmpty {
            let avgWeekdayMood = weekdayMoods.reduce(0.0) { $0 + $1.mood } / Double(weekdayMoods.count)
            let avgWeekendMood = weekendMoods.reduce(0.0) { $0 + $1.mood } / Double(weekendMoods.count)
            
            if avgWeekendMood > avgWeekdayMood + 0  { $0 + $1.mood } / Double(weekendMoods.count)
            
            if avgWeekendMood > avgWeekdayMood + 0.5 {
                insights.append("Your mood is significantly better on weekends compared to weekdays. Consider how you might bring more weekend-like activities into your weekdays.")
            } else if avgWeekdayMood > avgWeekendMood + 0.5 {
                insights.append("Interestingly, your mood is better during weekdays than on weekends. Reflect on what aspects of your work or routine might be contributing positively.")
            }
        }
        
        return insights
    }
    
    private func generateTimeOfDayInsights() -> [String] {
        var insights: [String] = []
        
        if weeklyEntries.isEmpty {
            insights.append("No journal entries this week. Start journaling at different times of day to see time-based patterns.")
            return insights
        }
        
        let validTimeData = timeOfDayMoodData.filter { $0.mood > 0 }
        
        if let bestTime = validTimeData.max(by: { $0.mood < $1.mood }) {
            insights.append("Your mood tends to be highest during the \(bestTime.timeOfDay.lowercased()) (average mood: \(String(format: "%.1f", bestTime.mood)) out of 5).")
        }
        
        if let worstTime = validTimeData.min(by: { $0.mood < $1.mood }) {
            insights.append("You typically feel less positive during the \(worstTime.timeOfDay.lowercased()) (average mood: \(String(format: "%.1f", worstTime.mood)) out of 5).")
        }
        
        // Check for morning vs. evening pattern
        let morningMoods = timeOfDayMoodData.filter { $0.mood > 0 && ["Morning"].contains($0.timeOfDay) }
        let eveningMoods = timeOfDayMoodData.filter { $0.mood > 0 && ["Evening", "Night"].contains($0.timeOfDay) }
        
        if !morningMoods.isEmpty && !eveningMoods.isEmpty {
            let avgMorningMood = morningMoods.reduce(0.0) { $0 + $1.mood } / Double(morningMoods.count)
            let avgEveningMood = eveningMoods.reduce(0.0) { $0 + $1.mood } / Double(eveningMoods.count)
            
            if avgMorningMood > avgEveningMood + 0.5 {
                insights.append("You tend to be more positive in the morning than in the evening. Consider scheduling important activities earlier in the day when your mood is better.")
            } else if avgEveningMood > avgMorningMood + 0.5 {
                insights.append("Your mood improves as the day progresses, with evenings being your most positive time. You might be a 'night person' who functions better later in the day.")
            }
        }
        
        return insights
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if weeklyEntries.isEmpty {
            recommendations.append("Start journaling regularly to receive personalized recommendations based on your patterns.")
            return recommendations
        }
        
        // Day of week recommendations
        let validMoodData = weekdayMoodData.filter { $0.mood > 0 }
        if let worstDay = validMoodData.min(by: { $0.mood < $1.mood }) {
            recommendations.append("Plan enjoyable activities or self-care for \(worstDay.weekday)s to help improve your typically lower mood on this day.")
        }
        
        // Time of day recommendations
        let validTimeData = timeOfDayMoodData.filter { $0.mood > 0 }
        if let bestTime = validTimeData.max(by: { $0.mood < $1.mood }) {
            recommendations.append("Schedule important tasks or decisions during the \(bestTime.timeOfDay.lowercased()) when your mood is typically at its best.")
        }
        
        if let worstTime = validTimeData.min(by: { $0.mood < $1.mood }) {
            recommendations.append("Create a specific self-care routine for the \(worstTime.timeOfDay.lowercased()) to help elevate your mood during this challenging time of day.")
        }
        
        // General pattern recommendations
        recommendations.append("Notice what activities, people, or environments are present during your highest mood times and try to incorporate more of these elements into your routine.")
        
        recommendations.append("Consider tracking additional factors like sleep, exercise, or social interaction alongside your mood to identify more specific patterns and triggers.")
        
        return recommendations
    }
}

