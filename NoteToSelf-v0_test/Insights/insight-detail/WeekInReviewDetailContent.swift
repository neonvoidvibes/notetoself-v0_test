import SwiftUI
import Charts // For mood trend chart

struct WeekInReviewDetailContent: View {
    let result: WeekInReviewResult
    let generatedDate: Date?
    @ObservedObject private var styles = UIStyles.shared

    // Format the date range string from the result
    private var summaryPeriod: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // e.g., "Oct 20"
        guard let start = result.startDate, let end = result.endDate else {
            return "Week Period N/A"
        }
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: styles.layout.spacingXL) {

                // Date Range Header
                Text(summaryPeriod)
                    .font(styles.typography.title3)
                    .foregroundColor(styles.colors.text)
                    .frame(maxWidth: .infinity, alignment: .center) // Center align date range
                    .padding(.bottom, styles.layout.spacingS) // Space below date

                // --- Weekly Summary Section ---
                styledSection(title: "Weekly Summary") { // Title uses accent via helper
                    Text(result.summaryText ?? "Weekly summary not available.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(styles.layout.spacingXS)
                }

                // --- Key Themes Section ---
                if let themes = result.keyThemes, !themes.isEmpty {
                    styledSection(title: "Key Themes") { // Title uses accent via helper
                         FlowLayout(spacing: 10) { // VERIFIED FlowLayout usage
                             ForEach(themes, id: \.self) { theme in
                                 Text(theme)
                                     .font(styles.typography.bodySmall)
                                     .padding(.horizontal, 12)
                                     .padding(.vertical, 8)
                                     .background(styles.colors.secondaryBackground)
                                     .cornerRadius(styles.layout.radiusM)
                                     .foregroundColor(styles.colors.text)
                             }
                         }
                    }
                }

                // --- Mood Trend Section ---
                styledSection(title: "Mood Trend") { // Title uses accent via helper
                     if let trendData = result.moodTrendChartData, !trendData.isEmpty {
                         if #available(iOS 16.0, *) {
                             moodTrendChart(data: trendData) // VERIFIED Chart usage
                         } else {
                             Text("Chart requires iOS 16+").font(styles.typography.bodySmall).foregroundColor(styles.colors.textSecondary)
                                 .frame(height: 200, alignment: .center)
                         }
                     } else {
                         Text("Mood trend data not available.")
                             .font(styles.typography.bodySmall)
                             .foregroundColor(styles.colors.textSecondary)
                              .frame(height: 200)
                              .frame(maxWidth: .infinity, alignment: .center)
                     }
                }

                // --- Recurring Themes (Think) Section ---
                 styledSection(title: "Recurring Themes & Values") { // Title uses accent via helper
                      Text(result.recurringThemesText ?? "Recurring themes analysis not available.")
                          .font(styles.typography.bodyFont)
                          .foregroundColor(styles.colors.textSecondary)
                          .frame(maxWidth: .infinity, alignment: .leading)
                          .lineSpacing(styles.layout.spacingXS)
                 }

                // --- Action Highlights (Act) Section ---
                 styledSection(title: "Action Highlights") { // Title uses accent via helper
                      Text(result.actionHighlightsText ?? "Action highlights not available.")
                          .font(styles.typography.bodyFont)
                          .foregroundColor(styles.colors.textSecondary)
                          .frame(maxWidth: .infinity, alignment: .leading)
                          .lineSpacing(styles.layout.spacingXS)
                 }

                // --- Takeaway (Learn) Section ---
                 styledSection(title: "Key Takeaway") { // Title uses accent via helper
                      Text(result.takeawayText ?? "Weekly takeaway not available.")
                          .font(styles.typography.bodyFont)
                          .foregroundColor(styles.colors.textSecondary)
                          .frame(maxWidth: .infinity, alignment: .leading)
                          .lineSpacing(styles.layout.spacingXS)
                 }


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

    // Helper ViewBuilder for consistent section styling
    @ViewBuilder
    private func styledSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text(title)
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.accent) // VERIFIED Accent color for sub-headers
            content() // The actual content for the section
        }
        .padding()
        .background(styles.colors.secondaryBackground.opacity(0.5))
        .cornerRadius(styles.layout.radiusM)
    }

    // Chart Builder Function (Copied from FeelDetailContent, could be refactored)
     @available(iOS 16.0, *)
     private func moodTrendChart(data: [MoodTrendPoint]) -> some View {
          Chart(data) { point in
              LineMark(
                  x: .value("Date", point.date, unit: .day),
                  y: .value("Mood", point.moodValue)
              )
              .foregroundStyle(styles.colors.accent)
              .interpolationMethod(.catmullRom)
              .lineStyle(StrokeStyle(lineWidth: 2))

               AreaMark(
                  x: .value("Date", point.date, unit: .day),
                  yStart: .value("MinMood", 1),
                  yEnd: .value("Mood", point.moodValue)
               )
               .foregroundStyle(
                   LinearGradient(
                       gradient: Gradient(colors: [styles.colors.accent.opacity(0.3), styles.colors.accent.opacity(0.0)]),
                       startPoint: .top,
                       endPoint: .bottom
                   )
               )
               .interpolationMethod(.catmullRom)

              if !point.label.isEmpty {
                  PointMark(
                      x: .value("Date", point.date, unit: .day),
                      y: .value("Mood", point.moodValue)
                  )
                  .symbolSize(40)
                  .foregroundStyle(styles.colors.accent)
                  .annotation(position: .top, alignment: .center, spacing: 6) {
                      Text(point.label)
                          .font(styles.typography.caption)
                          .foregroundColor(styles.colors.text)
                          .padding(.horizontal, 6)
                          .padding(.vertical, 3)
                          .background(styles.colors.secondaryBackground.opacity(0.85))
                          .clipShape(Capsule())
                  }
              }
          }
          .chartYScale(domain: 1...5)
          .chartXAxis {
              AxisMarks(values: .stride(by: .day)) { value in
                  AxisGridLine(centered: true, stroke: StrokeStyle(dash: [2, 3]))
                  AxisTick(centered: true, stroke: StrokeStyle(lineWidth: 1))
                      .foregroundStyle(styles.colors.textSecondary.opacity(0.5))
                  AxisValueLabel {
                       if let dateValue = value.as(Date.self) {
                           Text(dateValue.formatted(.dateTime.weekday(.abbreviated)))
                               .font(styles.typography.caption)
                               .foregroundColor(styles.colors.textSecondary)
                       }
                   }
              }
          }
           .chartYAxis {
               AxisMarks(position: .leading, values: [1, 3, 5]) { value in
                   AxisGridLine(stroke: StrokeStyle(dash: [2, 3]))
                    AxisValueLabel() {
                         if let intValue = value.as(Int.self) {
                             switch intValue {
                             case 1: Text("Low")
                             case 3: Text("Mid")
                             case 5: Text("High")
                             default: Text("")
                             }
                         }
                     }
                     .font(styles.typography.caption)
                     .foregroundStyle(styles.colors.textSecondary)
               }
           }
          .frame(height: 200)
      }
}

