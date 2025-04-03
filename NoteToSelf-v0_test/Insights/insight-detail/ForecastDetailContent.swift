import SwiftUI
import Charts // Import Charts if needed for visualizations

// Placeholder Detail View
struct ForecastDetailContent: View {
    let forecastResult: ForecastResult? // Accept the optional result
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
         ScrollView { // Wrap content in ScrollView if it might exceed screen height
             VStack(alignment: .leading, spacing: styles.layout.spacingXL) { // Increased spacing
                 Text("Personalized Forecast")
                     .font(styles.typography.title1) // Title style
                     .foregroundColor(styles.colors.text)
                     .padding(.bottom) // Add padding below title

                 // --- Mood Prediction Section ---
                 VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     Text("Mood Prediction")
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)

                     // Display Mood Prediction
                     Text(forecastResult?.moodPredictionText ?? "Mood prediction currently unavailable.")
                         .font(styles.typography.bodyLarge) // Larger font for prediction
                         .foregroundColor(forecastResult?.moodPredictionText != nil ? styles.colors.text : styles.colors.textSecondary)
                         .frame(minHeight: 50, alignment: .leading) // Adjust height
                         .frame(maxWidth: .infinity, alignment: .leading)
                          .padding() // Add padding
                          .background(styles.colors.secondaryBackground.opacity(0.5))
                          .cornerRadius(styles.layout.radiusM)

                     // Optional: Placeholder for Mood Chart
                     // if let chartData = forecastResult?.moodChartData { ... }
                 }

                 // --- General Trends Section ---
                  VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                      Text("General Trends")
                          .font(styles.typography.title3)
                          .foregroundColor(styles.colors.text)

                      // Display Consistency Forecast
                      Text("Consistency: \(forecastResult?.consistencyForecast ?? "N/A")")
                           .font(styles.typography.bodyFont)
                           .foregroundColor(styles.colors.textSecondary)

                      // Display Emerging Topics
                      if let topics = forecastResult?.emergingTopics, !topics.isEmpty {
                          Text("Emerging Topics:")
                               .font(styles.typography.bodyLarge.weight(.semibold))
                               .foregroundColor(styles.colors.text)
                               .padding(.top, styles.layout.spacingS)
                          FlowLayout(spacing: 8) { // Use FlowLayout for topics
                               ForEach(topics, id: \.self) { topic in
                                   Text(topic)
                                        .font(styles.typography.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(styles.colors.tertiaryBackground)
                                        .cornerRadius(styles.layout.radiusM)
                                        .foregroundColor(styles.colors.text)
                               }
                           }
                      } else {
                           Text("No specific topic trends identified recently.")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                      }
                  }
                  .padding() // Add padding around section
                  .background(styles.colors.secondaryBackground.opacity(0.5))
                  .cornerRadius(styles.layout.radiusM)


                 // --- Preemptive Action Plan Section ---
                  VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                      Text("Preemptive Action Plan")
                          .font(styles.typography.title3)
                          .foregroundColor(styles.colors.text)

                      if let items = forecastResult?.actionPlanItems, !items.isEmpty {
                          ForEach(items) { item in
                               VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                                   Text(item.title)
                                       .font(styles.typography.bodyLarge.weight(.semibold))
                                       .foregroundColor(styles.colors.accent)
                                   Text(item.description)
                                       .font(styles.typography.bodyFont)
                                       .foregroundColor(styles.colors.textSecondary)
                                   if let rationale = item.rationale, !rationale.isEmpty {
                                       Text("Rationale: \(rationale)")
                                           .font(styles.typography.caption.italic())
                                           .foregroundColor(styles.colors.textSecondary.opacity(0.8))
                                   }
                               }
                               .padding(.bottom, styles.layout.spacingS)
                                // Add divider between items if needed
                                if item.id != items.last?.id {
                                    Divider().background(styles.colors.divider.opacity(0.5)).padding(.vertical, styles.layout.spacingS)
                                }
                          }
                      } else {
                           Text("No specific actions suggested based on the current forecast.")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                      }
                  }
                  .padding() // Add padding around section
                  .background(styles.colors.secondaryBackground.opacity(0.5))
                  .cornerRadius(styles.layout.radiusM)


                  Spacer() // Push content up

                  Text("Forecasts are based on recent trends and may not be perfectly accurate. Use them as a guide for reflection and planning.")
                     .font(styles.typography.caption)
                     .foregroundColor(styles.colors.textSecondary)
                     .multilineTextAlignment(.center)
                     .padding(.top) // Add padding above disclaimer
             } // End VStack
         } // End ScrollView
        .padding(styles.layout.paddingL) // Add padding to the outer VStack
    }
}

#Preview {
     let mockAction = ForecastResult.ActionPlanItem(
         title: "Schedule Downtime",
         description: "Block 30 minutes for quiet relaxation tomorrow evening.",
         rationale: "To balance anticipated busy period."
     )
     let mockResult = ForecastResult(
         moodPredictionText: "Generally stable, slight stress possible.",
         emergingTopics: ["Project X", "Weekend Trip"],
         consistencyForecast: "Likely consistent",
         actionPlanItems: [mockAction]
     )

    return ForecastDetailContent(forecastResult: mockResult)
         .padding()
         .environmentObject(UIStyles.shared)
         .environmentObject(ThemeManager.shared)
}