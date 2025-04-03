import SwiftUI

// Renamed from StreakInsightCard to StreakNarrativeInsightCard
struct StreakNarrativeInsightCard: View { // Ensure struct name matches file name
    let streak: Int

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared

    // State for the decoded result and loading/error status
    @State private var narrativeResult: StreakNarrativeResult? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "streakNarrative" // Consistent identifier

    // Computed properties to access result data safely
    private var storySnippet: String {
        narrativeResult?.storySnippet ?? (streak > 0 ? "Analyzing your recent journey..." : "Begin your story by journaling today.")
    }
    private var narrativeText: String {
        narrativeResult?.narrativeText ?? "Your detailed storyline will appear here with more data."
    }


    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            isPrimary: streak > 0, // Highlight if streak is active
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: Larger streak, fewer items, helping text
                HStack(alignment: .center, spacing: styles.layout.spacingL) {
                    // Large Flame Icon & Streak Number
                    VStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 36))
                            .foregroundColor(styles.colors.accent)
                        Text("\(streak)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced)) // Larger, bolder
                            .foregroundColor(styles.colors.text)
                        Text(streak == 1 ? "day" : "days")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary)
                    }
                    .frame(width: 60) // Fixed width for icon/number

                    // Story Snippet & Helping Text
                    VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                        Text("Your Journey") // Clearer title
                            .font(styles.typography.smallLabelFont)
                            .foregroundColor(styles.colors.textSecondary)

                        Text(storySnippet)
                            .font(styles.typography.bodyFont) // Main text for snippet
                            .foregroundColor(styles.colors.text)
                            .lineLimit(2)

                        Text("Tap to see your journey's turning points!") // Helping text
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.accent)
                    }
                    Spacer() // Push content to left
                }
                .padding(.vertical, styles.layout.paddingS) // Add some vertical padding
            },
            detailContent: {
                // Pass the narrative result to the detail view
                StreakNarrativeDetailContent(
                    streak: streak,
                    entries: appState.journalEntries, // Keep passing entries if detail view needs them
                    narrativeResult: narrativeResult // Pass the loaded result
                )
            }
        )
        .transition(.scale.combined(with: .opacity))
        // Add loading logic
        .onAppear(perform: loadInsight)
        .onChange(of: appState.journalEntries.count) { _, _ in // Reload if entries change
             // Optional: Add a debounce or check if generation actually happened recently
             // to avoid reloading too often if InsightUtils trigger is delayed.
             // For now, reload on any entry change.
             loadInsight()
         }
         // Add listener for explicit insight updates
         .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[StreakNarrativeCard] Received insightsDidUpdate notification.")
             loadInsight()
         }
    }

    // Function to load and decode the insight
    private func loadInsight() {
        // Avoid concurrent loads
        guard !isLoading else { return }
        isLoading = true
        loadError = false
        print("[StreakNarrativeCard] Loading insight...")

        Task {
            do {
                // Use await as loadLatestInsight might become async
                if let (json, _) = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                    if let data = json.data(using: .utf8) {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(StreakNarrativeResult.self, from: data)
                        await MainActor.run {
                            narrativeResult = result
                            isLoading = false
                             print("[StreakNarrativeCard] Insight loaded and decoded.")
                        }
                    } else {
                        throw NSError(domain: "StreakNarrativeCard", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to Data"])
                    }
                } else {
                    // No insight found in DB
                     await MainActor.run {
                         narrativeResult = nil // Ensure it's nil if not found
                         isLoading = false
                         print("[StreakNarrativeCard] No stored insight found.")
                     }
                }
            } catch {
                 await MainActor.run {
                     print("‼️ [StreakNarrativeCard] Failed to load/decode insight: \(error)")
                     narrativeResult = nil // Clear result on error
                     loadError = true
                     isLoading = false
                 }
            }
        }
    }
}

// Preview remains similar, just update the name
#Preview {
    ScrollView {
        StreakNarrativeInsightCard(streak: 5)
            .padding()
            .environmentObject(AppState()) // Provide mock data if needed
            .environmentObject(DatabaseService()) // Provide DatabaseService
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}