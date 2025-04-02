import SwiftUI

struct SentimentAnalysisDetailContent: View {
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    
    // Simulated sentiment data for demonstration
    private let sentimentData = [
        ("Jan", 0.2),
        ("Feb", 0.4),
        ("Mar", 0.1),
        ("Apr", -0.3),
        ("May", -0.5),
        ("Jun", 0.0),
        ("Jul", 0.6),
        ("Aug", 0.7)
    ]
    
    var body: some View {
        VStack(spacing: styles.layout.spacingL) {
            // Sentiment chart
            SentimentChartView(sentimentData: sentimentData)
                .padding(.vertical, styles.layout.paddingL)
            
            // Sentiment insights
            SentimentInsightsView(sentimentData: sentimentData)
                .padding(.vertical, styles.layout.paddingL)
        }
    }
}

struct SentimentChartView: View {
    let sentimentData: [(String, Double)]
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Sentiment Over Time")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(sentimentData, id: \.0) { data in
                    VStack(spacing: 8) {
                        // Bar
                        Rectangle()
                            .fill(data.1 >= 0 ? Mood.happy.color : Mood.sad.color) // Use Mood enum colors
                            .frame(width: 24, height: abs(CGFloat(data.1) * 150))

                        // Month label
                        Text(data.0)
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary)
                    }
                }
            }
            .frame(height: 200, alignment: .center)
            .padding(.vertical, styles.layout.paddingM)
            
            // Legend
            HStack(spacing: styles.layout.spacingL) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Mood.happy.color) // Use Mood enum color
                        .frame(width: 16, height: 16)

                    Text("Positive")
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.text)
                }

                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Mood.sad.color) // Use Mood enum color
                        .frame(width: 16, height: 16)

                    Text("Negative")
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.text)
                }
            }
        }
    }
}

struct SentimentInsightsView: View {
    let sentimentData: [(String, Double)]
    private let styles = UIStyles.shared
    
    private var averageSentiment: Double {
        let sum = sentimentData.reduce(0.0) { $0 + $1.1 }
        return sum / Double(sentimentData.count)
    }
    
    private var sentimentTrend: String {
        let firstHalf = sentimentData.prefix(sentimentData.count / 2)
        let secondHalf = sentimentData.suffix(sentimentData.count / 2)
        
        let firstAvg = firstHalf.reduce(0.0) { $0 + $1.1 } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0.0) { $0 + $1.1 } / Double(secondHalf.count)
        
        if secondAvg > firstAvg + 0.1 {
            return "Improving"
        } else if secondAvg < firstAvg - 0.1 {
            return "Declining"
        } else {
            return "Stable"
        }
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Sentiment Insights")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: styles.layout.spacingXL) {
                StatItem(
                    value: String(format: "%.2f", averageSentiment),
                    label: "Average Sentiment",
                    icon: "chart.bar.fill"
                )
                
                StatItem(
                    value: sentimentTrend,
                    label: "Trend",
                    icon: sentimentTrend == "Improving" ? "arrow.up.circle.fill" : 
                           sentimentTrend == "Declining" ? "arrow.down.circle.fill" : "arrow.right.circle.fill",
                    color: sentimentTrend == "Improving" ? Mood.happy.color : // Use Mood enum colors
                           sentimentTrend == "Declining" ? Mood.sad.color : Mood.neutral.color // Use Mood enum colors
                )
            }

            // Sentiment analysis
            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                Text("What This Means")
                    .font(styles.typography.bodyLarge)
                    .foregroundColor(styles.colors.text)
                
                Text("Your overall sentiment is \(averageSentiment > 0.2 ? "positive" : averageSentiment < -0.2 ? "negative" : "neutral") and has been \(sentimentTrend.lowercased()) over time. This analysis helps you understand your emotional patterns in your journal entries.")
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, styles.layout.paddingM)
        }
    }
}