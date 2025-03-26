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
        Button(action: {
            isExpanded = true
        }) {
            styles.enhancedCard(
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
                        
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: styles.layout.iconSizeL))
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
                    
                    // View more button
                    HStack {
                        Spacer()
                        
                        Text("View Full Summary")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.accent)
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: 12))
                    }
                }
                .padding(styles.layout.cardInnerPadding),
                isPrimary: isFresh // Make it primary if it's fresh
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isExpanded) {
            InsightDetailView(
                insight: InsightDetail(
                    type: .weeklySummary,
                    title: "Weekly Summary",
                    data: weeklyEntries
                ),
                entries: entries
            )
        }
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

