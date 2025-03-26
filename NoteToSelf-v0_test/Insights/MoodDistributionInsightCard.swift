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
            styles.card(
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
                    
                    Text("These are your most frequent moods. Understanding your emotional patterns can help you identify triggers and improve well-being.")
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, styles.layout.spacingS)
                }
                .padding(styles.layout.paddingL)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
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
}

