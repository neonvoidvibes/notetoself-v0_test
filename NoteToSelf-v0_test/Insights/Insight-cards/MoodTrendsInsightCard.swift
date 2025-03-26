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
    
    var body: some View {
        Button(action: {
            isExpanded = true
        }) {
            styles.card(
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
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 2)) { value in
                                AxisValueLabel {
                                    if let date = value.as(Date.self) {
                                        Text(formatDate(date))
                                            .font(styles.typography.caption)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                    } else {
                        // Fallback for iOS 15
                        Text("Mood chart requires iOS 16 or later")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Text("Track your mood patterns over time to identify trends and triggers.")
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, styles.layout.spacingS)
                }
                .padding(styles.layout.paddingL)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

