import SwiftUI

// Model to represent different types of insights for detail view
struct InsightDetail: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let data: Any
    
    enum InsightType {
        case streak
        case calendar
        case moodTrends
        case writingConsistency
        case moodDistribution
        case wordCount
        case topicAnalysis
        case sentimentAnalysis
        case journalEntry(JournalEntry)
    }
}

struct InsightDetailView: View {
    let insight: InsightDetail
    let entries: [JournalEntry]
    @Environment(\.dismiss) private var dismiss
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom navigation bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: styles.layout.spacingS) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(styles.typography.bodyFont)
                        }
                        .foregroundColor(styles.colors.accent)
                    }
                    
                    Spacer()
                    
                    // Title
                    Text(insight.title)
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                    
                    // Empty space to balance the back button
                    HStack(spacing: styles.layout.spacingS) {
                        Text("     ")
                            .font(styles.typography.bodyFont)
                    }
                    .opacity(0)
                }
                .padding(.horizontal, styles.layout.paddingXL)
                .padding(.top, styles.layout.topSafeAreaPadding)
                .padding(.bottom, styles.layout.paddingM)
                
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: styles.layout.spacingXL) {
                        // Content based on insight type
                        switch insight.type {
                        case .streak:
                            StreakDetailContent(streak: insight.data as? Int ?? 0)
                        case .calendar:
                            if let date = insight.data as? Date {
                                CalendarDetailContent(selectedMonth: date, entries: entries)
                            }
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
                        case .journalEntry(let entry):
                            JournalEntryDetailContent(entry: entry)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, styles.layout.paddingL)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

