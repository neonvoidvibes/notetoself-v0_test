import SwiftUI

struct WeeklySummaryInsightCard: View {
    // Input: Raw JSON string, generation date, and subscription status
    let jsonString: String?
    let generatedDate: Date?
    let isFresh: Bool // Flag for highlighting
    let subscriptionTier: SubscriptionTier

    // Local state for decoded result
    @State private var decodedSummary: WeeklySummaryResult? = nil
    @State private var decodingError: Bool = false
    @State private var isHovering: Bool = false // Keep for button hover effects
    @State private var showingFullScreen = false // State for full screen presentation
    @State private var isLoading: Bool = false // Add loading state

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService (needed for reload on notification)

    // Computed properties based on the DECODED result
    private var summaryPeriod: String {
        let calendar = Calendar.current
        let endDate = generatedDate ?? Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: endDate)
        let startOfWeek = calendar.date(from: components)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endDate))"
    }

    // Placeholder message logic
    private var placeholderMessage: String {
        if jsonString == nil {
            return "Keep journaling this week to generate your first summary!"
        } else if decodedSummary == nil && !decodingError && isLoading {
             return "Loading summary..."
        } else if decodingError {
            return "Could not load summary. Please try again later."
        } else if decodedSummary == nil && !isLoading {
             return "Weekly summary is not available yet."
        } else {
             return "" // Has data
        }
    }


    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: Period, Key Themes Preview, NEW badge
                VStack(alignment: .leading, spacing: styles.layout.spacingL) { // Increased spacing
                    HStack {
                        Text("Weekly Summary")
                            .font(styles.typography.title3) // Revert to title3
                            .foregroundColor(styles.colors.text)

                        if isFresh && subscriptionTier == .premium {
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(styles.colors.accentContrastText) // Contrast text
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(styles.colors.accent.opacity(0.9)) // Use accent directly
                                .clipShape(Capsule())
                                .shadow(color: styles.colors.accent.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        Spacer()
                        if subscriptionTier == .free {
                             Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                         }
                    }

                    if subscriptionTier == .premium {
                        Text(summaryPeriod) // Show period clearly
                            .font(styles.typography.bodyFont.weight(.semibold)) // Slightly bolder
                            .foregroundColor(styles.colors.accent) // Use accent color

                        // Key Themes Preview or Loading/Error state
                        HStack { // Wrap in HStack for ProgressView alignment
                             if let themes = decodedSummary?.keyThemes, !themes.isEmpty {
                                 HStack(spacing: styles.layout.spacingS) {
                                     Image(systemName: "tag.fill")
                                         .foregroundColor(styles.colors.textSecondary)
                                         .font(.caption)
                                     Text(themes.prefix(2).joined(separator: ", ") + (themes.count > 2 ? "..." : ""))
                                         .font(styles.typography.bodySmall)
                                         .foregroundColor(styles.colors.textSecondary)
                                         .lineLimit(1)
                                     Spacer() // Push themes left
                                 }
                             } else {
                                 // Loading/Error/Placeholder
                                 Text(placeholderMessage)
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(decodingError ? styles.colors.error : styles.colors.textSecondary)
                                     .lineLimit(1)
                                 Spacer() // Push text left
                                 if isLoading {
                                     ProgressView().tint(styles.colors.accent)
                                 }
                             }
                        }
                        .frame(height: 20) // Give consistent height

                    } else {
                        // Free tier locked state
                        Text("Unlock weekly summaries and deeper insights with Premium.")
                            .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, styles.layout.paddingL) // INCREASED bottom padding
            } // Removed detailContent closure
        ) // End expandableCard
        .contentShape(Rectangle())
        .onTapGesture { if subscriptionTier == .premium { showingFullScreen = true } } // Only allow open if premium
        .onAppear {
            // Decode initial jsonString passed in
            decodeJSON(json: jsonString)
        }
        // Decode if the jsonString from parent changes
        .onChange(of: jsonString) { oldValue, newValue in
            decodeJSON(json: newValue)
        }
         // Add listener for explicit insight updates (to reload from DB)
         .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[WeeklySummaryCard] Received insightsDidUpdate notification.")
             loadInsightFromDB() // Call new function to reload from DB
         }
        .fullScreenCover(isPresented: $showingFullScreen) {
             // Ensure we only show content if data exists
             if let result = decodedSummary {
                 InsightFullScreenView(title: "Weekly Summary") {
                     WeeklySummaryDetailContent(
                         summaryResult: result,
                         summaryPeriod: summaryPeriod, // Pass calculated period
                         generatedDate: generatedDate
                     )
                 }
                 .environmentObject(styles) // Pass styles
             } else {
                  ProgressView()
             }
         }
    }

    // Renamed original decode function to handle passed string
    private func decodeJSON(json: String?) {
         guard let json = json, !json.isEmpty else {
             if decodedSummary != nil { decodedSummary = nil }
             decodingError = false
             isLoading = false // Ensure loading is false if json is nil/empty
             return
         }
         // Assume loading starts if we have JSON to decode
         if !isLoading { isLoading = true }
         decodingError = false

         guard let data = json.data(using: .utf8) else {
             print("⚠️ [WeeklySummaryCard] Failed to convert JSON string to Data.")
              if decodedSummary != nil { decodedSummary = nil }
              decodingError = true
              isLoading = false
             return
         }
         do {
             let result = try JSONDecoder().decode(WeeklySummaryResult.self, from: data)
             if result != decodedSummary {
                 decodedSummary = result
                 print("[WeeklySummaryCard] Decoded new summary from input.")
             }
              isLoading = false // Stop loading on success
              decodingError = false
         } catch {
             print("‼️ [WeeklySummaryCard] Failed to decode WeeklySummaryResult from input: \(error). JSON: \(json)")
              if decodedSummary != nil { decodedSummary = nil }
              decodingError = true
              isLoading = false // Stop loading on error
         }
     }

    // New function to explicitly load latest from DB on notification
    private func loadInsightFromDB() {
         guard !isLoading else { return }
         isLoading = true
         decodingError = false
         print("[WeeklySummaryCard] Reloading insight from DB...")
         Task {
             do {
                 if let (json, _) = try await databaseService.loadLatestInsight(type: "weeklySummary") {
                     decodeJSON(json: json) // Decode the newly loaded JSON
                 } else {
                     print("[WeeklySummaryCard] No insight found in DB during reload.")
                      await MainActor.run {
                          decodedSummary = nil
                          decodingError = false
                      }
                 }
             } catch {
                 print("‼️ [WeeklySummaryCard] Error reloading insight from DB: \(error)")
                  await MainActor.run {
                      decodedSummary = nil
                      decodingError = true
                  }
             }
             // Ensure loading is stopped on main thread
              await MainActor.run { isLoading = false }
         }
     }
}


