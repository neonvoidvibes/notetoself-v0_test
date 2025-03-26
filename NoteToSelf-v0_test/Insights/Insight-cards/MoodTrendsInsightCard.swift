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
    
    // Update the MoodTrendsInsightCard to use the enhanced card style and improved content
    var body: some View {
        Button(action: {
            isExpanded = true
        }) {
            styles.enhancedCard(
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Mood Trends")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                        
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: styles.layout.iconSizeL))
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
                .padding(styles.layout.cardInnerPadding)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isExpanded) {
            InsightDetailView(
                insight: InsightDetail(
                    type: .moodTrends,
                    title: "Mood Trends",
                    data: entries
                ),
                entries: entries
            )
        }
    }
    
    // Add this method to generate more personalized trend insights
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

