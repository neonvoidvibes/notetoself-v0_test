import SwiftUI

struct WritingConsistencyDetailContent: View {
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingL) {
            // Consistency calendar
            ConsistencyCalendarView(entries: entries)
                .padding(.vertical, styles.layout.paddingL)
            
            // Consistency stats
            ConsistencyStatsView(entries: entries)
                .padding(.vertical, styles.layout.paddingL)
        }
    }
}

struct ConsistencyCalendarView: View {
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    
    private var lastSixMonths: [Date] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<6).map { monthOffset in
            calendar.date(byAdding: .month, value: -monthOffset, to: now)!
        }.reversed()
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Writing Consistency")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: styles.layout.spacingM) {
                ForEach(lastSixMonths, id: \.self) { month in
                    MonthConsistencyRow(month: month, entries: entries)
                }
            }
        }
    }
}

struct MonthConsistencyRow: View {
    let month: Date
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: month)
    }
    
    private var daysInMonth: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month)!
        return range.count
    }
    
    private var entryDays: Set<Int> {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        let year = components.year!
        let month = components.month!
        
        return Set(entries.filter { entry in
            let entryComponents = calendar.dateComponents([.year, .month, .day], from: entry.date)
            return entryComponents.year == year && entryComponents.month == month
        }.map { entry in
            calendar.component(.day, from: entry.date)
        })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthName)
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.text)
            
            HStack(spacing: 2) {
                ForEach(1...daysInMonth, id: \.self) { day in
                    Rectangle()
                        .fill(entryDays.contains(day) ? styles.colors.accent : styles.colors.tertiaryBackground)
                        .frame(height: 12)
                        .cornerRadius(2)
                }
            }
        }
    }
}

struct ConsistencyStatsView: View {
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    
    private var entriesByMonth: [Int: Int] {
        let calendar = Calendar.current
        var counts: [Int: Int] = [:]
        
        for entry in entries {
            let month = calendar.component(.month, from: entry.date)
            counts[month, default: 0] += 1
        }
        
        return counts
    }
    
    private var bestMonth: (month: Int, count: Int)? {
        if let best = entriesByMonth.max(by: { $0.value < $1.value }) {
            return (month: best.key, count: best.value)
        }
        return nil
    }
    
    private var averageEntriesPerMonth: Double {
        if entriesByMonth.isEmpty {
            return 0
        }
        
        let total = entriesByMonth.values.reduce(0, +)
        return Double(total) / Double(entriesByMonth.count)
    }
    
    private var longestStreak: Int {
        var maxStreak = 0
        var currentStreak = 0
        let calendar = Calendar.current
        
        // Sort entries by date
        let sortedEntries = entries.sorted { $0.date < $1.date }
        
        // Find the longest streak
        for i in 0..<sortedEntries.count {
            if i == 0 {
                currentStreak = 1
            } else {
                let previousDate = calendar.startOfDay(for: sortedEntries[i-1].date)
                let currentDate = calendar.startOfDay(for: sortedEntries[i].date)
                
                if let dayDifference = calendar.dateComponents([.day], from: previousDate, to: currentDate).day, dayDifference == 1 {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
            }
            
            maxStreak = max(maxStreak, currentStreak)
        }
        
        return maxStreak
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            Text("Consistency Stats")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: styles.layout.spacingXL) {
                if let best = bestMonth {
                    StatItem(
                        value: monthName(for: best.month),
                        label: "Best Month",
                        icon: "calendar.badge.clock"
                    )
                }
                
                StatItem(
                    value: String(format: "%.1f", averageEntriesPerMonth),
                    label: "Monthly Avg",
                    icon: "chart.bar.fill"
                )
                
                StatItem(
                    value: "\(longestStreak)",
                    label: "Longest Streak",
                    icon: "flame.fill"
                )
            }
        }
    }
    
    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        var components = DateComponents()
        components.month = month
        components.day = 1
        components.year = Calendar.current.component(.year, from: Date())
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        
        return ""
    }
}

