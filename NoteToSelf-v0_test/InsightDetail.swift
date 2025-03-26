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
  let data: Any
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
                      // Placeholder for hidden feature
                      HiddenFeatureDetailContent(title: "Word Count Analysis")
                  case .topicAnalysis:
                      // Placeholder for hidden feature
                      HiddenFeatureDetailContent(title: "Topic Analysis")
                  case .sentimentAnalysis:
                      // Placeholder for hidden feature
                      HiddenFeatureDetailContent(title: "Sentiment Analysis")
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

