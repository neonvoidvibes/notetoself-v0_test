import SwiftUI
import Charts

struct WeeklyInsightCard: View {
    let entries: [JournalEntry]
    @State private var isExpanded: Bool = false
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
        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
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
    
    private var subscriptionTier: SubscriptionTier {
        // Access app state to get subscription tier
        // For now, we'll assume it's available via environment object
        return .premium // Default to premium for demo
    }
    
    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Weekly Patterns")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                        
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: styles.layout.iconSizeL))
                    }
                    
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
                        .frame(height: 160)
                    } else {
                        // Fallback for iOS 15
                        Text("Weekly mood chart requires iOS 16 or later")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Insight text - brief for free users, more detailed for premium
                    Text(generateInsightText())
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(subscriptionTier == .premium ? 3 : 2)
                }
            },
            detailContent: {
                // Expanded detail content
                VStack(spacing: styles.layout.spacingL) {
                    Divider()
                        .background(styles.colors.tertiaryBackground)
                        .padding(.vertical, 8)
                    
                    // Weekly mood analysis
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Weekly Mood Analysis")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Text(generateDetailedWeeklyAnalysis())
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Day-by-day breakdown
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Day-by-Day Breakdown")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        ForEach(weekdayMoodData.filter { $0.mood > 0 }, id: \.weekday) { dataPoint in
                            HStack {
                                Text(dataPoint.weekday)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.text)
                                    .frame(width: 50, alignment: .leading)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        Rectangle()
                                            .fill(styles.colors.tertiaryBackground)
                                            .cornerRadius(styles.layout.radiusM)
                                        
                                        // Fill
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [styles.colors.accent, styles.colors.accent.opacity(0.7)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .cornerRadius(styles.layout.radiusM)
                                            .frame(width: geometry.size.width * CGFloat(dataPoint.mood / 5.0))
                                        
                                        // Label
                                        Text(moodValueToText(dataPoint.mood))
                                            .font(styles.typography.caption)
                                            .foregroundColor(styles.colors.text)
                                            .padding(.leading, 8)
                                    }
                                }
                                .frame(height: 24)
                            }
                        }
                    }
                    
                    // Recommendations based on patterns
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Recommendations")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        ForEach(generateRecommendations(), id: \.self) { recommendation in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(styles.colors.accent)
                                    .font(.system(size: 16))
                                
                                Text(recommendation)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        )
    }
    
    // Helper methods for expanded content
    private func moodValueToText(_ value: Double) -> String {
        if value >= 4.5 {
            return "Excited"
        } else if value >= 3.5 {
            return "Happy"
        } else if value >= 2.5 {
            return "Neutral"
        } else if value >= 1.5 {
            return "Stressed"
        } else {
            return "Sad"
        }
    }
    
    private func generateDetailedWeeklyAnalysis() -> String {
        let validData = weekdayMoodData.filter { $0.mood > 0 }
        if validData.count < 2 {
            return "Not enough data yet to analyze weekly patterns. Continue journaling throughout the week to reveal day-to-day mood variations."
        }
        
        // Find best and worst days
        let bestDay = validData.max(by: { $0.mood < $1.mood })
        let worstDay = validData.min(by: { $0.mood < $1.mood })
        
        var analysis = ""
        
        if let bestDay = bestDay, let worstDay = worstDay, bestDay.weekday != worstDay.weekday {
            analysis += "Your mood tends to be highest on \(bestDay.weekday)s (\(moodValueToText(bestDay.mood))) and lowest on \(worstDay.weekday)s (\(moodValueToText(worstDay.mood))). "
            
            // Add possible explanations
            if bestDay.weekday == "Sat" || bestDay.weekday == "Sun" {
                analysis += "Weekend days often bring more freedom and less work-related stress, which might explain your higher mood. "
            } else if worstDay.weekday == "Mon" {
                analysis += "The beginning of the work week can often bring transition stress as you shift from weekend activities. "
            } else if worstDay.weekday == "Thu" || worstDay.weekday == "Fri" {
                analysis += "End-of-week fatigue might be contributing to your lower mood on \(worstDay.weekday)s. "
            }
        } else if validData.count >= 3 {
            // Check for trends across the week
            let firstHalfAvg = validData.prefix(3).reduce(0.0) { $0 + $1.mood } / Double(min(3, validData.count))
            let secondHalfAvg = validData.suffix(min(3, validData.count)).reduce(0.0) { $0 + $1.mood } / Double(min(3, validData.count))
            
            if firstHalfAvg > secondHalfAvg + 0.5 {
                analysis += "Your mood tends to start higher early in the week and gradually decrease. This might reflect increasing fatigue or stress as the week progresses. "
            } else if secondHalfAvg > firstHalfAvg + 0.5 {
                analysis += "Your mood tends to improve as the week progresses, perhaps as you look forward to weekend activities or complete work tasks. "
            } else {
                analysis += "Your mood remains relatively stable throughout the week, without dramatic shifts between weekdays. "
            }
        }
        
        // Add general insight
        if analysis.isEmpty {
            analysis = "Your weekly mood pattern is still emerging. Continue journaling to reveal more detailed insights about how different days of the week affect your well-being."
        } else {
            analysis += "Understanding these patterns can help you plan activities and self-care strategically throughout your week."
        }
        
        return analysis
    }
    
    private func generateRecommendations() -> [String] {
        let validData = weekdayMoodData.filter { $0.mood > 0 }
        if validData.count < 2 {
            return ["Continue journaling throughout the week to receive personalized recommendations based on your patterns."]
        }
        
        var recommendations: [String] = []
        
        // Find best and worst days
        if let bestDay = validData.max(by: { $0.mood < $1.mood }),
           let worstDay = validData.min(by: { $0.mood < $1.mood }),
           bestDay.weekday != worstDay.weekday {
            
            recommendations.append("Consider scheduling challenging tasks or meetings on \(bestDay.weekday)s when your mood tends to be higher.")
            recommendations.append("Plan extra self-care or enjoyable activities on \(worstDay.weekday)s to help balance your typically lower mood.")
        }
        
        // Check for weekend vs. weekday patterns
        let weekendDays = validData.filter { $0.weekday == "Sat" || $0.weekday == "Sun" }
        let weekdayDays = validData.filter { $0.weekday != "Sat" && $0.weekday != "Sun" }
        
        if !weekendDays.isEmpty && !weekdayDays.isEmpty {
            let weekendAvg = weekendDays.reduce(0.0) { $0 + $1.mood } / Double(weekendDays.count)
            let weekdayAvg = weekdayDays.reduce(0.0) { $0 + $1.mood } / Double(weekdayDays.count)
            
            if weekendAvg > weekdayAvg + 0.5 {
                recommendations.append("Try incorporating elements of your weekend activities into your weekdays to help maintain a more consistent mood.")
            } else if weekdayAvg > weekendAvg + 0.5 {
                recommendations.append("Consider whether your weekend activities are truly restorative. You might benefit from more structure or meaningful engagement during free time.")
            }
        }
        
        // Add general recommendations
        if recommendations.isEmpty {
            recommendations = [
                "Maintain awareness of how different days affect your mood and energy levels.",
                "Consider tracking specific activities alongside your mood to identify what most positively impacts your well-being.",
                "Experiment with different routines on different days of the week to see what works best for you."
            ]
        }
        
        return recommendations
    }
    
    private func generateInsightText() -> String {
        guard !weeklyEntries.isEmpty else {
            return "Add entries throughout the week to discover your day-to-day patterns."
        }
        
        // Find best and worst days
        let validMoodData = weekdayMoodData.filter { $0.mood > 0 }
        let bestDay = validMoodData.max(by: { $0.mood < $1.mood })
        let worstDay = validMoodData.min(by: { $0.mood < $1.mood })
        
        var insightText = ""
        
        if let bestDay = bestDay, let worstDay = worstDay, bestDay.weekday != worstDay.weekday {
            insightText = "\(bestDay.weekday)s tend to be your best days, while \(worstDay.weekday)s are typically more challenging."
        } else if let bestDay = bestDay {
            insightText = "Your mood is often highest on \(bestDay.weekday)s. What makes these days special?"
        } else if let worstDay = worstDay {
            insightText = "You typically feel less positive on \(worstDay.weekday)s. Consider what factors might be affecting you."
        }
        
        // Add more detailed insights for premium users
        if subscriptionTier == .premium && !insightText.isEmpty {
            insightText += " Planning activities based on these patterns can help optimize your well-being."
        }
        
        return insightText.isEmpty ? "Your weekly patterns will become clearer as you add more entries." : insightText
    }
}

