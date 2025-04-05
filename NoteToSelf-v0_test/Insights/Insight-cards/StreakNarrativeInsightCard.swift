import SwiftUI

// Renamed from StreakInsightCard to StreakNarrativeInsightCard
struct StreakNarrativeInsightCard: View { // Ensure struct name matches file name
    let streak: Int

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false // State for full screen presentation
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared

    // State for the decoded result and loading/error status
    @State private var narrativeResult: StreakNarrativeResult? = nil
    @State private var generatedDate: Date? = nil // Add state for date
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "streakNarrative" // Consistent identifier

    // Computed properties to access result data safely
    private var storySnippet: String {
        if isLoading { return "Loading story..." }
        if loadError { return "Could not load story."}
        return narrativeResult?.storySnippet ?? (streak > 0 ? "Analyzing your recent journey..." : "Begin your story by journaling today.")
    }
    private var narrativeText: String { // Although not used directly here, keep for passing
        narrativeResult?.narrativeText ?? "Your detailed storyline will appear here with more data."
    }


    var body: some View {
        styles.expandableCard( // Removed isPrimary argument
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: Standard Header + Streak Display + Snippet
                VStack(alignment: .leading, spacing: styles.layout.spacingL) { // Increased spacing
                    // Standard Header
                    HStack {
                        Text("Your Journey") // Updated Title
                            .font(styles.typography.title3) // Revert to title3
                            .foregroundColor(styles.colors.text)
                        Spacer()
                        // Icon on the right
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20)) // Slightly smaller icon in header
                            .foregroundColor(styles.colors.accent)
                    }

                    // Streak Display (Centered below header)
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(streak)")
                            .font(.system(size: 40, weight: .bold, design: .monospaced)) // Large streak number
                            .foregroundColor(styles.colors.text)
                        Text(streak == 1 ? "day" : "days")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .padding(.leading, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .center) // Center the streak


                    // Story Snippet & Helping Text (Centered below streak)
                    VStack(spacing: styles.layout.spacingS) {
                         // Wrap potentially long snippet text with ProgressView/Error indication
                         HStack {
                             Text(storySnippet)
                                 .font(styles.typography.bodyFont) // Main text for snippet
                                 .foregroundColor(loadError ? styles.colors.error : styles.colors.text) // Use error color if needed
                                 .multilineTextAlignment(.center)
                                 .lineLimit(2)
                                 .fixedSize(horizontal: false, vertical: true) // Allow wrapping
                             if isLoading {
                                 ProgressView().tint(styles.colors.accent).padding(.leading, 4)
                             }
                         }
                         .frame(minHeight: 30) // Give space for loading indicator

                         Text("Tap to see your journey's turning points!") // Helping text
                             .font(styles.typography.caption)
                             .foregroundColor(styles.colors.accent)
                             .multilineTextAlignment(.center)
                    }
                     .frame(maxWidth: .infinity, alignment: .center) // Center the text block
                     .padding(.bottom, styles.layout.paddingL) // INCREASED bottom padding

                }
            } // Removed detailContent closure
        )
        .contentShape(Rectangle()) // Make entire card tappable
        .onTapGesture { showingFullScreen = true } // Trigger fullscreen on tap
        .transition(.scale.combined(with: .opacity))
        .fullScreenCover(isPresented: $showingFullScreen) {
            InsightFullScreenView(title: "Your Journey") {
                 // Embed the detail content view
                 StreakNarrativeDetailContent(
                     streak: streak,
                     entries: appState.journalEntries,
                     narrativeResult: narrativeResult,
                     generatedDate: generatedDate // Pass date
                 )
             }
             .environmentObject(styles) // Pass styles if needed by subview
             .environmentObject(appState) // Pass appState
             .environmentObject(databaseService) // Pass databaseService
        }
        // Add loading logic
        .onAppear(perform: loadInsight)
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
                if let (json, date) = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) { // Capture date
                    if let data = json.data(using: .utf8) {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(StreakNarrativeResult.self, from: data)
                        await MainActor.run {
                            narrativeResult = result
                            generatedDate = date // Store date
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
                         generatedDate = nil // Clear date
                         isLoading = false
                         print("[StreakNarrativeCard] No stored insight found.")
                     }
                }
            } catch {
                 await MainActor.run {
                     print("‼️ [StreakNarrativeCard] Failed to load/decode insight: \(error)")
                     narrativeResult = nil // Clear result on error
                     generatedDate = nil // Clear date
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