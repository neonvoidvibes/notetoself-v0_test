import SwiftUI

// MARK: - Insight Detail Model

// Define the NEW set of Insight Types based on the updated card list
enum InsightType: String, Codable, Equatable, Hashable { // Added Equatable & Hashable for potential use
    // --- NEW Top Cards ---
    case dailyReflection // #1
    case weekInReview    // #2

    // --- Existing Cards ---
    case journeyNarrative // Renamed from streakNarrative
    case weeklySummary    // Original weekly summary (may be deprecated by weekInReview)
    case aiReflection     // Original AI Reflection (may be deprecated by dailyReflection)
    case moodAnalysis     // Original Mood Analysis (may be deprecated by Feel)
    case recommendations  // Original Recommendations (may be deprecated by Act)
    case forecast         // Original Forecast (may be deprecated by Act)

    // --- NEW Grouped Cards ---
    case feelInsights     // #3
    case thinkInsights    // #4
    case actInsights      // #5
    case learnInsights    // #6

}

struct InsightDetail: Identifiable {
  let id = UUID()
  let type: InsightType // Use the updated enum
  let title: String // Dynamic title based on card
  let data: Any? // Data can be nil or specific types depending on the insight

    // Add Equatable conformance
    static func == (lhs: InsightDetail, rhs: InsightDetail) -> Bool {
        return lhs.id == rhs.id
    }

    // Add Hashable conformance
     func hash(into hasher: inout Hasher) {
         hasher.combine(id)
     }
}


// MARK: - Hidden Feature Placeholder (Keep for potential future use)

struct HiddenFeatureDetailContent: View {
    let title: String
    @ObservedObject private var styles = UIStyles.shared // Use styles

    var body: some View {
        VStack(spacing: styles.layout.spacingL) { // Use layout spacing
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(styles.colors.textSecondary) // Use secondary text color
                .padding(.bottom, styles.layout.paddingL) // Use layout padding

            Text("Premium Feature")
                .font(styles.typography.title1) // Use typography
                .fontWeight(.bold)
                .foregroundColor(styles.colors.text) // Use text color

            Text("\(title) is currently available only in the premium version.") // Updated text
                .font(styles.typography.bodyFont) // Use typography
                .foregroundColor(styles.colors.textSecondary) // Use secondary text color
                .multilineTextAlignment(.center)
                .padding(.horizontal, styles.layout.paddingXL) // Use layout padding

            // Optional: Add upgrade button here if desired
             Button("Upgrade to Premium") {
                 // TODO: Add action to show subscription options
             }
             .buttonStyle(GlowingButtonStyle()) // Use themed button style
             .padding(.top, styles.layout.paddingL)

        }
        .padding(styles.layout.paddingXL) // Use layout padding
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(styles.colors.appBackground) // Use app background
    }
}

// MARK: - Insight Detail View (Updated for New Cards)

struct InsightDetailView: View {
  let insight: InsightDetail
  // Pass specific data required by detail views, e.g., entries for analysis cards
  @EnvironmentObject var appState: AppState // Access app state for data if needed
  @Environment(\.dismiss) var dismiss // Use dismiss environment variable

  @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

