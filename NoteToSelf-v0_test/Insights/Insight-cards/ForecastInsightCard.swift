import SwiftUI

// New card for Predictive Mood & General Forecast
struct ForecastInsightCard: View {
    // Input: Requires a dedicated ForecastResult Codable struct (to be defined)
    let subscriptionTier: SubscriptionTier

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false // State for full screen presentation
    @ObservedObject private var styles = UIStyles.shared
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService
    @EnvironmentObject var appState: AppState // Add EnvironmentObject

    // State for the decoded result and loading/error status
    @State private var forecastResult: ForecastResult? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "forecast" // Consistent identifier

    // Computed property for collapsed view label
    private var forecastLabel: String {
        if isLoading { return "Loading forecast..." }
        if loadError { return "Forecast unavailable" }
        guard let result = forecastResult else { return "Future insights ready." }

        var components: [String] = []
        if let mood = result.moodPredictionText, !mood.isEmpty {
            components.append("Mood: \(mood)")
        }
        if let consistency = result.consistencyForecast, !consistency.isEmpty {
             // Maybe shorten consistency forecast for collapsed view if too long
             let snippet = consistency.count > 20 ? "\(consistency.prefix(20))..." : consistency
             components.append("Consistency: \(snippet)")
        }
        if components.isEmpty {
             return "Future insights ready."
        }
        return components.joined(separator: "; ")
    }

    var body: some View {
        styles.expandableCard( // Removed isExpanded
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                 // Collapsed View: Standard Header + Forecast Label + Helping Text
                 VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     // Standard Header
                     HStack {
                         Text("Future Forecast")
                             .font(styles.typography.title3)
                             .foregroundColor(styles.colors.text)
                         Spacer()
                          // Icon on the right
                          Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                              .font(.system(size: 20)) // Standard header icon size
                              .foregroundColor(styles.colors.accent)

                          // Lock icon if free tier
                          if subscriptionTier == .free {
                               Image(systemName: "lock.fill")
                                   .foregroundColor(styles.colors.textSecondary)
                                   .padding(.leading, styles.layout.spacingS)
                           }
                     }

                     // Forecast Label (dynamic text)
                      HStack { // Wrap in HStack to potentially add ProgressView
                          Text(forecastLabel)
                              .font(styles.typography.bodyFont)
                              .foregroundColor(loadError ? styles.colors.error : styles.colors.text)
                              .lineLimit(2) // Allow two lines for label
                              .frame(maxWidth: .infinity, alignment: .leading)

                          if isLoading {
                              ProgressView().tint(styles.colors.accent)
                          }
                      }


                     // Helping Text (only if premium)
                     if subscriptionTier == .premium {
                         Text("Tap to see your personalized forecast and plan ahead.")
                             .font(styles.typography.caption)
                             .foregroundColor(styles.colors.accent)
                             .frame(maxWidth: .infinity, alignment: .leading)
                     } else {
                          // Placeholder or alternative text for free users in collapsed state
                          Text("Forecasting requires Premium.")
                              .font(styles.typography.caption)
                              .foregroundColor(styles.colors.textSecondary)
                              .frame(maxWidth: .infinity, alignment: .leading)
                     }
                 }
            } // Removed detailContent closure
        )
         .contentShape(Rectangle())
         .onTapGesture { if subscriptionTier == .premium { showingFullScreen = true } } // Only allow open if premium
         // Add loading logic
         .onAppear(perform: loadInsight)
          // Add listener for explicit insight updates
          .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
              print("[ForecastCard] Received insightsDidUpdate notification.")
              loadInsight() // Reload data when insights update
          }
         .fullScreenCover(isPresented: $showingFullScreen) {
              InsightFullScreenView(title: "Future Forecast") {
                  ForecastDetailContent(forecastResult: forecastResult)
              }
              .environmentObject(styles) // Pass styles
              // Pass other EnvironmentObjects if ForecastDetailContent needs them
          }
    } // End body

     // Function to load and decode the insight
     private func loadInsight() {
         guard !isLoading else { return }
         isLoading = true
         loadError = false
         print("[ForecastCard] Loading insight...")

         Task {
             do {
                 // Use await as DB call might become async
                 if let (json, _) = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                     if let data = json.data(using: .utf8) {
                         let result = try JSONDecoder().decode(ForecastResult.self, from: data)
                         await MainActor.run {
                             forecastResult = result
                             isLoading = false
                              print("[ForecastCard] Insight loaded and decoded.")
                         }
                     } else {
                         throw NSError(domain: "ForecastCard", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to Data"])
                     }
                 } else {
                     await MainActor.run {
                         forecastResult = nil
                         isLoading = false
                         print("[ForecastCard] No stored insight found.")
                     }
                 }
             } catch {
                  await MainActor.run {
                      print("‼️ [ForecastCard] Failed to load/decode insight: \(error)")
                      forecastResult = nil
                      loadError = true
                      isLoading = false
                  }
             }
         }
     }
} // Add missing closing brace for struct

 #Preview {
      ScrollView {
          ForecastInsightCard(subscriptionTier: .premium)
              .padding()
              .environmentObject(AppState()) // Ensure AppState is provided
              .environmentObject(DatabaseService()) // Ensure DatabaseService is provided
              .environmentObject(UIStyles.shared)
              .environmentObject(ThemeManager.shared)
      }
      .background(Color.gray.opacity(0.1))
 }