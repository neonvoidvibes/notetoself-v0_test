import SwiftUI
import Charts // Import Charts for the mood trend chart

struct FeelDetailContent: View {
    let result: FeelInsightResult
    let generatedDate: Date?
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: styles.layout.spacingXL) {

                // --- Mood Trend Chart Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("7-Day Mood Trend")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)

                    if let trendData = result.moodTrendChartData, !trendData.isEmpty {
                        if #available(iOS 16.0, *) {
                             Chart(trendData) { point in
                                 LineMark(
                                     x: .value("Date", point.date),
                                     y: .value("Mood", point.moodValue)
                                 )
                                 .foregroundStyle(styles.colors.accent) // Use accent for the line

                                 // Add points for peaks/dips with labels
                                 if !point.label.isEmpty {
                                     PointMark(
                                         x: .value("Date", point.date),
                                         y: .value("Mood", point.moodValue)
                                     )
                                     .foregroundStyle(styles.colors.accent)
                                     .annotation(position: .top, alignment: .center) {
                                         Text(point.label)
                                             .font(styles.typography.caption)
                                             .foregroundColor(styles.colors.textSecondary)
                                             .padding(4)
                                             .background(styles.colors.secondaryBackground.opacity(0.7))
                                             .cornerRadius(4)
                                     }
                                 }
                             }
                             .chartYScale(domain: 1...5) // Set Y-axis scale (1=Low, 5=High)
                             .chartXAxis {
                                 AxisMarks(values: .stride(by: .day)) { _ in
                                     // Optionally customize X-axis appearance if needed
                                     AxisGridLine()
                                     AxisTick()
                                      // AxisValueLabel(format: .dateTime.weekday(.narrow)) // Example: Narrow weekday labels
                                 }
                             }
                             .frame(height: 200)
                        } else {
                            Text("Chart requires iOS 16+").font(styles.typography.bodySmall).foregroundColor(styles.colors.textSecondary)
                        }
                    } else {
                        Text("Mood trend data not available.")
                            .font(styles.typography.bodySmall)
                            .foregroundColor(styles.colors.textSecondary)
                             .frame(height: 200) // Keep placeholder height
                             .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
                .background(styles.colors.secondaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)

                // --- Mood Snapshot Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Mood Snapshot")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)

                    Text(result.moodSnapshotText ?? "Emotional snapshot not available. Keep journaling!")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(styles.colors.secondaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)

                Spacer(minLength: styles.layout.spacingXL)

                // Generated Date Timestamp
                if let date = generatedDate {
                    HStack {
                        Spacer()
                        Image(systemName: "clock")
                            .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                            .font(.system(size: 12))
                        Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .padding(.bottom, styles.layout.paddingL)
        }
    }
}

#Preview {
    // Mock data for preview
    let mockPoints: [MoodTrendPoint] = [
        .init(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, moodValue: 3.0, label: ""),
        .init(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, moodValue: 4.0, label: "Upward shift"),
        .init(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, moodValue: 3.5, label: ""),
        .init(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, moodValue: 2.0, label: "Feeling heavy"),
        .init(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, moodValue: 2.5, label: ""),
        .init(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, moodValue: 4.2, label: "Lighter"),
        .init(date: Date(), moodValue: 3.8, label: "")
    ]
    let mockResult = FeelInsightResult(
        moodTrendChartData: mockPoints,
        moodSnapshotText: "Preview: Your emotional energy seemed to ebb and flow this week, like tides rising and falling. There were moments of buoyancy followed by periods where things felt heavier."
    )

    return InsightFullScreenView(title: "Feel Insights") {
        FeelDetailContent(result: mockResult, generatedDate: Date())
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
}