#Preview {
     let mockPoints: [MoodTrendPoint] = [
         .init(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, moodValue: 3.0, label: ""),
         .init(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, moodValue: 4.0, label: "Upward shift"),
         .init(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, moodValue: 3.5, label: ""),
         .init(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, moodValue: 2.0, label: "Feeling heavy"),
         .init(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, moodValue: 2.5, label: ""),
         .init(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, moodValue: 4.2, label: "Lighter"),
         .init(date: Date(), moodValue: 3.8, label: "")
     ]
    let mockResult = WeekInReviewResult(
        startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
        endDate: Date(),
        summaryText: "Preview: A week focused on project completion, with some social time on the weekend. Mood remained fairly stable despite some deadline pressure.",
        keyThemes: ["Project Alpha", "Friend Gathering", "Deadline Stress"],
        moodTrendChartData: mockPoints,
        recurringThemesText: "Preview: Balancing work demands and personal time continued to be a prominent theme.",
        actionHighlightsText: "Preview: Successfully completing Project Alpha was a key action. Taking a walk during lunch breaks helped manage stress.",
        takeawayText: "Preview: Proactive planning, even for small breaks, significantly impacts focus and mood."
    )

    return InsightFullScreenView(title: "Week in Review") {
        WeekInReviewDetailContent(result: mockResult, generatedDate: Date())
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
}