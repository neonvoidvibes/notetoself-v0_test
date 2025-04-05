import SwiftUI

struct RecommendationsInsightCard: View {
    // Input: Raw JSON string, generation date, and subscription status
    let jsonString: String?
    let generatedDate: Date?
    let subscriptionTier: SubscriptionTier

    // Local state for decoded result
    @State private var decodedRecommendations: RecommendationResult? = nil
    @State private var decodingError: Bool = false
    @State private var isLoading: Bool = false
    // Note: generatedDate is passed in, no need for @State here

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false // State for full screen presentation
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService

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
        } else if decodedRecommendations == nil && !decodingError && isLoading { // Show loading only when actually loading
            return "Loading recommendations..."
        } else if decodingError {
            return "Could not load recommendations. Please try again later."
        } else if decodedRecommendations == nil && !isLoading { // No data loaded, not loading, no error
             return "Recommendations are not available yet."
        } else {
            return "" // Should have data if no other condition met
        }
    }


    var body: some View {
        styles.expandableCard( // Removed isExpanded
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: 1-2 snippets, helping text
                VStack(alignment: .leading, spacing: styles.layout.spacingL) { // Increased spacing
                     HStack {
                         Text("Suggested Actions") // Updated Title
                             .font(styles.typography.title3).foregroundColor(styles.colors.text) // Revert to title3
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
                             // Premium user, loading, error or no data state
                             HStack { // Use HStack to center ProgressView if shown
                                 Text(placeholderMessage)
                                     .font(styles.typography.bodyFont).foregroundColor(decodingError ? styles.colors.error : styles.colors.textSecondary)
                                     .frame(maxWidth: .infinity, alignment: .leading)
                                     .multilineTextAlignment(.leading)

                                 if isLoading {
                                      ProgressView().tint(styles.colors.accent).padding(.leading, 4)
                                 }
                             }
                             .frame(minHeight: 60) // Ensure consistent height
                        }
                    } else {
                        // Free tier locked state
                         Text("Unlock personalized recommendations with Premium.")
                             .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                             .frame(maxWidth: .infinity, minHeight: 60, alignment: .center) // Adjusted height
                             .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, styles.layout.paddingL) // INCREASED bottom padding
            } // Removed detailContent closure
        ) // End expandableCard
        .contentShape(Rectangle())
        .onTapGesture { if subscriptionTier == .premium { showingFullScreen = true } } // Only allow open if premium
        .onAppear(perform: loadInsight) // Load data on appear
         // Add listener for explicit insight updates
         .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[RecommendationsCard] Received insightsDidUpdate notification.")
             loadInsight() // Reload data when insights update
         }
        .fullScreenCover(isPresented: $showingFullScreen) {
             // Ensure we only show content if data exists
             if let recommendations = decodedRecommendations?.recommendations {
                 InsightFullScreenView(title: "Suggested Actions") {
                     RecommendationsDetailContent(
                         recommendations: recommendations,
                         generatedDate: generatedDate // Pass date
                     )
                 }
                 .environmentObject(styles) // Pass styles
             } else {
                 ProgressView()
             }
         }
    } // End body

     // Function to load and decode the insight
     private func loadInsight() {
         guard !isLoading else { return }
         isLoading = true
         decodingError = false // Reset error state
         print("[RecommendationsCard] Loading insight...")
         Task {
             do {
                 // Use await as DB call might become async
                  // Load JSON, date is passed in
                 if let (json, _) = try await databaseService.loadLatestInsight(type: "recommendation") {
                      decodeJSON(json: json) // Call decode function
                      await MainActor.run { isLoading = false }
                       print("[RecommendationsCard] Insight loaded.")
                 } else {
                     await MainActor.run {
                         decodedRecommendations = nil // Ensure it's nil if not found
                         isLoading = false
                         print("[RecommendationsCard] No stored insight found.")
                     }
                 }
             } catch {
                  await MainActor.run {
                      print("‼️ [RecommendationsCard] Failed to load insight: \(error)")
                      decodedRecommendations = nil // Clear result on error
                      decodingError = true // Set error state
                      isLoading = false
                  }
             }
         }
     }


    // Decoding function
    private func decodeJSON(json: String?) {
        guard let json = json, !json.isEmpty else {
             if decodedRecommendations != nil {
                  Task { await MainActor.run { decodedRecommendations = nil } }
             }
            // decodingError = false // Don't reset error here
            // isLoading = false // Ensure loading stops if json is nil/empty
            return
        }
        // isLoading = true // Start loading if we have JSON
        // decodingError = false // Reset error before trying decode

        guard let data = json.data(using: .utf8) else {
            print("⚠️ [RecommendationsCard] Failed convert JSON string to Data.");
            Task { await MainActor.run { decodingError = true; decodedRecommendations = nil; isLoading = false } } // Stop loading on error
            return
        }
        do {
            let result = try JSONDecoder().decode(RecommendationResult.self, from: data)
             Task { await MainActor.run {
                 if result != decodedRecommendations { decodedRecommendations = result; print("[RecommendationsCard] Decoded new recommendations.") }
                 decodingError = false // Clear error on success
                 // isLoading = false // Stop loading on success - Handled in loadInsight now
             }}
        } catch {
            print("‼️ [RecommendationsCard] Failed decode RecommendationResult: \(error). JSON: \(json)");
            Task { await MainActor.run { decodingError = true; decodedRecommendations = nil; isLoading = false } } // Stop loading on error
        }
    }
}

// Simplified RecommendationRow for preview (Keep as is)
struct RecommendationRow: View {
    let recommendation: RecommendationResult.RecommendationItem
    let iconName: String
    @ObservedObject private var styles = UIStyles.shared

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
                    .font(styles.typography.insightCaption) // Use insightCaption
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


#Preview {
    // Example RecommendationResult for preview
    let previewRecs = RecommendationResult(recommendations: [
        .init(id: UUID(), title: "5-Minute Mindfulness", description: "Take a short break to focus on your breath.", category: "Mindfulness", rationale: "Helps calm the mind based on recent stress indicators."),
        .init(id: UUID(), title: "Quick Walk Outside", description: "Get some fresh air and light movement.", category: "Activity", rationale: "Can boost mood and energy levels when feeling low.")
    ])
    let encoder = JSONEncoder()
    let data = try? encoder.encode(previewRecs)
    let jsonString = String(data: data ?? Data(), encoding: .utf8)

    return ScrollView {
        RecommendationsInsightCard(jsonString: jsonString, generatedDate: Date(), subscriptionTier: .premium)
            .padding()
            .environmentObject(DatabaseService()) // Provide DatabaseService
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}