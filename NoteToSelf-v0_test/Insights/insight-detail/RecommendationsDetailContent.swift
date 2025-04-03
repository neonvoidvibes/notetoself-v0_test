import SwiftUI

struct RecommendationsDetailContent: View {
    let recommendations: [RecommendationResult.RecommendationItem] // Use nested type
    @ObservedObject private var styles = UIStyles.shared // Use ObservedObject

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
                        .font(styles.typography.title3) // Use Title3
                        .foregroundColor(styles.colors.text)

                    Text("Based on your journal entries, here are some suggestions to help support your well-being.") // Simplified text
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                }

                // Recommendations List
                if recommendations.isEmpty {
                     Text("No recommendations available at this time. Keep journaling!")
                         .font(styles.typography.bodyFont)
                         .foregroundColor(styles.colors.textSecondary)
                         .padding(.vertical, 40)
                } else {
                     VStack(spacing: styles.layout.spacingL) {
                         ForEach(recommendations) { recommendation in
                             RecommendationDetailCard(recommendation: recommendation)
                         }
                     }
                }


                // Additional resources (Consider making this conditional or removing if too cluttered)
                /*
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Additional Resources")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)

                    ResourceLink(
                        title: "Mindfulness Practices",
                        description: "Simple mindfulness exercises to reduce stress.",
                        icon: "brain.head.profile"
                    )
                     ResourceLink(
                         title: "Sleep Hygiene Guide",
                         description: "Evidence-based tips for improving sleep quality.",
                         icon: "bed.double.fill"
                     )
                }
                .padding(.top) // Add padding if resources are shown
                */

                 Text("These recommendations are AI-generated based on patterns and are not a substitute for professional advice.")
                     .font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                     .multilineTextAlignment(.center).padding(.top, 8)

            }
            .padding(styles.layout.paddingXL) // Add padding to the outer VStack
        }
    }
}

struct RecommendationDetailCard: View {
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
        .padding(styles.layout.paddingL)
        .background(styles.colors.secondaryBackground) // Use secondary background
        .cornerRadius(styles.layout.radiusL)
         .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) // Softer shadow
    }
}

// ResourceLink remains the same if used
struct ResourceLink: View {
    let title: String
    let description: String
    let icon: String
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        Button(action: { /* Open resource */ }) {
            HStack(alignment: .top, spacing: styles.layout.spacingM) {
                Image(systemName: icon)
                    .foregroundColor(styles.colors.accent)
                    .font(.system(size: 20)).frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(styles.typography.bodyLarge).foregroundColor(styles.colors.text)
                    Text(description).font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(styles.colors.accent).font(.system(size: 14))
            }
            .padding(styles.layout.paddingM)
            .background(styles.colors.tertiaryBackground)
            .cornerRadius(styles.layout.radiusM)
        }.buttonStyle(PlainButtonStyle())
    }
}

#Preview {
     let previewRecs = [
         RecommendationResult.RecommendationItem(title: "Preview Rec 1", description: "Description for preview 1.", category: "Mindfulness", rationale: "Rationale preview 1."),
         RecommendationResult.RecommendationItem(title: "Preview Rec 2", description: "Description for preview 2.", category: "Activity", rationale: "Rationale preview 2.")
     ]
     return RecommendationsDetailContent(recommendations: previewRecs)
         .padding()
         .environmentObject(UIStyles.shared)
         .environmentObject(ThemeManager.shared)
}