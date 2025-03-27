import SwiftUI

struct MoodDistributionDetailContent: View {
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    
    private var moodCounts: [Mood: Int] {
        entries.reduce(into: [Mood: Int]()) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
    }
    
    private var totalEntries: Int {
        entries.count
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingL) {
            // Mood distribution chart
            MoodDistributionChart(moodCounts: moodCounts, totalEntries: totalEntries)
                .padding(.vertical, styles.layout.paddingL)
            
            // Mood breakdown
            MoodBreakdownList(moodCounts: moodCounts, totalEntries: totalEntries)
                .padding(.vertical, styles.layout.paddingL)
        }
    }
}

struct MoodDistributionChart: View {
    let moodCounts: [Mood: Int]
    let totalEntries: Int
    private let styles = UIStyles.shared
    
    private var sortedMoods: [(mood: Mood, percentage: Double)] {
        moodCounts.map { mood, count in
            (mood, Double(count) / Double(totalEntries) * 100)
        }.sorted { $0.percentage > $1.percentage }
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Mood Distribution")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Pie chart representation
            ZStack {
                ForEach(0..<sortedMoods.count, id: \.self) { index in
                    let mood = sortedMoods[index].mood
                    let percentage = sortedMoods[index].percentage
                    let startAngle = index == 0 ? 0.0 : sortedMoods[0..<index].reduce(0) { $0 + $1.percentage } / 100 * 360
                    let endAngle = startAngle + percentage / 100 * 360
                    
                    PieSlice(
                        startAngle: Angle(degrees: startAngle),
                        endAngle: Angle(degrees: endAngle),
                        color: mood.color
                    )
                }
                
                // Center circle for empty space
                Circle()
                    .fill(styles.colors.appBackground)
                    .frame(width: 100, height: 100)
                
                // Total entries in center
                VStack {
                    Text("\(totalEntries)")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(styles.colors.text)
                    
                    Text("Entries")
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.textSecondary)
                }
            }
            .frame(height: 250)
            .padding(.vertical, styles.layout.paddingM)
        }
    }
}

struct MoodBreakdownList: View {
    let moodCounts: [Mood: Int]
    let totalEntries: Int
    private let styles = UIStyles.shared
    
    private var sortedMoods: [(mood: Mood, count: Int, percentage: Double)] {
        moodCounts.map { mood, count in
            (mood, count, Double(count) / Double(totalEntries) * 100)
        }.sorted { $0.percentage > $1.percentage }
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Mood Breakdown")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(sortedMoods, id: \.mood) { moodData in
                HStack(spacing: styles.layout.spacingM) {
                    // Mood icon
                    Image(systemName: moodData.mood.systemIconName)
                        .foregroundColor(moodData.mood.color)
                        .font(.system(size: 20))
                    
                    // Mood name
                    Text(moodData.mood.name)
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                    
                    // Percentage
                    Text(String(format: "%.1f%%", moodData.percentage))
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                    
                    // Count
                    Text("(\(moodData.count))")
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.textSecondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

