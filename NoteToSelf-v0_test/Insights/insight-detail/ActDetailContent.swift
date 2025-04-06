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
                                 // Use the locally defined private struct
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

    // --- Private Recommendation Detail Card View ---
    // Recreated from the deleted RecommendationsDetailContent.swift
    private struct RecommendationDetailCard: View {
        let recommendation: RecommendationResult.RecommendationItem // Use nested type
        @ObservedObject private var styles = UIStyles.shared // Use ObservedObject

         // Helper to get icon based on category string (duplicated for local use)
          private func iconForCategory(_ category: String) -> String {
              switch category.lowercased() {
              case "mindfulness": return "brain.head.profile"
              case "activity": return "figure.walk"
              case "social": return "person.2.fill"
              case "self-care": return "heart.fill"
              case "reflection": return "text.book.closed.fill"
              default: return "star.fill"
              }
          }

        var body: some View {
            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                // Header
                HStack(spacing: styles.layout.spacingM) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(styles.colors.accent.opacity(0.1)) // Lighter accent background
                            .frame(width: 48, height: 48)

                        Image(systemName: iconForCategory(recommendation.category)) // Use helper
                            .foregroundColor(styles.colors.accent) // Use accent color
                            .font(.system(size: 24))
                    }

                    Text(recommendation.title)
                        .font(styles.typography.title3) // Use Title3
                        .foregroundColor(styles.colors.text)
                }

                // Description
                Text(recommendation.description)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Rationale
                if let rationale = recommendation.rationale, !rationale.isEmpty {
                     VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                         Text("Why this might help:") // Friendlier label
                             .font(styles.typography.bodyLarge.weight(.semibold)) // Use BodyLarge
                             .foregroundColor(styles.colors.text)

                         Text(rationale)
                             .font(styles.typography.bodyFont)
                             .foregroundColor(styles.colors.textSecondary)
                             .fixedSize(horizontal: false, vertical: true) // Allow wrapping
                     }
                     .padding(.top, styles.layout.spacingS)
                }
            }
            // Apply styling that used to be applied externally
            .padding()
            .background(styles.colors.secondaryBackground.opacity(0.5)) // Apply sub-section bg
            .cornerRadius(styles.layout.radiusM)
        }
    }
} // End ActDetailContent

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