  var body: some View {
      // Using NavigationView for title bar and close button
      NavigationView {
          ZStack {
              styles.colors.appBackground.ignoresSafeArea() // Use themed background

              // Content based on NEW insight type
              Group {
                  switch insight.type {
                  // --- NEW TOP CARDS ---
                  case .dailyReflection:
                      if let result = insight.data as? DailyReflectionResult {
                           DailyReflectionDetailContent(result: result, generatedDate: Date()) // Placeholder date
                      } else { Text("Error: Invalid Daily Reflection data") }
                  case .weekInReview:
                      if let result = insight.data as? WeekInReviewResult {
                           WeekInReviewDetailContent(result: result, generatedDate: Date()) // Placeholder date
                      } else { Text("Error: Invalid Week in Review data") }

                  // --- EXISTING CARDS ---
                  case .journeyNarrative:
                       let narrativeData = insight.data as? StreakNarrativeResult
                       let genDate = Date()
                       JourneyNarrativeDetailContent(
                           streak: appState.currentStreak,
                           entries: appState.journalEntries,
                           narrativeResult: narrativeData,
                           generatedDate: genDate
                       )
                  case .weeklySummary: // Keep original for now
                      if let result = insight.data as? WeeklySummaryResult {
                           let period = calculateSummaryPeriod(from: result)
                           let genDate = Date()
                           WeeklySummaryDetailContent(
                               summaryResult: result,
                               summaryPeriod: period,
                               generatedDate: genDate
                           )
                      } else { Text("Error: Invalid weekly summary data") }
                  case .aiReflection: // Keep original for now
                       if let result = insight.data as? AIReflectionResult {
                           let genDate = Date()
                            AIReflectionDetailContent(
                                insightMessage: result.insightMessage,
                                reflectionPrompts: result.reflectionPrompts,
                                generatedDate: genDate
                            )
                       } else {
                           AIReflectionDetailContent(
                                insightMessage: "Could not load reflection.",
                                reflectionPrompts: [],
                                generatedDate: nil
                           )
                       }
                  case .moodAnalysis: // Keep original for now
                      let genDate = Date()
                      MoodAnalysisDetailContent(
                          entries: appState.journalEntries,
                          generatedDate: genDate
                      )
                  case .recommendations: // Keep original for now
                      if let result = insight.data as? RecommendationResult {
                           let genDate = Date()
                          RecommendationsDetailContent(
                              recommendations: result.recommendations,
                              generatedDate: genDate
                          )
                      } else {
                           RecommendationsDetailContent(recommendations: [], generatedDate: nil)
                      }
                  case .forecast: // Keep original for now
                       let forecastData = insight.data as? ForecastResult
                       let genDate = Date()
                       ForecastDetailContent(
                           forecastResult: forecastData,
                           generatedDate: genDate
                       )

                   // --- NEW GROUPED CARDS ---
                   case .feelInsights:
                        if let result = insight.data as? FeelInsightResult {
                             FeelDetailContent(result: result, generatedDate: Date()) // Placeholder date
                        } else { Text("Error: Invalid Feel Insight data") }
                   case .thinkInsights:
                        if let result = insight.data as? ThinkInsightResult {
                            ThinkDetailContent(result: result, generatedDate: Date()) // Placeholder date
                        } else { Text("Error: Invalid Think Insight data") }
                   case .actInsights:
                        if let result = insight.data as? ActInsightResult {
                            ActDetailContent(result: result, generatedDate: Date()) // Placeholder date
                        } else { Text("Error: Invalid Act Insight data") }
                   case .learnInsights:
                       if let result = insight.data as? LearnInsightResult {
                           LearnDetailContent(result: result, generatedDate: Date()) // Placeholder date
                       } else { Text("Error: Invalid Learn Insight data") }
                   }
              }
          }
          .navigationTitle(insight.title) // Set title from insight
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
               ToolbarItem(placement: .navigationBarTrailing) {
                   Button {
                       dismiss()
                   } label: {
                       Image(systemName: "xmark")
                           .font(.system(size: 16, weight: .bold))
                           .foregroundColor(styles.colors.accent)
                   }
               }
           }
      }
  }

     // Keep this helper if original WeeklySummary card remains
     private func calculateSummaryPeriod(from result: WeeklySummaryResult) -> String {
         let calendar = Calendar.current
         let endDate = Date()
         let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "MMM d"
         return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
     }
}

#Preview {
     // Use a valid preview type, e.g., feelInsights
     let mockInsight = InsightDetail(type: .feelInsights, title: "Feel Preview", data: FeelInsightResult.empty())

     return InsightDetailView(insight: mockInsight)
         .environmentObject(AppState())
         .environmentObject(UIStyles.shared)
         .environmentObject(ThemeManager.shared)
}