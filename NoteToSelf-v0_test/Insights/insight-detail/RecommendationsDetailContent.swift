import SwiftUI

struct RecommendationsDetailContent: View {
    let recommendations: [RecommendationResult.RecommendationItem] // Use nested type
    private let styles = UIStyles.shared

    // Helper to get icon based on category string
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
        ScrollView {
            VStack(spacing: styles.layout.spacingXL) {
                // Introduction
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Personalized Recommendations")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)

                    Text("Based on your journal entries, we've created these personalized recommendations to help support your well-being. These suggestions are grounded in behavioral science and positive psychology principles.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                }

                // Recommendations
                VStack(spacing: styles.layout.spacingL) {
                    ForEach(recommendations) { recommendation in // Use RecommendationResult.RecommendationItem
                        RecommendationDetailCard(recommendation: recommendation)
                    }
                }

                // Additional resources
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Additional Resources")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)

                    ResourceLink(
                        title: "Mindfulness Practices",
                        description: "Simple mindfulness exercises to reduce stress and increase present-moment awareness.",
                        icon: "brain.head.profile"
                    )

                    ResourceLink(
                        title: "Sleep Hygiene Guide",
                        description: "Evidence-based tips for improving your sleep quality and duration.",
                        icon: "bed.double.fill"
                    )

                    ResourceLink(
                        title: "Mood-Boosting Activities",
                        description: "A curated list of activities scientifically shown to improve mood and well-being.",
                        icon: "heart.fill"
                    )
                }
            }
            .padding(styles.layout.paddingXL)
        }
    }
}

struct RecommendationDetailCard: View {
    let recommendation: RecommendationResult.RecommendationItem // Use nested type
    private let styles = UIStyles.shared

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
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    styles.colors.accent,
                                    styles.colors.accent.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: iconForCategory(recommendation.category)) // Use helper
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }

                Text(recommendation.title)
                    .font(styles.typography.title3)
                    .foregroundColor(styles.colors.text)
            }

            // Description
            Text(recommendation.description)
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Why it works
            VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                Text("Why It Works")
                    .font(styles.typography.bodyLarge)
                    .foregroundColor(styles.colors.text)

                Text(recommendation.rationale) // Use rationale from model
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
            }
            .padding(.top, styles.layout.spacingS)

            // How to implement (Could be added to RecommendationItem if needed)
            /*
            VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                Text("How to Implement")
                    .font(styles.typography.bodyLarge)
                    .foregroundColor(styles.colors.text)

                VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                    ForEach(generateImplementationSteps(for: recommendation), id: \.self) { step in
                        HStack(alignment: .top, spacing: styles.layout.spacingS) {
                            Text("•")
                                .foregroundColor(styles.colors.accent)

                            Text(step)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                        }
                    }
                }
            }
            .padding(.top, styles.layout.spacingS)
            */
        }
        .padding(styles.layout.paddingL)
        .background(
            RoundedRectangle(cornerRadius: styles.layout.radiusL)
                .fill(styles.colors.secondaryBackground)
        )
    }

    // Removed local helper functions for rationale/steps as they should come from the model
}

struct ResourceLink: View {
    let title: String
    let description: String
    let icon: String
    private let styles = UIStyles.shared

    var body: some View {
        Button(action: {
            // In a real app, this would open the resource
            // Example: guard let url = URL(string: "...") else { return }; openURL(url)
        }) {
            HStack(alignment: .top, spacing: styles.layout.spacingM) {
                // Icon
                Image(systemName: icon)
                    .foregroundColor(styles.colors.accent)
                    .font(.system(size: 20))
                    .frame(width: 24)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(styles.typography.bodyLarge)
                        .foregroundColor(styles.colors.text)

                    Text(description)
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(styles.colors.accent)
                    .font(.system(size: 14))
            }
            .padding(styles.layout.paddingM)
            .background(
                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                    .fill(styles.colors.tertiaryBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}