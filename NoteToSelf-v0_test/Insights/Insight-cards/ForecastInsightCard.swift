import SwiftUI

// New card for Predictive Mood & General Forecast
struct ForecastInsightCard: View {
    // Input: Requires a dedicated ForecastResult Codable struct (to be defined)
    // let forecastResult: ForecastResult? // Placeholder
    let subscriptionTier: SubscriptionTier

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    @ObservedObject private var styles = UIStyles.shared
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService

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
             components.append("Consistency: \(consistency.prefix(20))...")
        }
        if components.isEmpty {
             return "Future insights ready."
        }
        return components.joined(separator: "; ")
    }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: Icon, Quick Prediction Label, Helping Text
                HStack(spacing: styles.layout.spacingM) {
                    // Futuristic Icon
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill") // Example icon
                        .font(.system(size: 40))
                        .foregroundColor(styles.colors.accent)

                    // Prediction Label & Helping Text
                    VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                         Text("Future Forecast") // Clearer title
                            .font(styles.typography.smallLabelFont)
                            .foregroundColor(styles.colors.textSecondary)

                        if subscriptionTier == .premium {
                            // Show dynamic label
                            Text(forecastLabel) // Use computed property
                                .font(styles.typography.bodyFont)
                                .foregroundColor(loadError ? styles.colors.error : styles.colors.text) // Indicate error
                                .lineLimit(1)

                            Text("Tap to see your personalized forecast and plan ahead.") // Helping text
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.accent)
                        } else {
                             Text("Unlock predictive insights with Premium.")
                                 .font(styles.typography.bodyFont)
                                 .foregroundColor(styles.colors.textSecondary)
                                 .lineLimit(2)
                        }
                    }
                    Spacer() // Push content left
                }
                 .padding(.vertical, styles.layout.paddingS) // Add vertical padding
            },
            detailContent: {
                // Expanded View: Use ForecastDetailContent
                if subscriptionTier == .premium {
                    // Pass forecastResult
                    ForecastDetailContent(forecastResult: forecastResult)
                } else {
                     // Free tier expanded state
                     VStack(spacing: styles.layout.spacingL) {
                         Image(systemName: "lock.fill").font(.system(size: 40)).foregroundColor(styles.colors.accent)
                         Text("Upgrade for Forecasts").font(styles.typography.title3).foregroundColor(styles.colors.text)
                         Text("Unlock predictive mood and trend forecasts with Premium.")
                              .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary).multilineTextAlignment(.center)
                         Button { /* TODO: Trigger upgrade flow */ } label: {
                             Text("Upgrade Now").foregroundColor(styles.colors.primaryButtonText)
                         }.buttonStyle(GlowingButtonStyle())
                          .padding(.top)
                     }.padding()
                 }
            }
        )
         // Add loading logic
         .onAppear(perform: loadInsight)
         .onChange(of: appState.journalEntries.count) { _, _ in loadInsight() } // Reload on entry change
          // Add listener for explicit insight updates
          .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
              print("[ForecastCard] Received insightsDidUpdate notification.")
              loadInsight()
          }
    }

     // Function to load and decode the insight
     private func loadInsight() {
         guard !isLoading else { return }
         isLoading = true
         loadError = false
         print("[ForecastCard] Loading insight...")

         Task {
             do {
                 if let (json, _) = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
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
}

#Preview {
     ScrollView {
         ForecastInsightCard(subscriptionTier: .premium)
             .padding()
             .environmentObject(UIStyles.shared)
             .environmentObject(ThemeManager.shared)
     }
     .background(Color.gray.opacity(0.1))
}