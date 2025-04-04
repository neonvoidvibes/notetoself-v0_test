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
    @ObservedObject private var styles = UIStyles.shared

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
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: 1-2 snippets, helping text
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     HStack {
                         Text("Suggested Actions") // Updated Title
                             .font(styles.typography.title3).foregroundColor(styles.colors.text)
                         Spacer()
                          if subscriptionTier == .free {
                              Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                          }
                     }

                    if subscriptionTier == .premium {
                        if let recommendations = decodedRecommendations?.recommendations, !recommendations.isEmpty {
                            // Show 1 or 2 snippets
                            VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                                ForEach(recommendations.prefix(2)) { rec in
                                    HStack(spacing: styles.layout.spacingS) {
                                        Image(systemName: iconForCategory(rec.category))
                                            .foregroundColor(styles.colors.accent)
                                            .frame(width: 20, alignment: .center)
                                        Text(rec.title) // Show title as snippet
                                            .font(styles.typography.bodyFont)
                                            .foregroundColor(styles.colors.text)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.bottom, styles.layout.spacingS)

                            Text("Personalized tips just for you—tap for more details.") // Helping text
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.accent)
                        } else {
                            // Premium user, but no decoded data yet or error
                             Text(placeholderMessage)
                                 .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                 .frame(maxWidth: .infinity, minHeight: 60, alignment: .center) // Adjusted height
                                 .multilineTextAlignment(.center)
                                 if jsonString != nil && decodedRecommendations == nil && !decodingError {
                                     ProgressView().tint(styles.colors.accent).padding(.top, 4)
                                 }
                        }
                    } else {
                        // Free tier locked state
                         Text("Unlock personalized recommendations with Premium.")
                             .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                             .frame(maxWidth: .infinity, minHeight: 60, alignment: .center) // Adjusted height
                             .multilineTextAlignment(.center)
                    }
                }
            },
            detailContent: {
                // Expanded View: Use RecommendationsDetailContent (unchanged for now)
                if subscriptionTier == .premium {
                    if let recommendations = decodedRecommendations?.recommendations, !recommendations.isEmpty {
                        // Pass the array directly to the detail view
                        RecommendationsDetailContent(recommendations: recommendations)
                         // Add generation date if available
                         if let date = generatedDate {
                             Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                                 .font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                                 .frame(maxWidth: .infinity, alignment: .center).padding(.top)
                         }
                    } else {
                         // Premium, but no recommendations
                         Text("Personalized recommendations are not available yet. Keep journaling!")
                             .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                             .frame(maxWidth: .infinity, alignment: .center).padding()
                    }
                } else {
                    // Free tier expanded view
                    VStack(spacing: styles.layout.spacingL) {
                         Image(systemName: "lock.fill").font(.system(size: 40)).foregroundColor(styles.colors.accent)
                         Text("Upgrade for Recommendations").font(styles.typography.title3).foregroundColor(styles.colors.text)
                         Text("Unlock personalized recommendations based on your journal entries with Premium.")
                              .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary).multilineTextAlignment(.center)
                          Button { /* TODO: Trigger upgrade flow */ } label: {
                              Text("Upgrade Now").foregroundColor(styles.colors.primaryButtonText)
                          }.buttonStyle(GlowingButtonStyle())
                           .padding(.top)
                     }.padding() // Add padding to the Vstack
                 }
            }
        )
        .onChange(of: jsonString) { oldValue, newValue in
             decodeJSON(json: newValue)
        }
        .onAppear {
            decodeJSON(json: jsonString)
        }
    }

    // Decoding function (remains the same)
    private func decodeJSON(json: String?) {
        guard let json = json, !json.isEmpty else {
            decodedRecommendations = nil; decodingError = false; return
        }
        decodingError = false
        guard let data = json.data(using: .utf8) else {
            print("⚠️ [RecommendationsCard] Failed convert JSON string to Data."); decodingError = true; decodedRecommendations = nil; return
        }
        do {
            let result = try JSONDecoder().decode(RecommendationResult.self, from: data)
            if result != decodedRecommendations { decodedRecommendations = result; print("[RecommendationsCard] Decoded new recommendations.") }
        } catch {
            print("‼️ [RecommendationsCard] Failed decode RecommendationResult: \(error). JSON: \(json)"); decodingError = true; decodedRecommendations = nil
        }
    }
}

#Preview {
    // Example RecommendationResult for preview
    let previewRecs = RecommendationResult(recommendations: [
        .init(title: "5-Minute Mindfulness", description: "Take a short break to focus on your breath.", category: "Mindfulness", rationale: "Helps calm the mind based on recent stress indicators."),
        .init(title: "Quick Walk Outside", description: "Get some fresh air and light movement.", category: "Activity", rationale: "Can boost mood and energy levels when feeling low.")
    ])
    let encoder = JSONEncoder()
    let data = try? encoder.encode(previewRecs)
    let jsonString = String(data: data ?? Data(), encoding: .utf8)

    return ScrollView {
        RecommendationsInsightCard(jsonString: jsonString, generatedDate: Date(), subscriptionTier: .premium)
            .padding()
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}