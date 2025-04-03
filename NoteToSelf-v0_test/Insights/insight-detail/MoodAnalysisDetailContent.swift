import SwiftUI
import Charts

// Renamed from MoodTrendsDetailContent
struct MoodAnalysisDetailContent: View {
    let entries: [JournalEntry] // Needs full entries list for charting & insights
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        ScrollView { // Wrap in ScrollView
            VStack(alignment: .leading, spacing: styles.layout.spacingXL) { // Increased spacing
                Text("Mood Analysis")
                    .font(styles.typography.title1) // Title for the detail view
                    .foregroundColor(styles.colors.text)
                    .padding(.bottom, styles.layout.paddingS)

                if #available(iOS 16.0, *) {
                    // Placeholder for Dual Axis Chart Section
                    VStack(alignment: .leading) {
                         Text("Mood Dimensions Over Time")
                             .font(styles.typography.title3)
                             .foregroundColor(styles.colors.text)
                             .padding(.bottom, styles.layout.spacingS)

                        Text("Chart Placeholder:\nPositive/Negative Axis & Awake/Quiet Axis")
                            .font(styles.typography.bodyLarge)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(height: 250) // Keep placeholder height
                            .frame(maxWidth: .infinity)
                            .background(styles.colors.secondaryBackground.opacity(0.5))
                            .cornerRadius(styles.layout.radiusM)
                            .padding(.vertical, styles.layout.paddingS)

                        Text("Use horizontal scrolling and pinch-to-zoom to explore different time scales (Day, Week, Month, Year).")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary)

                         // Actual Chart Implementation would go here
                         // DetailedMoodAnalysisChart(entries: entries)
                         //    .frame(height: 250) // Example height
                    }
                    .padding(.bottom, styles.layout.paddingL)


                } else {
                    Text("Detailed mood chart requires iOS 16 or later.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(height: 250) // Keep placeholder height
                        .frame(maxWidth: .infinity)
                }

                // Mood insights section (using the existing MoodInsightsView)
                 VStack(alignment: .leading) {
                      Text("Analysis & Insights")
                          .font(styles.typography.title3)
                          .foregroundColor(styles.colors.text)
                          .padding(.bottom, styles.layout.spacingM)

                      MoodInsightsView(entries: entries) // Reuse the insights component
                  }

                 Spacer() // Push content up if ScrollView allows

            }
            .padding(styles.layout.paddingL) // Add padding to the outer VStack
        }
    }
}

// Placeholder for the Dual Axis Chart component (Keep for future implementation)
@available(iOS 16.0, *)
struct DetailedMoodAnalysisChart: View {
    let entries: [JournalEntry]
    // TODO: Implement dual axis chart logic (Positive/Negative and Awake/Quiet)
    var body: some View {
        Text("Dual Axis Chart Implementation Pending")
    }
}


// MoodInsightsView (Keep as is - provides textual summary)
struct MoodInsightsView: View {
    let entries: [JournalEntry]
    @ObservedObject private var styles = UIStyles.shared

    private var moodCounts: [Mood: Int] {
        entries.reduce(into: [Mood: Int]()) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
    }

    private var topMoods: [(mood: Mood, count: Int)] {
        moodCounts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }

    private var moodTrend: String {
        let sortedEntries = entries.sorted { $0.date > $1.date }
        let recentEntries = sortedEntries.prefix(5)
        let oldEntries = sortedEntries.dropFirst(5).prefix(5)

        if recentEntries.isEmpty || oldEntries.isEmpty { return "Not enough data" }

         func moodValue(_ mood: Mood) -> Double {
             switch mood {
             case .happy: return 4; case .excited: return 5; case .neutral: return 3
             case .stressed: return 2; case .sad: return 1; case .alert: return 4.5
             case .content: return 4.2; case .relaxed: return 4.0; case .calm: return 3.8
             case .bored: return 2.5; case .depressed: return 1.0; case .anxious: return 1.8
             case .angry: return 1.5
             }
         }

        let recentAvg = recentEntries.map { moodValue($0.mood) }.reduce(0.0, +) / Double(recentEntries.count)
        let oldAvg = oldEntries.map { moodValue($0.mood) }.reduce(0.0, +) / Double(oldEntries.count)

        if recentAvg > oldAvg + 0.5 { return "Improving" }
        else if recentAvg < oldAvg - 0.5 { return "Declining" }
        else { return "Stable" }
    }


    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingL) { // Increased spacing
            // Top moods section
            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                Text("Your Top Moods")
                    .font(styles.typography.bodyLarge.weight(.semibold)) // Bolder label
                    .foregroundColor(styles.colors.text)

                HStack(spacing: styles.layout.spacingL) {
                    ForEach(topMoods, id: \.mood) { moodData in
                        VStack(spacing: 8) {
                            Image(systemName: moodData.mood.systemIconName)
                                .foregroundColor(moodData.mood.color)
                                .font(.system(size: 24))
                            Text(moodData.mood.name)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)
                            Text("\(moodData.count) entries")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                     ForEach(0..<(3 - topMoods.count), id: \.self) { _ in // Placeholders
                         VStack(spacing: 8) {
                             Image(systemName: "circle.dashed").foregroundColor(styles.colors.textSecondary).font(.system(size: 24))
                             Text("N/A").font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                             Text(" ").font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                         }.frame(maxWidth: .infinity)
                     }
                }
                .padding(.vertical, styles.layout.paddingS)
                 .padding(.horizontal)
                 .background(styles.colors.secondaryBackground.opacity(0.5))
                 .cornerRadius(styles.layout.radiusM)
            }


            // Mood trend section
            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                Text("Your Mood Trend")
                    .font(styles.typography.bodyLarge.weight(.semibold)) // Bolder label
                    .foregroundColor(styles.colors.text)

                HStack(spacing: styles.layout.spacingM) { // Increased spacing
                    Image(systemName: moodTrend == "Improving" ? "arrow.up.circle.fill" :
                                     moodTrend == "Declining" ? "arrow.down.circle.fill" : "equal.circle.fill")
                        .foregroundColor(moodTrend == "Improving" ? Mood.happy.color :
                                         moodTrend == "Declining" ? Mood.sad.color : Mood.neutral.color)
                        .font(.system(size: 36)) // Larger icon

                    VStack(alignment: .leading, spacing: 4) {
                        Text(moodTrend)
                            .font(styles.typography.title3) // Make trend text larger
                            .foregroundColor(styles.colors.text)

                        Text("Based on recent vs. earlier entries")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary)
                    }
                }
                 .padding() // Add padding
                 .background(styles.colors.secondaryBackground.opacity(0.5)) // Subtle background
                 .cornerRadius(styles.layout.radiusM)
            }
        }
    }
}


#Preview {
    // Create mock entries for preview
    let mockEntries = [
        JournalEntry(text: "Entry 1", mood: .happy, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        JournalEntry(text: "Entry 2", mood: .stressed, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        JournalEntry(text: "Entry 3", mood: .content, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!),
        JournalEntry(text: "Entry 4", mood: .sad, date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!),
        JournalEntry(text: "Entry 5", mood: .neutral, date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!)
    ]
    ScrollView{ // Wrap preview in ScrollView
        MoodAnalysisDetailContent(entries: mockEntries)
            .padding()
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
}
