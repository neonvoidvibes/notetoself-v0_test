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
        Button(action: {
            isExpanded = true
        }) {
            styles.card(
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
                        .frame(height: 180)
                    } else {
                        // Fallback for iOS 15
                        Text("Weekly mood chart requires iOS 16 or later")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Insight text - brief for free users, more detailed for premium
                    Text(generateInsightText())
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(subscriptionTier == .premium ? nil : 2)
                    
                    if subscriptionTier == .free {
                        HStack {
                            Spacer()
                            
                            Text("Upgrade for detailed insights")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.accent)
                            
                            Image(systemName: "lock.fill")
                                .foregroundColor(styles.colors.accent)
                                .font(.system(size: 12))
                        }
                    }
                }
                .padding(styles.layout.paddingL)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isExpanded) {
            InsightDetailView(
                insight: InsightDetail(
                    type: .weeklyPatterns,
                    title: "Weekly Patterns",
                    data: weeklyEntries
                ),
                entries: entries
            )
        }
    }
    
    private func generateInsightText() -> String {
        guard !weeklyEntries.isEmpty else {
            return "No journal entries this week. Start journaling to see your weekly patterns."
        }
        
        // Find best and worst days
        let validMoodData = weekdayMoodData.filter { $0.mood > 0 }
        let bestDay = validMoodData.max(by: { $0.mood < $1.mood })
        let worstDay = validMoodData.min(by: { $0.mood < $1.mood })
        
        var insightText = ""
        
        if let bestDay = bestDay {
            insightText += "Your mood tends to be highest on \(bestDay.weekday)s. "
        }
        
        if let worstDay = worstDay {
            insightText += "You typically feel less positive on \(worstDay.weekday)s. "
        }
        
        // Add more detailed insights for premium users
        if subscriptionTier == .premium {
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
                    insightText += "Your mood has been improving throughout the week. "
                } else if isDownwardTrend {
                    insightText += "Your mood has been declining throughout the week. "
                }
            }
            
            // Add recommendations
            insightText += "Consider planning enjoyable activities for your lower mood days and reflecting on what makes your better days special."
        }
        
        return insightText
    }
}

