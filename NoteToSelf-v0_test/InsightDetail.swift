import SwiftUI

// MARK: - Insight Detail Model

// Define the NEW set of Insight Types based on the updated card list
enum InsightType: String, Codable, Equatable, Hashable { // Added Equatable & Hashable for potential use
    case journeyNarrative // Renamed from streakNarrative
    case weeklySummary
    case aiReflection // Replaces chat
    case moodAnalysis // Replaces moodTrends
    case recommendations
    case forecast // New card

    // Obsolete types removed as they are no longer displayed insight cards
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
                  case .journeyNarrative: // Renamed case
                       let narrativeData = insight.data as? StreakNarrativeResult // Still uses StreakNarrativeResult struct
                       let genDate = Date() // Placeholder - Need to pass actual date if available
                       // Use renamed detail view component
                       JourneyNarrativeDetailContent(
                           streak: appState.currentStreak,
                           entries: appState.journalEntries,
                           narrativeResult: narrativeData,
                           generatedDate: genDate // Pass date
                       )

                  case .weeklySummary:
                      if let result = insight.data as? WeeklySummaryResult {
                           let period = calculateSummaryPeriod(from: result)
                           let genDate = Date() // Placeholder
                           WeeklySummaryDetailContent(
                               summaryResult: result,
                               summaryPeriod: period,
                               generatedDate: genDate
                           )
                      } else {
                          Text("Error: Invalid weekly summary data")
                      }

                  case .aiReflection:
                       if let result = insight.data as? AIReflectionResult {
                           let genDate = Date() // Placeholder
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

                  case .moodAnalysis:
                      let genDate = Date() // Placeholder
                      MoodAnalysisDetailContent(
                          entries: appState.journalEntries,
                          generatedDate: genDate
                      )

                  case .recommendations:
                      if let result = insight.data as? RecommendationResult {
                           let genDate = Date() // Placeholder
                          RecommendationsDetailContent(
                              recommendations: result.recommendations,
                              generatedDate: genDate
                          )
                      } else {
                           RecommendationsDetailContent(recommendations: [], generatedDate: nil)
                      }

                  case .forecast:
                       let forecastData = insight.data as? ForecastResult
                       let genDate = Date() // Placeholder
                       ForecastDetailContent(
                           forecastResult: forecastData,
                           generatedDate: genDate
                       )
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
     let mockForecastData: ForecastResult? = nil
     // Use the renamed enum case for preview
     let mockInsight = InsightDetail(type: .journeyNarrative, title: "Journey Preview", data: StreakNarrativeResult.empty())

     return InsightDetailView(insight: mockInsight)
         .environmentObject(AppState())
         .environmentObject(UIStyles.shared)
         .environmentObject(ThemeManager.shared)
}