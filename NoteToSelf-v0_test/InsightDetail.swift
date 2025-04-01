import SwiftUI

// MARK: - Insight Detail Model

enum InsightType: String, Codable {
  case streak
  case calendar
  case moodTrends
  case writingConsistency
  case moodDistribution
  case wordCount // Hidden but kept for data model compatibility
  case topicAnalysis // Hidden but kept for data model compatibility
  case sentimentAnalysis // Hidden but kept for data model compatibility
  case journalEntry
  case weeklySummary
  case weeklyPatterns
  case recommendations
}

struct InsightDetail: Identifiable {
  let id = UUID()
  let type: InsightType
  let title: String
  let data: Any // Data can be different types depending on the insight
}

extension InsightDetail: Equatable {
  static func == (lhs: InsightDetail, rhs: InsightDetail) -> Bool {
      return lhs.id == rhs.id
  }
}

// MARK: - Hidden Feature Placeholder

struct HiddenFeatureDetailContent: View {
    let title: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding(.bottom, 10)

            Text("Premium Feature")
                .font(.title)
                .fontWeight(.bold)

            Text("\(title) is currently available only in premium version")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("This feature will be available in a future update.")
                .foregroundColor(.gray)
                .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Insight Detail View

struct InsightDetailView: View {
  let insight: InsightDetail
  let entries: [JournalEntry] // Keep entries for context if needed by some detail views
  @Environment(\.presentationMode) var presentationMode

  @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

  var body: some View {
      // Use NavigationView or NavigationStack based on deployment target
      NavigationView {
          ZStack {
              styles.colors.appBackground.ignoresSafeArea()

              // Content based on insight type
              Group {
                  switch insight.type {
                  case .streak:
                      // Assuming data is Int
                      if let streak = insight.data as? Int {
                          StreakDetailContent(streak: streak)
                      } else {
                          Text("Error: Invalid streak data")
                      }
                  case .calendar:
                       // Assuming data is Date
                       if let month = insight.data as? Date {
                            CalendarDetailContent(selectedMonth: month, entries: entries)
                       } else {
                           Text("Error: Invalid calendar data")
                       }
                  case .moodTrends:
                      // MoodTrendsDetailContent uses entries directly
                      MoodTrendsDetailContent(entries: entries)
                  case .writingConsistency:
                      // WritingConsistencyDetailContent uses entries directly
                      WritingConsistencyDetailContent(entries: entries)
                  case .moodDistribution:
                       // MoodDistributionDetailContent uses entries directly
                       MoodDistributionDetailContent(entries: entries)
                  case .wordCount:
                      HiddenFeatureDetailContent(title: "Word Count Analysis")
                  case .topicAnalysis:
                      HiddenFeatureDetailContent(title: "Topic Analysis")
                  case .sentimentAnalysis:
                      HiddenFeatureDetailContent(title: "Sentiment Analysis")
                  case .journalEntry:
                      // Assuming data is JournalEntry
                      if let entry = insight.data as? JournalEntry {
                          JournalEntryDetailContent(entry: entry)
                      } else {
                           Text("Error: Invalid journal entry data")
                      }
                  case .weeklySummary:
                       // WeeklySummaryDetailContent uses entries directly
                       WeeklySummaryDetailContent(entries: entries)
                  case .weeklyPatterns:
                        // WeeklyPatternsDetailContent uses entries directly
                        WeeklyPatternsDetailContent(entries: entries)
                  case .recommendations:
                       // Assuming data is RecommendationResult
                       if let result = insight.data as? RecommendationResult {
                            RecommendationsDetailContent(recommendations: result.recommendations)
                       } else {
                            // Fallback if data isn't RecommendationResult, maybe show empty state
                            RecommendationsDetailContent(recommendations: []) // Pass empty array
                            // Or: Text("Error: Invalid recommendations data")
                       }
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