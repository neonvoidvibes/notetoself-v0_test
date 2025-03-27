import SwiftUI

struct WeeklySummaryInsightCard: View {
    let entries: [JournalEntry]
    @State private var isExpanded: Bool = false
    private let styles = UIStyles.shared
    
    // Check if the summary is fresh (generated in the past 24 hours)
    // In a real app, this would be based on when the summary was actually generated
    private var isFresh: Bool {
        // For demo purposes, we'll consider it fresh if there's an entry from today
        return entries.contains { Calendar.current.isDateInToday($0.date) }
    }
    
    private var summaryPeriod: String {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate the start of the current week (Sunday)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        // Calculate the end of the week (Saturday)
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        // Format the dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        return "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endOfWeek))"
    }
    
    private var weeklyEntries: [JournalEntry] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        return entries.filter { entry in
            let entryDate = entry.date
            return entryDate >= startOfWeek && entryDate <= today
        }
    }
    
    private var dominantMood: Mood? {
        let moodCounts = weeklyEntries.reduce(into: [Mood: Int]()) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private var entryCount: Int {
        return weeklyEntries.count
    }
    
    private var averageWordCount: Int {
        guard !weeklyEntries.isEmpty else { return 0 }
        
        let totalWords = weeklyEntries.reduce(0) { total, entry in
            total + entry.text.split(separator: " ").count
        }
        
        return totalWords / weeklyEntries.count
    }
    
    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            isPrimary: isFresh,
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    // Header with badge for fresh summaries
                    HStack {
                        Text("Weekly Summary")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                    
                        if isFresh {
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(styles.colors.accent)
                                .cornerRadius(4)
                        }
                    
                        Spacer()
                    }
                
                    // Period
                    Text(summaryPeriod)
                        .font(styles.typography.insightCaption)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                
                    // Summary stats
                    HStack(spacing: styles.layout.spacingXL) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Entries")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                        
                            Text("\(entryCount)")
                                .font(styles.typography.insightValue)
                                .foregroundColor(styles.colors.text)
                        }
                    
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dominant Mood")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                        
                            HStack(spacing: 4) {
                                if let mood = dominantMood {
                                    Circle()
                                        .fill(mood.color)
                                        .frame(width: 12, height: 12)
                                
                                    Text(mood.name)
                                        .font(styles.typography.bodyLarge)
                                        .foregroundColor(styles.colors.text)
                                } else {
                                    Text("N/A")
                                        .font(styles.typography.bodyLarge)
                                        .foregroundColor(styles.colors.textSecondary)
                                }
                            }
                        }
                    
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Avg. Words")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                        
                            Text("\(averageWordCount)")
                                .font(styles.typography.insightValue)
                                .foregroundColor(styles.colors.text)
                        }
                    }
                    .padding(.vertical, styles.layout.spacingS)
                
                    // Summary text - more conversational and focused
                    Text(generateSummaryText())
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }
            },
            detailContent: {
                // Expanded detail content
                VStack(spacing: styles.layout.spacingL) {
                    // Detailed weekly stats
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Weekly Insights")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                    
                        Text(generateDetailedSummary())
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                
                    // Entry breakdown by day
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Daily Breakdown")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                    
                        ForEach(daysOfWeek(), id: \.self) { day in
                            DailyEntryRow(
                                day: day,
                                entry: entryForDay(day),
                                styles: styles
                            )
                        }
                    }
                
                    // Weekly themes
                    if let themes = identifyWeeklyThemes() {
                        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                            Text("Weekly Themes")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)
                        
                            Text(themes)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        )
    }
    
    // Helper methods for expanded content
    private func daysOfWeek() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!
        
        return (0..<7).map { day in
            calendar.date(byAdding: .day, value: day, to: startOfWeek)!
        }
    }
    
    private func entryForDay(_ date: Date) -> JournalEntry? {
        let calendar = Calendar.current
        return entries.first { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
    
    private func generateDetailedSummary() -> String {
        guard !weeklyEntries.isEmpty else {
            return "You haven't made any entries this week yet. Starting a journaling habit can help you track your moods, thoughts, and experiences over time."
        }
        
        let moodPhrase: String
        if let mood = dominantMood {
            switch mood {
            case .happy, .excited, .content, .relaxed, .calm:
                moodPhrase = "Your predominant mood this week has been \(mood.name.lowercased()), which suggests you're experiencing a period of positive emotions and well-being."
            case .sad, .depressed, .anxious, .stressed:
                moodPhrase = "You've been feeling predominantly \(mood.name.lowercased()) this week. Remember that emotions are temporary and it's okay to seek support when needed."
            case .angry:
                moodPhrase = "Frustration has been a common theme in your entries this week. Consider what might be triggering these feelings and whether there are constructive ways to address the underlying issues."
            case .bored:
                moodPhrase = "You've mentioned feeling bored several times this week. This might be an opportunity to explore new activities or revisit interests you've enjoyed in the past."
            default:
                moodPhrase = "Your mood has shown variety this week, reflecting the natural complexity of emotional experience."
            }
        } else {
            moodPhrase = "Your mood has varied throughout the week, showing the natural ebb and flow of emotions."
        }
        
        let consistencyPhrase: String
        if entryCount >= 5 {
            consistencyPhrase = "You've been remarkably consistent with your journaling this week, with \(entryCount) entries. This regular practice helps build self-awareness and provides valuable insights into your patterns over time."
        } else if entryCount >= 3 {
            consistencyPhrase = "You've made \(entryCount) entries this week, showing a good commitment to your journaling practice. This consistency helps you track patterns and changes in your thoughts and feelings."
        } else {
            consistencyPhrase = "You've made \(entryCount) entries so far this week. Even occasional journaling provides valuable snapshots of your experiences and emotions."
        }
        
        let expressionPhrase: String
        if averageWordCount > 100 {
            expressionPhrase = "Your entries have been quite detailed (averaging \(averageWordCount) words), suggesting you're taking time for deep reflection."
        } else if averageWordCount > 50 {
            expressionPhrase = "Your entries have been moderately detailed (averaging \(averageWordCount) words), providing a good balance of reflection and brevity."
        } else {
            expressionPhrase = "Your entries have been concise (averaging \(averageWordCount) words), capturing your thoughts efficiently."
        }
        
        return "\(moodPhrase) \(consistencyPhrase) \(expressionPhrase)"
    }
    
    private func identifyWeeklyThemes() -> String? {
        guard weeklyEntries.count >= 3 else {
            return nil
        }
        
        // In a real app, this would use NLP to identify common themes
        // For demo purposes, we'll return a placeholder
        return "Based on your entries this week, common themes include personal reflection, daily routines, and social interactions. Journaling about these areas helps build awareness of what matters most to you."
    }
    
    // Update the generateSummaryText method to be more conversational and focused
    private func generateSummaryText() -> String {
        guard !weeklyEntries.isEmpty else {
            return "No entries yet this week. Start journaling to build your personal insights."
        }
        
        let moodPhrase: String
        if let mood = dominantMood {
            switch mood {
            case .happy, .excited, .content, .relaxed, .calm:
                moodPhrase = "You've been mostly \(mood.name.lowercased()) this week - that's great!"
            case .sad, .depressed, .anxious, .stressed:
                moodPhrase = "You've experienced some \(mood.name.lowercased()) feelings this week."
            case .angry:
                moodPhrase = "You've expressed some frustration in your entries this week."
            case .bored:
                moodPhrase = "You've mentioned feeling bored several times this week."
            default:
                moodPhrase = "Your mood has been mixed this week."
            }
        } else {
            moodPhrase = "Your mood has varied throughout the week."
        }
        
        let consistencyPhrase: String
        if entryCount >= 5 {
            consistencyPhrase = "Your consistent journaling is building a great reflection habit."
        } else if entryCount >= 3 {
            consistencyPhrase = "You're developing a good journaling rhythm."
        } else {
            consistencyPhrase = "Adding more entries will help reveal deeper patterns."
        }
        
        return "\(moodPhrase) \(consistencyPhrase)"
    }
}

// Helper view for daily entry rows in expanded view
struct DailyEntryRow: View {
    let day: Date
    let entry: JournalEntry?
    let styles: UIStyles
    
    var body: some View {
        HStack(spacing: styles.layout.spacingM) {
            // Day label
            Text(formatDay(day))
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.text)
                .frame(width: 80, alignment: .leading)
            
            // Entry indicator
            if let entry = entry {
                HStack {
                    Circle()
                        .fill(entry.mood.color)
                        .frame(width: 12, height: 12)
                    
                    Text(entry.mood.name)
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                    
                    Text("\(entry.text.split(separator: " ").count) words")
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.textSecondary)
                }
                .padding(8)
                .background(styles.colors.tertiaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)
            } else {
                Text("No entry")
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(styles.colors.tertiaryBackground.opacity(0.3))
                    .cornerRadius(styles.layout.radiusM)
            }
        }
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

