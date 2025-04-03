import SwiftUI

// MARK: - Insight Detail Model

// Define the NEW set of Insight Types based on the updated card list
enum InsightType: String, Codable, Equatable, Hashable { // Added Equatable & Hashable for potential use
    case streakNarrative // Replaces streak
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
                  case .streakNarrative:
                       // Attempt to cast insight.data to the expected type
                       let narrativeData = insight.data as? StreakNarrativeResult
                       // Pass the casted data (or nil) to the detail view
                       StreakNarrativeDetailContent(
                           streak: appState.currentStreak,
                           entries: appState.journalEntries,
                           narrativeResult: narrativeData
                       )

                  case .weeklySummary:
                      // Needs decoded WeeklySummaryResult
                      if let result = insight.data as? WeeklySummaryResult {
                           // Use the specific expanded view component
                           // We need to calculate the period and get the date here or pass it
                           // For simplicity, let's assume necessary info is available or recalculated
                           let period = calculateSummaryPeriod(from: result) // Placeholder function
                           // TODO: Pass the actual generatedDate if available from insight.data or another source
                           WeeklySummaryDetailContent(summaryResult: result, summaryPeriod: period, generatedDate: Date()) // Pass optional date
                      } else {
                          Text("Error: Invalid weekly summary data") // Or show empty state
                      }
                      // Removed cases for obsolete InsightTypes:
                      // .calendar, .writingConsistency, .moodDistribution, .wordCount,
                      // .topicAnalysis, .sentimentAnalysis, .journalEntry, .weeklyPatterns

                  case .aiReflection:
                       // Needs AIReflectionResult
                       if let result = insight.data as? AIReflectionResult {
                            AIReflectionDetailContent(
                                insightMessage: result.insightMessage,
                                reflectionPrompts: result.reflectionPrompts
                            )
                       } else {
                           // Fallback or error view if data isn't the correct type
                           AIReflectionDetailContent(
                                insightMessage: "Could not load reflection.",
                                reflectionPrompts: []
                           )
                       }

                  case .moodAnalysis:
                      // Needs journal entries from AppState
                      MoodAnalysisDetailContent(entries: appState.journalEntries)

                  case .recommendations:
                      // Needs decoded RecommendationResult
                      if let result = insight.data as? RecommendationResult {
                          RecommendationsDetailContent(recommendations: result.recommendations)
                      } else {
                           RecommendationsDetailContent(recommendations: []) // Show empty state
                      }

                  case .forecast:
                       // Needs decoded ForecastResult
                       let forecastData = insight.data as? ForecastResult // Attempt to cast
                       ForecastDetailContent(forecastResult: forecastData) // Pass casted data or nil
                  }
              }
              .padding(styles.layout.paddingL) // Add padding around the detail content
          }
          .navigationTitle(insight.title) // Set title from insight
          .navigationBarTitleDisplayMode(.inline)
          .toolbar { // Use .toolbar for navigation items
               ToolbarItem(placement: .navigationBarTrailing) { // Place on the right
                   Button {
                       dismiss() // Use dismiss action
                   } label: {
                       Image(systemName: "xmark") // Standard close icon
                           .font(.system(size: 16, weight: .bold)) // Style as needed
                           .foregroundColor(styles.colors.accent) // Use accent color
                   }
               }
           }
      }
  }

    // Placeholder helper function - actual calculation might need more context
     private func calculateSummaryPeriod(from result: WeeklySummaryResult) -> String {
         // In a real scenario, the period start/end might be stored alongside the result
         // For now, return a placeholder based on current date
         let calendar = Calendar.current
         let endDate = Date()
         let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "MMM d"
         return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
     }
}

// MARK: - Preview Provider

#Preview {
     // Example: Create insight detail for forecast preview
     // ForecastDetailContent currently shows placeholders and doesn't require complex data
     let mockForecastData: ForecastResult? = nil // Explicitly nil or provide mock ForecastResult
     let mockInsight = InsightDetail(type: .forecast, title: "Forecast Preview", data: mockForecastData)

     // Pass necessary environment objects for previews
     return InsightDetailView(insight: mockInsight)
         .environmentObject(AppState()) // Provide mock AppState if needed by detail views
         .environmentObject(UIStyles.shared)
         .environmentObject(ThemeManager.shared)
}