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
        styles.expandableCard(
            isExpanded: $isExpanded,
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Writing Consistency")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
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
            },
            detailContent: {
                // Expanded detail content
                VStack(spacing: styles.layout.spacingL) {
                    // Monthly consistency analysis
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Monthly Analysis")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Text(generateDetailedConsistencyAnalysis())
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Consistency calendar
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Consistency Calendar")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                            ForEach(daysInLastMonthArray(), id: \.self) { day in
                                ConsistencyDayView(
                                    day: day,
                                    hasEntry: hasEntryForDay(day),
                                    styles: styles
                                )
                            }
                        }
                    }
                    
                    // Consistency tips
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Tips to Improve Consistency")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        ForEach(consistencyTips(), id: \.self) { tip in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(styles.colors.accent)
                                    .font(.system(size: 12))
                                    .padding(.top, 4)
                                
                                Text(tip)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        )
    }
    
    // Helper methods for expanded content
    private func daysInLastMonthArray() -> [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: lastMonth)
        let firstDayOfMonth = calendar.date(from: components)!
        
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
        
        return (1...range.count).map { day in
            let dateComponents = DateComponents(year: components.year, month: components.month, day: day)
            return calendar.date(from: dateComponents)!
        }
    }
    
    private func hasEntryForDay(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return entriesLastMonth.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
    
    private func generateDetailedConsistencyAnalysis() -> String {
        if entriesLastMonth.isEmpty {
            return "You didn't make any journal entries last month. Starting a journaling habit can be challenging, but even a few minutes each day can make a significant difference in self-awareness and emotional processing."
        }
        
        let percentage = Int(completionRate * 100)
        
        var analysis = ""
        
        if percentage < 30 {
            analysis = "You journaled on \(entriesLastMonth.count) days last month, which is \(percentage)% of the days. While your journaling was occasional, remember that any reflection is valuable. Even sporadic entries can provide meaningful insights into your experiences and emotions."
        } else if percentage < 60 {
            analysis = "You journaled on \(entriesLastMonth.count) of \(daysInLastMonth) days last month (\(percentage)% consistency). This shows a good commitment to your journaling practice. Your growing consistency helps build self-awareness and creates a valuable record of your experiences."
        } else if percentage < 90 {
            analysis = "Great consistency! You journaled on \(entriesLastMonth.count) days last month (\(percentage)% of days). This strong habit demonstrates your commitment to self-reflection and personal growth. Regular journaling helps reveal patterns and insights that might otherwise go unnoticed."
        } else {
            analysis = "Exceptional dedication! You journaled on \(entriesLastMonth.count) of \(daysInLastMonth) days last month (\(percentage)% consistency). This level of commitment creates a comprehensive record of your experiences and emotions, enabling deeper self-understanding and more nuanced insights."
        }
        
        // Add pattern analysis
        let calendar = Calendar.current
        var entriesByWeekday: [Int: Int] = [:]
        
        for entry in entriesLastMonth {
            let weekday = calendar.component(.weekday, from: entry.date)
            entriesByWeekday[weekday, default: 0] += 1
        }
        
        if let mostConsistentDay = entriesByWeekday.max(by: { $0.value < $1.value }) {
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEEE"
            let dayName = weekdayFormatter.string(from: nextWeekday(weekday: mostConsistentDay.key))
            
            analysis += " You tend to journal most consistently on \(dayName)s, which might reflect a pattern in your schedule or energy levels."
        }
        
        return analysis
    }
    
    private func nextWeekday(weekday: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today)
        
        let daysToAdd = (weekday - todayWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd, to: today)!
    }
    
    private func consistencyTips() -> [String] {
        let percentage = Int(completionRate * 100)
        
        if percentage < 30 {
            return [
                "Set a specific time each day for journaling, even if it's just for 5 minutes.",
                "Keep your journal easily accessible, whether physical or digital.",
                "Start with shorter entries to build the habit without feeling overwhelmed.",
                "Use reminders or pair journaling with an existing habit like morning coffee."
            ]
        } else if percentage < 60 {
            return [
                "Identify the days you tend to miss and consider what obstacles might be present.",
                "Experiment with different journaling times to find what works best for your schedule.",
                "Create a simple template to make starting entries easier on busy days.",
                "Celebrate your consistency and reflect on how regular journaling has benefited you."
            ]
        } else {
            return [
                "Consider varying your journaling prompts to keep the practice fresh and engaging.",
                "Periodically review past entries to appreciate your growth and insights.",
                "Share your consistency strategies with others who might benefit.",
                "Explore deeper reflection techniques to build on your strong foundation."
            ]
        }
    }
    
    // Generate consistency insight for preview
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

// Helper view for consistency calendar
struct ConsistencyDayView: View {
    let day: Date
    let hasEntry: Bool
    let styles: UIStyles
    
    var body: some View {
        ZStack {
            if hasEntry {
                RoundedRectangle(cornerRadius: 4)
                    .fill(styles.colors.accent)
                    .frame(width: 24, height: 24)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(styles.colors.tertiaryBackground, lineWidth: 1)
                    .frame(width: 24, height: 24)
            }
            
            Text("\(Calendar.current.component(.day, from: day))")
                .font(styles.typography.caption)
                .foregroundColor(hasEntry ? .black : styles.colors.textSecondary)
        }
    }
}

