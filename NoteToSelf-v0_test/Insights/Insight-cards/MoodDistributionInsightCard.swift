import SwiftUI

struct MoodDistributionInsightCard: View {
    let entries: [JournalEntry]
    @State private var isExpanded: Bool = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    private var moodCounts: [Mood: Int] {
        entries.reduce(into: [Mood: Int]()) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
    }
    
    private var topMoods: [(mood: Mood, count: Int)] {
        moodCounts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }
    
    var body: some View {
        Button(action: {
            isExpanded = true
        }) {
            styles.enhancedCard(
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Mood Distribution")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                    
                    Spacer()
                    
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(styles.colors.accent)
                        .font(.system(size: styles.layout.iconSizeL))
                }
                
                // Top moods
                HStack(spacing: styles.layout.spacingL) {
                    ForEach(topMoods, id: \.mood) { moodData in
                        VStack(spacing: 8) {
                            Image(systemName: moodData.mood.systemIconName)
                                .foregroundColor(moodData.mood.color)
                                .font(.system(size: 24))
                            
                            Text(moodData.mood.name)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)
                            
                            Text("\(moodData.count)")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // More conversational insight text
                Text(generateDistributionInsight())
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, styles.layout.spacingS)
                    .lineLimit(2)
            }
            .padding(styles.layout.cardInnerPadding)
        )
    }
    .buttonStyle(PlainButtonStyle())
    .sheet(isPresented: $isExpanded) {
        InsightDetailView(
            insight: InsightDetail(
                type: .moodDistribution,
                title: "Mood Distribution",
                data: entries
            ),
            entries: entries
        )
    }
}

// Add this method to generate more personalized distribution insights
private func generateDistributionInsight() -> String {
    if topMoods.isEmpty {
        return "Start journaling to track your emotional patterns over time."
    }
    
    if let topMood = topMoods.first {
        let percentage = Float(topMood.count) / Float(entries.count) * 100
        let formattedPercentage = Int(percentage)
        
        switch topMood.mood {
        case .happy, .excited, .content, .relaxed, .calm:
            return "You feel \(topMood.mood.name.lowercased()) about \(formattedPercentage)% of the time. This positive outlook can help build resilience."
        case .sad, .depressed:
            return "You've recorded feeling \(topMood.mood.name.lowercased()) frequently. Consider what patterns might be contributing to this."
        case .anxious, .stressed:
            return "Stress appears in \(formattedPercentage)% of your entries. Identifying triggers can help manage these feelings."
        default:
            return "Your most common mood is \(topMood.mood.name.lowercased()). Understanding your patterns helps build emotional awareness."
        }
    } else {
        return "Your emotional landscape is diverse. This awareness helps you understand yourself better."
    }
}
}

