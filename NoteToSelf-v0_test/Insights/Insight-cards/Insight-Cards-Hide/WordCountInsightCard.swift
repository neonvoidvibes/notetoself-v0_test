import SwiftUI

struct WordCountInsightCard: View {
    let entries: [JournalEntry]
    @State private var isExpanded: Bool = false

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    private var totalWords: Int {
        entries.reduce(0) { $0 + $1.text.split(separator: " ").count }
    }
    
    private var averageWordsPerEntry: Double {
        if entries.isEmpty {
            return 0
        }
        return Double(totalWords) / Double(entries.count)
    }
    
    var body: some View {
        Button(action: {
            isExpanded = true
        }) {
            styles.card(
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Word Count")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                        
                        Image(systemName: "text.word.count")
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: styles.layout.iconSizeL))
                    }
                    
                    // Word count stats
                    HStack(spacing: styles.layout.spacingXL) {
                        VStack(spacing: 8) {
                            Text("\(totalWords)")
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(styles.colors.text)
                            
                            Text("Total Words")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                        }
                        
                        VStack(spacing: 8) {
                            Text(String(format: "%.1f", averageWordsPerEntry))
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(styles.colors.text)
                            
                            Text("Avg per Entry")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                        }
                    }
                    
                    Text("Track your writing volume over time. More detailed entries often lead to better self-reflection and insights.")
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
                    type: .wordCount,
                    title: "Word Count",
                    data: entries
                ),
                entries: entries
            )
        }
    }
}
