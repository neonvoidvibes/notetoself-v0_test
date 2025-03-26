import SwiftUI

struct MonthlyStatsView: View {
    let month: Date
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    
    private var monthEntries: [JournalEntry] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        let startOfMonth = calendar.date(from: components)!
        
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let nextMonthComponents = calendar.dateComponents([.year, .month], from: nextMonth)
        let startOfNextMonth = calendar.date(from: nextMonthComponents)!
        
        return entries.filter { entry in
            entry.date >= startOfMonth && entry.date < startOfNextMonth
        }
    }
    
    private var entryCount: Int {
        return monthEntries.count
    }
    
    private var daysInMonth: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month)!
        return range.count
    }
    
    private var completionRate: Double {
        return Double(entryCount) / Double(daysInMonth)
    }
    
    private var dominantMood: Mood? {
        let moodCounts = monthEntries.reduce(into: [Mood: Int]()) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Monthly Stats")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: styles.layout.spacingXL) {
                StatItem(
                    value: "\(entryCount)",
                    label: "Entries",
                    icon: "doc.text.fill"
                )
                
                StatItem(
                    value: "\(Int(completionRate * 100))%",
                    label: "Completion",
                    icon: "chart.bar.fill"
                )
                
                if let mood = dominantMood {
                    StatItem(
                        value: mood.name,
                        label: "Top Mood",
                        icon: mood.systemIconName,
                        color: mood.color
                    )
                }
            }
        }
    }
}

