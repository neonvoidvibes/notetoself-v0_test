import SwiftUI

struct RecommendationsDetailContent: View {
    let recommendations: [RecommendationResult.RecommendationItem] // Use nested type
    let generatedDate: Date? // Accept date
    // Ensure styles are observed if passed down or used globally
    @ObservedObject private var styles = UIStyles.shared

     // Add explicit init if needed to ensure parameters are set, though memberwise should work
     init(recommendations: [RecommendationResult.RecommendationItem], generatedDate: Date?) {
         self.recommendations = recommendations
         self.generatedDate = generatedDate
     }

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
            VStack(alignment: .leading, spacing: styles.layout.spacingXL) { // Keep XL spacing

                 Text("Based on your journal entries, here are some suggestions to help support your well-being.") // Simplified text
                     .font(styles.typography.bodyFont)
                     .foregroundColor(styles.colors.textSecondary)
                     .padding(.bottom, styles.layout.spacingS) // Add slight padding below intro


                // Recommendations List - Each recommendation is now a styled section
                if recommendations.isEmpty {
                     VStack { // Wrap placeholder in styled section
                          Text("No recommendations available at this time. Keep journaling!")
                              .font(styles.typography.bodyFont)
                              .foregroundColor(styles.colors.textSecondary)
                     }
                      .padding()
                      .frame(maxWidth: .infinity) // Ensure it takes width
                      .background(styles.colors.secondaryBackground.opacity(0.5))
                      .cornerRadius(styles.layout.radiusM)

                } else {
                      ForEach(recommendations) { recommendation in
                          // Apply section styling to each RecommendationDetailCard directly
                          RecommendationDetailCard(recommendation: recommendation)
                               // These modifiers are now inside RecommendationDetailCard
                               // .padding()
                               // .background(styles.colors.secondaryBackground.opacity(0.5))
                               // .cornerRadius(styles.layout.radiusM)
                      }
                }

                // Removed Additional Resources section for now

                 Text("These recommendations are AI-generated based on patterns and are not a substitute for professional advice.")
                     .font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                     .multilineTextAlignment(.center).padding(.top, styles.layout.spacingL) // Increased spacing before disclaimer

                 Spacer(minLength: styles.layout.spacingXL) // Add spacer before timestamp

                 // Generated Date Timestamp (Outside styled sections)
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
            }
             .padding(.bottom, styles.layout.paddingL) // Add bottom padding for scroll breathing room
        } // End ScrollView
    } // End body
} // End struct

// RecommendationDetailCard now incorporates the section styling
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
        .padding() // Apply styling to the VStack (section container)
        .background(styles.colors.secondaryBackground.opacity(0.5))
        .cornerRadius(styles.layout.radiusM)
        // Removed shadow from here, card container has shadow
    }
}

// ResourceLink remains the same if used (Keep commented out for now)
/*
struct ResourceLink: View { ... }
*/

#Preview {
     // Correctly create mock data
     let previewRecs = [
         RecommendationResult.RecommendationItem(id: UUID(), title: "Preview Rec 1", description: "Description for preview 1.", category: "Mindfulness", rationale: "Rationale preview 1."),
         RecommendationResult.RecommendationItem(id: UUID(), title: "Preview Rec 2", description: "Description for preview 2.", category: "Activity", rationale: "Rationale preview 2.")
     ]
      // Wrap in InsightFullScreenView for accurate preview of padding/layout
      return InsightFullScreenView(title: "Suggested Actions") {
          RecommendationsDetailContent(
              recommendations: previewRecs,
              generatedDate: Date() // Pass date
          )
      }
     .environmentObject(UIStyles.shared)
     .environmentObject(ThemeManager.shared)
 }