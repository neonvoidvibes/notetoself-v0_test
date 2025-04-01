import SwiftUI

struct RecommendationsInsightCard: View {
    // Input: Raw JSON string, generation date, and subscription status
    let jsonString: String?
    let generatedDate: Date?
    let subscriptionTier: SubscriptionTier

    // Local state for decoded result
    @State private var decodedRecommendations: RecommendationResult? = nil
    @State private var decodingError: Bool = false

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

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

    private var placeholderMessage: String {
        if jsonString == nil {
            return "Keep journaling (at least 3 entries needed) to receive personalized recommendations!"
        } else if decodedRecommendations == nil && !decodingError {
            return "Loading recommendations..."
        } else if decodingError {
            return "Could not load recommendations. Please try again later."
        } else {
            return "Recommendations are not available yet."
        }
    }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            scrollProxy: scrollProxy, // Pass proxy
            cardId: cardId,           // Pass ID
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Recommendations")
                            .font(styles.typography.title3).foregroundColor(styles.colors.text)
                        Spacer()
                         if subscriptionTier == .free {
                             Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                         }
                    }

                    // Show recommendations if available and subscribed
                    if subscriptionTier == .premium {
                        // Use decodedRecommendations for display
                        if let recommendations = decodedRecommendations?.recommendations, !recommendations.isEmpty {
                            ForEach(recommendations.prefix(2)) { rec in
                                RecommendationRow(recommendation: rec, iconName: iconForCategory(rec.category))
                                if rec.id != recommendations.prefix(2).last?.id {
                                     Divider().background(styles.colors.tertiaryBackground.opacity(0.5))
                                }
                            }
                            if recommendations.count > 2 {
                                 Text("+\(recommendations.count - 2) more...")
                                     .font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                                     .frame(maxWidth: .infinity, alignment: .trailing).padding(.top, 4)
                            }
                        } else {
                            // Premium user, but no decoded data yet or error
                             Text(placeholderMessage)
                                 .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                 .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
                                 .multilineTextAlignment(.center)
                                 if jsonString != nil && decodedRecommendations == nil && !decodingError {
                                     ProgressView().tint(styles.colors.accent).padding(.top, 4)
                                 }
                        }
                    } else {
                         // Free tier locked state
                         Text("Unlock personalized recommendations with Premium.")
                             .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                             .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
                             .multilineTextAlignment(.center)
                    }
                } // End VStack
            }, // End content closure
            detailContent: {
                // Expanded detail content (only shown if premium and data exists)
                if subscriptionTier == .premium {
                    if let recommendations = decodedRecommendations?.recommendations, !recommendations.isEmpty {
                         VStack(spacing: styles.layout.spacingL) {
                            // ... (Detailed content using 'recommendations' - unchanged from previous version) ...
                            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                Text("Personalized Recommendations")
                                    .font(styles.typography.title3).foregroundColor(styles.colors.text)
                                Text("Based on your recent journal entries, here are some suggestions:")
                                    .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                                ForEach(recommendations) { recommendation in
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: iconForCategory(recommendation.category))
                                                .foregroundColor(styles.colors.accent).font(.system(size: 20))
                                                .frame(width: 24, height: 24)
                                            Text(recommendation.title)
                                                .font(styles.typography.bodyLarge.weight(.semibold)).foregroundColor(styles.colors.text)
                                        }
                                        Text(recommendation.description)
                                            .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text("Rationale: \(recommendation.rationale)")
                                            .font(styles.typography.caption.italic()).foregroundColor(styles.colors.textSecondary.opacity(0.8))
                                            .fixedSize(horizontal: false, vertical: true).padding(.top, 4)
                                         if recommendation.id != recommendations.last?.id {
                                             Divider().background(styles.colors.tertiaryBackground.opacity(0.5)).padding(.top, 8)
                                         }
                                    }.padding(.vertical, 8)
                                }
                            }

                            Text("These recommendations are AI-generated based on patterns and are not a substitute for professional advice.")
                                .font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                                .multilineTextAlignment(.center).padding(.top, 8)

                             if let date = generatedDate {
                                 Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                                     .font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                                     .frame(maxWidth: .infinity, alignment: .center).padding(.top)
                             }
                        } // End VStack for detail content
                    } else {
                        // Premium, but no recommendations generated yet
                        Text("Personalized recommendations are not available yet. Keep journaling!")
                            .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    // Free tier expanded view
                    VStack(spacing: styles.layout.spacingL) {
                         Image(systemName: "lock.fill").font(.system(size: 40)).foregroundColor(styles.colors.accent)
                         Text("Upgrade for Recommendations").font(styles.typography.title3).foregroundColor(styles.colors.text)
                         Text("Unlock personalized recommendations based on your journal entries with Premium.")
                              .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary).multilineTextAlignment(.center)
                          // Optional Upgrade Button
                          Button("Upgrade Now") { /* TODO: Trigger upgrade flow */ }
                          .buttonStyle(GlowingButtonStyle()) // Remove arguments
                          .padding(.top)
                     }
                 }
            } // End detailContent
        ) // End expandableCard
        // Add the onChange modifier to decode the JSON string
        .onChange(of: jsonString) { oldValue, newValue in
             decodeJSON(json: newValue)
        }
        // Decode initially as well
        .onAppear {
            decodeJSON(json: jsonString)
        }
    } // End body

    // Decoding function
    private func decodeJSON(json: String?) {
        guard let json = json, !json.isEmpty else {
            if decodedRecommendations != nil { decodedRecommendations = nil }
            decodingError = false
            return
        }
        decodingError = false
        guard let data = json.data(using: .utf8) else {
            print("⚠️ [RecommendationsCard] Failed to convert JSON string to Data.")
            if decodedRecommendations != nil { decodedRecommendations = nil }
            decodingError = true
            return
        }
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(RecommendationResult.self, from: data)
            // Update state only if decoded data is different
            if result != decodedRecommendations {
                 decodedRecommendations = result
                 print("[RecommendationsCard] Successfully decoded new recommendations.")
            }
        } catch {
            print("‼️ [RecommendationsCard] Failed to decode RecommendationResult: \(error). JSON: \(json)")
            if decodedRecommendations != nil { decodedRecommendations = nil }
            decodingError = true
        }
    }
}

// Simplified RecommendationRow for preview
struct RecommendationRow: View {
    let recommendation: RecommendationResult.RecommendationItem
    let iconName: String
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    var body: some View {
        HStack(alignment: .top, spacing: styles.layout.spacingM) {
            ZStack { // Icon
                Circle().fill(styles.colors.tertiaryBackground).frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .foregroundColor(styles.colors.accent)
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 4) { // Content
                Text(recommendation.title)
                    .font(styles.typography.insightCaption)
                    .foregroundColor(styles.colors.text)
                Text(recommendation.description)
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
