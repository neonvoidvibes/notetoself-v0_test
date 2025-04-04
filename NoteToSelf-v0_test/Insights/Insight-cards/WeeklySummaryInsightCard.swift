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

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService

    // Computed properties based on the DECODED result
    private var summaryPeriod: String {
        let calendar = Calendar.current
        let endDate = generatedDate ?? Date()
        // Adjust to calculate the start of the week (Sunday) based on the end date
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: endDate)
        let startOfWeek = calendar.date(from: components)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d" // Keep format concise
        return "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endDate))"
    }

    // Placeholder message logic
    private var placeholderMessage: String {
        if jsonString == nil {
            return "Keep journaling this week to generate your first summary!"
        } else if decodedSummary == nil && !decodingError {
             return "Loading summary..." // Indicates decoding is happening or pending
        } else if decodingError {
            return "Could not load summary. Please try again later."
        } else {
            // Should have decodedSummary if no error and jsonString exists
            return "Weekly summary is not available yet."
        }
    }

    var body: some View {
        styles.expandableCard( // Removed isExpanded, isPrimary, highlightColor
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

                        // Key Themes Preview
                        if let themes = decodedSummary?.keyThemes, !themes.isEmpty {
                            HStack(spacing: styles.layout.spacingS) {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(styles.colors.textSecondary)
                                    .font(.caption)
                                Text(themes.prefix(2).joined(separator: ", ") + (themes.count > 2 ? "..." : ""))
                                    .font(styles.typography.bodySmall) // Main font for themes preview
                                    .foregroundColor(styles.colors.textSecondary)
                                    .lineLimit(1)
                            }
                        } else if jsonString != nil && decodedSummary == nil && !decodingError {
                           ProgressView().tint(styles.colors.accent).padding(.vertical, 4) // Show loading indicator briefly
                        } else if jsonString == nil || decodingError {
                             Text(placeholderMessage) // Show placeholder if no data/error
                                 .font(styles.typography.bodySmall)
                                 .foregroundColor(styles.colors.textSecondary)
                        } else {
                            Text("Key themes will appear here.") // Default text if themes are empty but summary exists
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.textSecondary)
                        }

                    } else {
                        // Free tier locked state
                        Text("Unlock weekly summaries and deeper insights with Premium.")
                            .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                            .multilineTextAlignment(.center)
                    }
                }
            } // Removed detailContent closure
        )
        .contentShape(Rectangle())
        .onTapGesture { if subscriptionTier == .premium { showingFullScreen = true } } // Only allow open if premium
        .onChange(of: jsonString) { oldValue, newValue in
            decodeJSON(json: newValue)
        }
        .onAppear {
            decodeJSON(json: jsonString)
        }
         // Add listener for explicit insight updates
         .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[WeeklySummaryCard] Received insightsDidUpdate notification.")
             // Assuming summary only updates weekly, might not need immediate reload here
             // unless triggered specifically for summary. For now, rely on onAppear/jsonString change.
             // loadInsight() // Could add a loadInsight func if needed
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
                 // Pass other EnvironmentObjects if WeeklySummaryDetailContent needs them
             } else {
                  // Optional: Show a loading or error view if cover is presented before data is ready
                  ProgressView() // Simple loading indicator
             }
         }
    }

    // Decoding function (remains the same)
    private func decodeJSON(json: String?) {
        guard let json = json, !json.isEmpty else {
            // Reset state if json is nil or empty
             if decodedSummary != nil { decodedSummary = nil }
             decodingError = false
            return
        }

        decodingError = false // Reset error before trying

        guard let data = json.data(using: .utf8) else {
            print("⚠️ [WeeklySummaryCard] Failed to convert JSON string to Data.")
             if decodedSummary != nil { decodedSummary = nil }
             decodingError = true
            return
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(WeeklySummaryResult.self, from: data)
            if result != decodedSummary {
                decodedSummary = result
                print("[WeeklySummaryCard] Decoded new summary.")
            }
        } catch {
            print("‼️ [WeeklySummaryCard] Failed to decode WeeklySummaryResult: \(error). JSON: \(json)")
             if decodedSummary != nil { decodedSummary = nil }
             decodingError = true
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
        }
        .padding()
        .environmentObject(DatabaseService()) // Provide DatabaseService
        .environmentObject(UIStyles.shared)
        .environmentObject(ThemeManager.shared)
    }
     .background(Color.gray.opacity(0.1))

}