import SwiftUI

// MARK: - Insight Detail Model

enum InsightType: String, Codable {
    case streak
    case calendar
    case moodTrends
    case writingConsistency
    case moodDistribution
    case wordCount
    case topicAnalysis
    case sentimentAnalysis
    case journalEntry
    case weeklySummary
    case weeklyPatterns
    case recommendations
}

struct InsightDetail: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let data: Any
}

extension InsightDetail: Equatable {
    static func == (lhs: InsightDetail, rhs: InsightDetail) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Insight Detail View

struct InsightDetailView: View {
    let insight: InsightDetail
    let entries: [JournalEntry]
    @Environment(\.presentationMode) var presentationMode
    
    private let styles = UIStyles.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                styles.colors.appBackground.ignoresSafeArea()
                
                // Content based on insight type
                Group {
                    switch insight.type {
                    case .streak:
                        StreakDetailContent(streak: insight.data as! Int)
                    case .calendar:
                        CalendarDetailContent(selectedMonth: insight.data as! Date, entries: entries)
                    case .moodTrends:
                        MoodTrendsDetailContent(entries: entries)
                    case .writingConsistency:
                        WritingConsistencyDetailContent(entries: entries)
                    case .moodDistribution:
                        MoodDistributionDetailContent(entries: entries)
                    case .wordCount:
                        WordCountDetailContent(entries: entries)
                    case .topicAnalysis:
                        TopicAnalysisDetailContent(entries: entries)
                    case .sentimentAnalysis:
                        SentimentAnalysisDetailContent(entries: entries)
                    case .journalEntry:
                        JournalEntryDetailContent(entry: insight.data as! JournalEntry)
                    case .weeklySummary:
                        WeeklySummaryDetailContent(entries: entries)
                    case .weeklyPatterns:
                        WeeklyPatternsDetailContent(entries: entries)
                    case .recommendations:
                        RecommendationsDetailContent(recommendations: insight.data as! [Recommendation])
                    }
                }
            }
            .navigationBarTitle(insight.title, displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(styles.colors.accent)
                    .font(.system(size: 20))
            })
        }
    }
}