#Preview {
    // Example Summary for Preview
    let previewSummary = WeeklySummaryResult(
        mainSummary: "This week involved focusing on work projects and finding time for relaxation during the weekend.",
        keyThemes: ["Work Stress", "Weekend Relaxation", "Project Deadline"],
        moodTrend: "Generally positive with a dip mid-week",
        notableQuote: "Felt a real sense of accomplishment today."
    )
    let encoder = JSONEncoder()
    let data = try? encoder.encode(previewSummary)
    let jsonString = String(data: data ?? Data(), encoding: .utf8)

    return ScrollView {
        VStack(spacing: 20) {
            WeeklySummaryInsightCard(jsonString: jsonString, generatedDate: Date(), isFresh: true, subscriptionTier: .premium)
            WeeklySummaryInsightCard(jsonString: jsonString, generatedDate: Date(), isFresh: false, subscriptionTier: .premium)
            WeeklySummaryInsightCard(jsonString: jsonString, generatedDate: Date(), isFresh: true, subscriptionTier: .free)
             // Example for loading state
             WeeklySummaryInsightCard(jsonString: "{}", generatedDate: Date(), isFresh: false, subscriptionTier: .premium)
             // Example for error state (pass invalid JSON)
             WeeklySummaryInsightCard(jsonString: "{invalid json}", generatedDate: Date(), isFresh: false, subscriptionTier: .premium)
             // Example for no data state
             WeeklySummaryInsightCard(jsonString: nil, generatedDate: nil, isFresh: false, subscriptionTier: .premium)
        }
        .padding()
        .environmentObject(DatabaseService()) // Provide DatabaseService
        .environmentObject(UIStyles.shared)
        .environmentObject(ThemeManager.shared)
    }
     .background(Color.gray.opacity(0.1))

}