import SwiftUI

struct DailyReflectionInsightCard: View {
    @EnvironmentObject var appState: AppState
    // Remove databaseService dependency if loading is handled by parent
    // @EnvironmentObject var databaseService: DatabaseService

    // Accept data from parent
    let jsonString: String?
    let generatedDate: Date? // Keep generatedDate if needed for display

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    // State for DECODED result, loading/error status during decode
    @State private var insightResult: DailyReflectionResult? = nil
    @State private var isLoading: Bool = false // Used briefly during decode
    @State private var decodeError: Bool = false

    // Computed properties remain the same, relying on insightResult state
    private var snapshotText: String? { insightResult?.snapshotText }
    private var reflectionPrompts: [String]? { insightResult?.reflectionPrompts }

    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header
                    HStack {
                        Text("Daily Reflection") // UPDATED Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text) // Standard color
                        Spacer()
                        // UPDATED Icon
                        Image(systemName: "brain.head.profile")
                             .foregroundColor(styles.colors.accent)
                             .font(.system(size: 20)) // Match other card icon sizes
                         if appState.subscriptionTier == .free { // Gating
                            Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                        }
                    }

                    // Content Snippet (Daily Snapshot)
                    if appState.subscriptionTier == .premium {
                        if isLoading { // Loading means decoding in progress
                            ProgressView().tint(styles.colors.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 60)
                        } else if decodeError { // Use decodeError state
                            Text("Could not load daily reflection.")
                                .font(styles.typography.bodySmall) // Error text can be smaller
                                .foregroundColor(styles.colors.error)
                                .frame(minHeight: 60)
                        } else if let snapshot = snapshotText, !snapshot.isEmpty {
                             VStack(alignment: .leading, spacing: styles.layout.spacingS) { // Use spacing S for less gap
                                 Text(snapshot)
                                     .font(styles.typography.bodyFont) // Ensure bodyFont
                                     .foregroundColor(styles.colors.text) // Ensure primary text color
                                     .lineLimit(3) // Allow more lines for snapshot

                                // --- REMOVED Button ---
                                // The "Continue in Chat" button is removed from here.
                             }

                        } else {
                             // Handles case where jsonString was nil or decoding resulted in empty data
                            Text("Today's reflection available after journaling.")
                                .font(styles.typography.bodyFont) // Ensure bodyFont
                                .foregroundColor(styles.colors.text) // Ensure primary text color
                                .frame(minHeight: 60, alignment: .center)
                        }
                    } else {
                         Text("Unlock daily AI reflections with Premium.")
                             .font(styles.typography.bodySmall) // Keep small for locked state
                             .foregroundColor(styles.colors.textSecondary)
                             .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                             .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, styles.layout.paddingL) // Keep standard bottom padding
            }
        )
        .contentShape(Rectangle())
        // Keep tap gesture for opening detail view
        .onTapGesture { if appState.subscriptionTier == .premium { showingFullScreen = true } }
        .onAppear { decodeJSON() } // Decode initial JSON on appear
        .onChange(of: jsonString) { // Re-decode if JSON string changes
             oldValue, newValue in
             decodeJSON()
         }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Daily Reflection") {
                  DailyReflectionDetailContent(
                      result: insightResult ?? .empty(), // Use decoded result
                      generatedDate: generatedDate // Pass date if needed
                  )
              }
              .environmentObject(styles)
              .environmentObject(appState)
        }
    }

    // Decode function now uses the passed-in jsonString
    @MainActor
    private func decodeJSON() {
        guard let json = jsonString, !json.isEmpty else {
            insightResult = nil
            decodeError = false // Not an error if no JSON provided
            isLoading = false
            return
        }

        // Only set loading if we actually have JSON to decode
        if !isLoading { isLoading = true }
        decodeError = false
        print("[DailyReflectionCard] Decoding JSON...")

        if let data = json.data(using: .utf8) {
            do {
                let result = try JSONDecoder().decode(DailyReflectionResult.self, from: data)
                self.insightResult = result
                self.decodeError = false
                print("[DailyReflectionCard] Decode success.")
            } catch {
                print("‼️ [DailyReflectionCard] Failed to decode DailyReflectionResult: \(error). JSON: \(json)")
                self.insightResult = nil
                self.decodeError = true
            }
        } else {
            print("‼️ [DailyReflectionCard] Failed to convert JSON string to Data.")
            self.insightResult = nil
            self.decodeError = true
        }
        self.isLoading = false
    }
}

#Preview {
    // Pass nil for preview as InsightsView now handles loading
    ScrollView {
        DailyReflectionInsightCard(jsonString: nil, generatedDate: nil)
            .padding()
            .environmentObject(AppState())
            .environmentObject(DatabaseService()) // Keep DB if detail view needs it
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}