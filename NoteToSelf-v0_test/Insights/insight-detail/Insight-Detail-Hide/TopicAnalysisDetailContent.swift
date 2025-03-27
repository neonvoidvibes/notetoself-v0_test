import SwiftUI

struct TopicAnalysisDetailContent: View {
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    
    // Simulated topics for demonstration
    private let topics = [
        ("Work", 42),
        ("Relationships", 35),
        ("Health", 28),
        ("Hobbies", 22),
        ("Family", 18),
        ("Travel", 15),
        ("Finance", 12),
        ("Education", 10)
    ]
    
    var body: some View {
        VStack(spacing: styles.layout.spacingL) {
            // Topic cloud
            TopicCloudView(topics: topics)
                .padding(.vertical, styles.layout.paddingL)
            
            // Topic trends
            TopicTrendsView(topics: topics)
                .padding(.vertical, styles.layout.paddingL)
        }
    }
}

struct TopicCloudView: View {
    let topics: [(String, Int)]
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Topic Cloud")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Simple topic cloud layout
            FlowLayout(spacing: 10) {
                ForEach(topics, id: \.0) { topic in
                    Text(topic.0)
                        .font(.system(size: calculateFontSize(for: topic.1), weight: .medium, design: .monospaced))
                        .foregroundColor(styles.colors.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(styles.colors.tertiaryBackground)
                        .cornerRadius(styles.layout.radiusM)
                }
            }
            .padding(.vertical, styles.layout.paddingM)
        }
    }
    
    private func calculateFontSize(for count: Int) -> CGFloat {
        let maxCount = topics.map { $0.1 }.max() ?? 1
        let minSize: CGFloat = 12
        let maxSize: CGFloat = 20
        let percentage = CGFloat(count) / CGFloat(maxCount)
        return minSize + percentage * (maxSize - minSize)
    }
}

struct TopicTrendsView: View {
    let topics: [(String, Int)]
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Topic Trends")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(topics.prefix(5), id: \.0) { topic in
                HStack(spacing: styles.layout.spacingM) {
                    // Topic name
                    Text(topic.0)
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.text)
                        .frame(width: 120, alignment: .leading)
                    
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
                                .frame(width: calculateWidth(for: topic.1, in: geometry))
                        }
                    }
                    .frame(height: 12)
                    
                    // Count
                    Text("\(topic.1)")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func calculateWidth(for count: Int, in geometry: GeometryProxy) -> CGFloat {
        let maxCount = topics.map { $0.1 }.max() ?? 1
        let percentage = CGFloat(count) / CGFloat(maxCount)
        return geometry.size.width * percentage
    }
}

