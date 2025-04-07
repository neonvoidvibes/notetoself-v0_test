import SwiftUI
import Charts

// MARK: - Mini Charts Data Point Definitions

// Define the missing data point struct for the weekly bar chart
struct WeeklyBarChartDataPoint: Identifiable {
    let id = UUID() // Make it identifiable
    let day: String    // e.g., "Mon", "Tue"
    let value: Double // e.g., Mood score, entry count
}

// Reuse MoodTrendPoint for sparkline if appropriate, or define a simpler one if needed.
// Assuming MoodTrendPoint from Models.swift is suitable for the sparkline.
// If MoodTrendPoint is not available, uncomment and adapt the definition below:
/*
 struct SparklineDataPoint: Identifiable {
     let id = UUID()
     let date: Date // Or perhaps just an index/position
     let value: Double
 }
*/


// MARK: - Mini Sparkline Chart View (for Feel Card)

@available(iOS 16.0, *)
struct MiniSparklineChart: View {
    let data: [MoodTrendPoint] // Assuming MoodTrendPoint is the correct type
    let gradient: LinearGradient

    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        Chart(data) { point in
            // Main line
            LineMark(
                x: .value("Date", point.date), // Assuming MoodTrendPoint has 'date'
                y: .value("Value", point.moodValue) // Assuming MoodTrendPoint has 'moodValue'
            )
            .foregroundStyle(gradient) // Apply gradient to the line
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.5)) // Make line slightly thicker

            // Optional: Area Mark for subtle fill
            AreaMark(
                x: .value("Date", point.date),
                yStart: .value("Min", data.map { $0.moodValue }.min() ?? 1), // Adjust based on expected scale
                yEnd: .value("Value", point.moodValue)
            )
            .foregroundStyle(gradient.opacity(0.2)) // Very subtle fill
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 50) // Compact height for card
        .padding(.vertical, 5) // Minimal vertical padding
    }
}

// MARK: - Mini Weekly Bar Chart View (for WeekInReview Card)

@available(iOS 16.0, *)
struct MiniWeeklyBarChart: View {
    // Use the newly defined struct
    let data: [WeeklyBarChartDataPoint]
    let color: Color

    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Day", point.day), // Use 'day' property
                y: .value("Value", point.value) // Use 'value' property
            )
            .foregroundStyle(color.opacity(0.8)) // Slightly transparent bars
            .cornerRadius(3) // Soften corners
        }
        .chartXAxis {
            // Simplify the AxisMarks and AxisValueLabel
            AxisMarks(preset: .aligned, values: data.map { $0.day }) { value in // Use day strings as values
                 AxisValueLabel() { // Use default label
                     // Attempt to cast the axis value to String (which it should be)
                     if let dayString = value.as(String.self) {
                         Text(dayString)
                             .font(.system(size: 8)) // Smaller font for labels
                             .foregroundStyle(styles.colors.textSecondary)
                     }
                 }
                 // Optional: Add Ticks or GridLines if desired
                 // AxisTick()
            }
        }
        .chartYAxis(.hidden) // Hide Y axis for mini chart
        .frame(height: 50) // Compact height
        .padding(.vertical, 5) // Minimal vertical padding
    }
}


// MARK: - Mini Activity Dots View (for Journey Card)

struct MiniActivityDots: View {
    let habitData: [Bool] // Array of bools for the last 7 days

    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        HStack(spacing: 6) { // Adjust spacing as needed
            ForEach(0..<7) { index in
                Circle()
                    // Use accent color if true, secondary background if false
                    .fill(habitData[index] ? styles.colors.accent : styles.colors.secondaryBackground)
                    .frame(width: 10, height: 10) // Small dots
                    .overlay(
                        // Optional: Add a subtle border
                        Circle().stroke(styles.colors.divider.opacity(0.3), lineWidth: 0.5)
                    )
            }
        }
        .frame(height: 15) // Define a height for the container
        .padding(.vertical, 5)
    }
}


// MARK: - Previews

#Preview {
    VStack(spacing: 30) {
        if #available(iOS 16.0, *) {
            // Mock data for Sparkline
            let sparklinePoints: [MoodTrendPoint] = [
                .init(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, moodValue: 3.0, label: ""),
                .init(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, moodValue: 4.0, label: ""),
                .init(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, moodValue: 3.5, label: ""),
                .init(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, moodValue: 2.0, label: ""),
                .init(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, moodValue: 2.5, label: ""),
                .init(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, moodValue: 4.2, label: ""),
                .init(date: Date(), moodValue: 3.8, label: "")
            ]
            MiniSparklineChart(
                data: sparklinePoints,
                gradient: LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
            )
            .padding()
            .background(Color.black.opacity(0.8))

            // Mock data for Bar Chart
            let barPoints: [WeeklyBarChartDataPoint] = [
                .init(day: "Mon", value: 3),
                .init(day: "Tue", value: 4),
                .init(day: "Wed", value: 2),
                .init(day: "Thu", value: 5),
                .init(day: "Fri", value: 4),
                .init(day: "Sat", value: 3),
                .init(day: "Sun", value: 4)
            ]
            MiniWeeklyBarChart(data: barPoints, color: .orange)
                .padding()
                .background(Color.black.opacity(0.8))
        } else {
            Text("Charts require iOS 16+")
        }

        // Mock data for Activity Dots
        MiniActivityDots(habitData: [true, false, true, true, false, false, true])
            .padding()
            .background(Color.black.opacity(0.8))
    }
    .padding()
    .background(Color.gray.opacity(0.2))
    .environmentObject(UIStyles.shared) // Provide UIStyles
    .environmentObject(ThemeManager.shared) // Provide ThemeManager
}