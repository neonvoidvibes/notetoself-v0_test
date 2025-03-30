import SwiftUI

struct RecommendationsInsightCard: View {
    // Input: Stored insight result and generation date
    let recommendationResult: RecommendationResult?
    let generatedDate: Date? // Keep track of when it was generated

    @State private var isExpanded: Bool = false
    private let styles = UIStyles.shared

    // Access subscription tier from environment
    @EnvironmentObject var appState: AppState
    private var subscriptionTier: SubscriptionTier {
        appState.subscriptionTier
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
        styles.expandableCard(
            isExpanded: $isExpanded,
            content: {
                // Preview content
                ZStack {
                    VStack(spacing: styles.layout.spacingM) {
                        HStack {
                            Text("Recommendations")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)
                            Spacer()
                        }

                        // Show recommendations if available and subscribed
                        if subscriptionTier == .premium {
                            if let recommendations = recommendationResult?.recommendations, !recommendations.isEmpty {
                                // Show first 1 or 2 recommendations in preview
                                ForEach(recommendations.prefix(2)) { rec in
                                    RecommendationRow(recommendation: rec, iconName: iconForCategory(rec.category))
                                    if rec.id != recommendations.prefix(2).last?.id {
                                         Divider().background(styles.colors.tertiaryBackground.opacity(0.5))
                                    }
                                }
                                if recommendations.count > 2 {
                                     Text("+\(recommendations.count - 2) more insights...")
                                         .font(styles.typography.caption)
                                         .foregroundColor(styles.colors.textSecondary)
                                         .frame(maxWidth: .infinity, alignment: .trailing)
                                         .padding(.top, 4)
                                }

                            } else {
                                Text("Personalized recommendations are being generated or not available yet.")
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .center) // Placeholder height
                            }
                        } else {
                             // Free tier preview
                             Text("Unlock personalized recommendations with Premium.")
                                 .font(styles.typography.bodyFont)
                                 .foregroundColor(styles.colors.textSecondary)
                                 .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
                        }
                    } // End VStack

                    // Lock overlay for free users
                    if subscriptionTier == .free {
                         VStack {
                             Spacer()
                             LinearGradient(
                                 gradient: Gradient(colors: [styles.colors.surface.opacity(0), styles.colors.surface.opacity(0.8)]),
                                 startPoint: .top,
                                 endPoint: .bottom
                             )
                             .frame(height: 80)
                             .overlay(
                                 VStack {
                                     Spacer()
                                     Image(systemName: "lock.fill")
                                         .font(.title)
                                         .foregroundColor(styles.colors.accent)
                                         .padding(.bottom)
                                 }
                             )
                         }
                         .allowsHitTesting(false)
                    }
                } // End ZStack
            },
            detailContent: {
                // Expanded detail content (only shown if premium)
                if subscriptionTier == .premium {
                    if let recommendations = recommendationResult?.recommendations, !recommendations.isEmpty {
                        VStack(spacing: styles.layout.spacingL) {
                            // Introduction
                            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                Text("Personalized Recommendations")
                                    .font(styles.typography.title3)
                                    .foregroundColor(styles.colors.text)

                                Text("Based on your recent journal entries, here are some suggestions that might support your well-being:")
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            // All recommendations with details
                            VStack(alignment: .leading, spacing: styles.layout.spacingL) { // Increased spacing
                                ForEach(recommendations) { recommendation in
                                    VStack(alignment: .leading, spacing: 12) { // Increased spacing
                                        // Title and Icon
                                        HStack {
                                            Image(systemName: iconForCategory(recommendation.category))
                                                .foregroundColor(styles.colors.accent)
                                                .font(.system(size: 20))
                                                .frame(width: 24, height: 24)

                                            Text(recommendation.title)
                                                .font(styles.typography.bodyLarge.weight(.semibold)) // Bolder title
                                                .foregroundColor(styles.colors.text)
                                        }

                                        // Description
                                        Text(recommendation.description)
                                            .font(styles.typography.bodyFont)
                                            .foregroundColor(styles.colors.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)


                                        // Rationale
                                        Text("Rationale: \(recommendation.rationale)")
                                            .font(styles.typography.caption.italic()) // Italic rationale
                                            .foregroundColor(styles.colors.textSecondary.opacity(0.8))
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.top, 4)

                                         if recommendation.id != recommendations.last?.id {
                                             Divider().background(styles.colors.tertiaryBackground.opacity(0.5)).padding(.top, 8)
                                         }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }

                            // Disclaimer
                            Text("These recommendations are AI-generated based on patterns and are not a substitute for professional advice.")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)

                             // Generation Date
                             if let date = generatedDate {
                                 // Corrected: .shortened
                                 Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                                     .font(styles.typography.caption)
                                     .foregroundColor(styles.colors.textSecondary)
                                     .frame(maxWidth: .infinity, alignment: .center)
                                     .padding(.top)
                             }
                        }
                    } else {
                        Text("Personalized recommendations are not available yet. Keep journaling!")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    // Free tier expanded view
                    VStack(spacing: styles.layout.spacingL) {
                         Image(systemName: "lock.fill")
                             .font(.system(size: 40))
                             .foregroundColor(styles.colors.accent)
                         Text("Unlock Recommendations")
                             .font(styles.typography.title3)
                             .foregroundColor(styles.colors.text)
                         Text("Upgrade to Premium to receive personalized recommendations based on your journal entries.")
                              .font(styles.typography.bodyFont)
                              .foregroundColor(styles.colors.textSecondary)
                              .multilineTextAlignment(.center)
                         Button("Upgrade Now") {
                             // TODO: Trigger upgrade flow
                         }
                         .buttonStyle(GlowingButtonStyle(colors: styles.colors, typography: styles.typography, layout: styles.layout))
                         .padding(.top)
                    }
                }
            } // End detailContent
        ) // End expandableCard
    } // End body
}

// Simplified RecommendationRow for preview
struct RecommendationRow: View {
    let recommendation: RecommendationResult.RecommendationItem // Use nested type
    let iconName: String
    private let styles = UIStyles.shared

    var body: some View {
        HStack(alignment: .top, spacing: styles.layout.spacingM) {
            // Icon
            ZStack {
                Circle()
                    .fill(styles.colors.tertiaryBackground)
                    .frame(width: 40, height: 40)

                Image(systemName: iconName)
                    .foregroundColor(styles.colors.accent)
                    .font(.system(size: 18))
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(styles.typography.insightCaption)
                    .foregroundColor(styles.colors.text)

                Text(recommendation.description)
                    .font(styles.typography.bodySmall) // Smaller font for preview
                    .foregroundColor(styles.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2) // Limit lines in preview
            }
            Spacer() // Push content to left
        }
    }
}