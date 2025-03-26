import SwiftUI

struct WordCountDetailContent: View {
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    
    private var totalWords: Int {
        entries.reduce(0) { $0 + $1.text.split(separator: " ").count }
    }
    
    private var averageWordsPerEntry: Double {
        if entries.isEmpty {
            return 0
        }
        return Double(totalWords) / Double(entries.count)
    }
    
    private var entriesByMonth: [(month: String, count: Int, words: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        var monthData: [String: (count: Int, words: Int)] = [:]
        
        for entry in entries {
            let monthStr = formatter.string(from: entry.date)
            let wordCount = entry.text.split(separator: " ").count
            
            if let existing = monthData[monthStr] {
                monthData[monthStr] = (existing.count + 1, existing.words + wordCount)
            } else {
                monthData[monthStr] = (1, wordCount)
            }
        }
        
        return monthData.map { (month: $0.key, count: $0.value.count, words: $0.value.words) }
            .sorted { formatter.date(from: $0.month)! < formatter.date(from: $1.month)! }
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingL) {
            // Word count stats
            WordCountStatsView(totalWords: totalWords, averageWords: averageWordsPerEntry)
                .padding(.vertical, styles.layout.paddingL)
            
            // Monthly word count
            MonthlyWordCountView(monthlyData: entriesByMonth)
                .padding(.vertical, styles.layout.paddingL)
        }
    }
}

struct WordCountStatsView: View {
    let totalWords: Int
    let averageWords: Double
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Word Count Stats")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: styles.layout.spacingXL) {
                StatItem(
                    value: "\(totalWords)",
                    label: "Total Words",
                    icon: "text.word.count"
                )
                
                StatItem(
                    value: String(format: "%.1f", averageWords),
                    label: "Avg per Entry",
                    icon: "chart.bar.fill"
                )
            }
        }
    }
}

struct MonthlyWordCountView: View {
    let monthlyData: [(month: String, count: Int, words: Int)]
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Monthly Word Count")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(monthlyData, id: \.month) { data in
                HStack(spacing: styles.layout.spacingM) {
                    // Month
                    Text(data.month)
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.text)
                        .frame(width: 100, alignment: .leading)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(styles.colors.tertiaryBackground)
                                .cornerRadius(4)
                            
                            // Fill
                            Rectangle()
                                .fill(styles.colors.accent)
                                .cornerRadius(4)
                                .frame(width: calculateWidth(for: data.words, in: geometry))
                        }
                    }
                    .frame(height: 12)
                    
                    // Word count
                    Text("\(data.words)")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func calculateWidth(for words: Int, in geometry: GeometryProxy) -> CGFloat {
        let maxWords = monthlyData.map { $0.words }.max() ?? 1
        let percentage = CGFloat(words) / CGFloat(maxWords)
        return geometry.size.width * percentage
    }
}

