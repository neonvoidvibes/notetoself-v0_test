import SwiftUI

struct ActDetailContent: View {
    let result: ActInsightResult
    let generatedDate: Date?
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: styles.layout.spacingXL) {

                // --- Action Forecast Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     // Use accent color for sub-header
                    Text("Action Forecast")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.accent) // Accent color for sub-header

                    Text(result.actionForecastText ?? "Forecast based on recent actions will appear here.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(styles.layout.spacingXS) // Add line spacing
                }
                .padding()
                .background(styles.colors.secondaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)

                // --- Personalized Recommendations Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     // Use accent color for sub-header
                    Text("Personalized Recommendations")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.accent) // Accent color for sub-header

                    if let recommendations = result.personalizedRecommendations, !recommendations.isEmpty {
                        // Use VStack instead of ForEach directly to apply background/padding to the section
                         VStack(spacing: styles.layout.spacingL) { // Spacing between recommendation cards
                             ForEach(recommendations) { recommendation in
                                 RecommendationDetailCard(recommendation: recommendation)
                                     // No additional background/padding needed here, handled by the card itself
                             }
                         }
                    } else {
                        Text("No specific recommendations available currently. Keep journaling!")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                             .padding(.vertical) // Add padding if no recommendations
                    }
                }
                 // Apply styling to the entire recommendations section
                 .padding()
                 .background(styles.colors.secondaryBackground.opacity(0.5))
                 .cornerRadius(styles.layout.radiusM)


                Spacer(minLength: styles.layout.spacingXL)

                // Generated Date Timestamp
                if let date = generatedDate {
                    HStack {
                        Spacer()
                        Image(systemName: "clock")
                            .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                            .font(.system(size: 12))
                        Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .padding(.bottom, styles.layout.paddingL)
        }
    }
}

#Preview {
    let mockRecs = [
        RecommendationResult.RecommendationItem(id: UUID(), title: "Schedule 'Worry Time'", description: "Dedicate 15 minutes to acknowledge worries, then release them.", category: "Experiment", rationale: "To contain anxious thoughts."),
        RecommendationResult.RecommendationItem(id: UUID(), title: "Plan One Small Win", description: "Identify and complete one small, achievable task tomorrow morning.", category: "Planning", rationale: "To build momentum.")
    ]
    let mockResult = ActInsightResult(
        actionForecastText: "Preview: Maintaining the current pace without dedicated breaks might lead to reduced focus later in the week. There's an opportunity to experiment with structured pauses.",
        personalizedRecommendations: mockRecs
    )

    return InsightFullScreenView(title: "Act Insights") {
        ActDetailContent(result: mockResult, generatedDate: Date())
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
}