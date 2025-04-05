import SwiftUI
import Charts // Import Charts if needed for visualizations

// Placeholder Detail View
struct ForecastDetailContent: View {
    let forecastResult: ForecastResult? // Ensure this parameter is present
    let generatedDate: Date? // Accept date
     // Ensure styles are observed if passed down or used globally
     @ObservedObject private var styles = UIStyles.shared

    // Explicitly define init if needed, though memberwise should work
    init(forecastResult: ForecastResult?, generatedDate: Date?) {
         self.forecastResult = forecastResult
         self.generatedDate = generatedDate
    }

    var body: some View {
         ScrollView { // Wrap content in ScrollView if it might exceed screen height
             VStack(alignment: .leading, spacing: styles.layout.spacingXL) { // Ensure XL spacing

                 // --- Mood Prediction Section ---
                 VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     Text("Mood Prediction")
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)
                          // No bottom padding needed here, handled by VStack spacing

                     // Display Mood Prediction text
                     Text(forecastResult?.moodPredictionText ?? "Mood prediction currently unavailable.")
                         .font(styles.typography.bodyLarge) // Larger font for prediction
                         .foregroundColor(forecastResult?.moodPredictionText != nil ? styles.colors.text : styles.colors.textSecondary)
                         .frame(maxWidth: .infinity, alignment: .leading) // Ensure text takes width

                 }
                  // Apply padding, background, cornerRadius to the VStack itself
                  .padding()
                  .background(styles.colors.secondaryBackground.opacity(0.5))
                  .cornerRadius(styles.layout.radiusM)


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
                     .padding(.top, styles.layout.spacingL) // Increased padding

                 Spacer(minLength: styles.layout.spacingXL) // Add spacer before timestamp

                  // Generated Date Timestamp
                   if let date = generatedDate {
                       HStack {
                           Spacer() // Center align
                           Image(systemName: "clock")
                               .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                               .font(.system(size: 12))
                           Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                               .font(styles.typography.caption)
                               .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                           Spacer()
                       }
                       .padding(.top) // Padding above timestamp
                   }

             } // End VStack
             .padding(.bottom, styles.layout.paddingL) // Bottom padding inside scrollview
         } // End ScrollView
    } // End body
} // End struct

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

      // Wrap in InsightFullScreenView for accurate preview of padding/layout
      return InsightFullScreenView(title: "Future Forecast") {
          ForecastDetailContent(forecastResult: mockResult, generatedDate: Date()) // Pass date
      }
     .environmentObject(UIStyles.shared)
     .environmentObject(ThemeManager.shared)
}