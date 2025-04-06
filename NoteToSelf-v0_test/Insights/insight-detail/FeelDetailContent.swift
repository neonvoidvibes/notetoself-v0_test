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
                moodTrendChartSection // Call helper view

                // --- Mood Snapshot Section ---
                moodSnapshotSection // Call helper view

                Spacer(minLength: styles.layout.spacingXL)

                // Generated Date Timestamp
                generatedDateView // Call helper view
            }
            .padding(.bottom, styles.layout.paddingL)
        }
    }

    // MARK: - Helper Views

    // Extracted Mood Trend Chart Section
    private var moodTrendChartSection: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            // Use accent color for sub-header
            Text("7-Day Mood Trend")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.accent) // Accent color for sub-header

            if let trendData = result.moodTrendChartData, !trendData.isEmpty {
                if #available(iOS 16.0, *) {
                    moodTrendChart(data: trendData) // Call chart builder
                } else {
                    Text("Chart requires iOS 16+").font(styles.typography.bodySmall).foregroundColor(styles.colors.textSecondary)
                        .frame(height: 200, alignment: .center)
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
    }

    // Extracted Mood Snapshot Section
    private var moodSnapshotSection: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            // Use accent color for sub-header
            Text("Mood Snapshot")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.accent) // Accent color for sub-header

            Text(result.moodSnapshotText ?? "Emotional snapshot not available. Keep journaling!")
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(styles.layout.spacingXS) // Add line spacing
        }
        .padding()
        .background(styles.colors.secondaryBackground.opacity(0.5))
        .cornerRadius(styles.layout.radiusM)
    }

    // Extracted Generated Date View
    @ViewBuilder
    private var generatedDateView: some View {
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


    // MARK: - Chart Builder Function (iOS 16+)
    @available(iOS 16.0, *)
    private func moodTrendChart(data: [MoodTrendPoint]) -> some View {
         Chart(data) { point in
             // Line Mark
             LineMark(
                 x: .value("Date", point.date, unit: .day), // Use .day unit
                 y: .value("Mood", point.moodValue)
             )
             .foregroundStyle(styles.colors.accent) // Use accent for the line
             .interpolationMethod(.catmullRom) // Smoother line
             .lineStyle(StrokeStyle(lineWidth: 2))

             // Area Mark (Subtle gradient fill below line)
              AreaMark(
                 x: .value("Date", point.date, unit: .day),
                 yStart: .value("MinMood", 1), // Assuming 1 is the bottom of your scale
                 yEnd: .value("Mood", point.moodValue)
              )
              .foregroundStyle(
                  LinearGradient(
                      gradient: Gradient(colors: [styles.colors.accent.opacity(0.3), styles.colors.accent.opacity(0.0)]),
                      startPoint: .top,
                      endPoint: .bottom
                  )
              )
              .interpolationMethod(.catmullRom) // Match line interpolation


             // Point Marks with Annotations for labeled peaks/dips
             if !point.label.isEmpty {
                 PointMark(
                     x: .value("Date", point.date, unit: .day),
                     y: .value("Mood", point.moodValue)
                 )
                 .symbolSize(40) // Slightly larger points for labels
                 .foregroundStyle(styles.colors.accent)
                 .annotation(position: .top, alignment: .center, spacing: 6) { // Add spacing
                     Text(point.label)
                         .font(styles.typography.caption)
                         .foregroundColor(styles.colors.text) // Use standard text color
                         .padding(.horizontal, 6)
                         .padding(.vertical, 3)
                         .background(styles.colors.secondaryBackground.opacity(0.85)) // Slightly less opaque
                         .clipShape(Capsule()) // Use Capsule shape
                 }
             }
         }
         .chartYScale(domain: 1...5) // Set Y-axis scale (1=Low, 5=High)
         // Corrected X Axis Configuration
         .chartXAxis {
             AxisMarks(values: .stride(by: .day)) { value in // Pass values directly to AxisMarks
                 AxisGridLine(centered: true, stroke: StrokeStyle(dash: [2, 3]))
                 AxisTick(centered: true, stroke: StrokeStyle(lineWidth: 1))
                     .foregroundStyle(styles.colors.textSecondary.opacity(0.5))
                 // Use AxisValueLabel with trailing closure to format the Date value
                 AxisValueLabel {
                     // Safely cast value.as to Date? and format it within a Text view
                     if let dateValue = value.as(Date.self) {
                         Text(dateValue.formatted(.dateTime.weekday(.abbreviated)))
                             .font(styles.typography.caption)
                             .foregroundColor(styles.colors.textSecondary)
                     }
                 }
             }
         }
         // Corrected Y Axis Configuration (similar logic if needed, this looks okay)
          .chartYAxis {
              AxisMarks(position: .leading, values: [1, 3, 5]) { value in
                  AxisGridLine(stroke: StrokeStyle(dash: [2, 3]))
                   AxisValueLabel() { // Use default label
                        if let intValue = value.as(Int.self) {
                            switch intValue {
                            case 1: Text("Low")
                            case 3: Text("Mid")
                            case 5: Text("High")
                            default: Text("")
                            }
                        }
                    }
                    .font(styles.typography.caption) // Apply modifiers after label creation
                    .foregroundStyle(styles.colors.textSecondary)
              }
          }
         .frame(height: 200)
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