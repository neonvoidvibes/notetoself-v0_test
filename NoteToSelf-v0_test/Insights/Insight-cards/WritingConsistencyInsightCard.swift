import SwiftUI

struct WritingConsistencyInsightCard: View {
    let entries: [JournalEntry]
    @State private var isExpanded: Bool = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    private var lastMonth: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    }
    
    private var daysInLastMonth: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: lastMonth)!
        return range.count
    }
    
    private var entriesLastMonth: [JournalEntry] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: lastMonth)
        let year = components.year!
        let month = components.month!
        
        return entries.filter { entry in
            let entryComponents = calendar.dateComponents([.year, .month], from: entry.date)
            return entryComponents.year == year && entryComponents.month == month
        }
    }
    
    private var completionRate: Double {
        Double(entriesLastMonth.count) / Double(daysInLastMonth)
    }
    
    // Update the WritingConsistencyInsightCard to use the enhanced card style and improved content
    var body: some View {
        Button(action: {
            isExpanded = true
        }) {
            styles.enhancedCard(
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Writing Consistency")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                    
                    Spacer()
                    
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(styles.colors.accent)
                        .font(.system(size: styles.layout.iconSizeL))
                }
                
                // Consistency bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Last Month")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                        
                        Text("\(Int(completionRate * 100))%")
                            .font(styles.typography.insightValue)
                            .foregroundColor(styles.colors.accent)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(styles.colors.tertiaryBackground)
                                .cornerRadius(styles.layout.radiusM)
                            
                            // Fill
                            Rectangle()
                                .fill(styles.colors.accent)
                                .cornerRadius(styles.layout.radiusM)
                                .frame(width: geometry.size.width * CGFloat(completionRate))
                        }
                    }
                    .frame(height: 12)
                }
                
                // More conversational and focused insight text
                Text(generateConsistencyInsight())
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
                type: .writingConsistency,
                title: "Writing Consistency",
                data: entries
            ),
            entries: entries
        )
    }
}

// Add this method to generate more personalized consistency insights
private func generateConsistencyInsight() -> String {
    let percentage = Int(completionRate * 100)
    
    if entriesLastMonth.isEmpty {
        return "Start your journaling habit this month to track your consistency."
    }
    
    if percentage < 30 {
        return "You journaled \(entriesLastMonth.count) days last month. Even occasional entries provide valuable insights."
    } else if percentage < 60 {
        return "You wrote on \(entriesLastMonth.count) of \(daysInLastMonth) days. Your growing consistency helps build self-awareness."
    } else if percentage < 90 {
        return "Great consistency! You journaled \(percentage)% of days last month, building a strong reflection habit."
    } else {
        return "Exceptional dedication! You journaled almost every day last month. This consistency reveals deeper patterns."
    }
}
}

