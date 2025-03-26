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
    
    var body: some View {
        Button(action: {
            isExpanded = true
        }) {
            styles.card(
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
                                .font(styles.typography.bodyFont)
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
                    
                    Text("You wrote \(entriesLastMonth.count) out of \(daysInLastMonth) days last month. Aim for consistency to build your journaling habit.")
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
                    type: .writingConsistency,
                    title: "Writing Consistency",
                    data: entries
                ),
                entries: entries
            )
        }
    }
}

