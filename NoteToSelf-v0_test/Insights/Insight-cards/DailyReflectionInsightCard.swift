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

    // [5.1] Check if insight is fresh (within 24 hours)
    private var isFresh: Bool {
        guard let genDate = generatedDate else { return false }
        // Consider insight new if generated within the last 24 hours
        return Calendar.current.dateComponents([.hour], from: genDate, to: Date()).hour ?? 25 < 24
    }

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

                        // [5.1] Add NEW Badge conditionally
                        if isFresh && appState.subscriptionTier == .pro { // CORRECTED: Check .pro
                            NewBadgeView()
                        }

                        // Icon
                        Image(systemName: "brain.head.profile")
                             .foregroundColor(styles.colors.accent)
                             .font(.system(size: 20))
                         if appState.subscriptionTier == .free { // Gating check is correct (.free)
                            Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                        }
                    }

                    // Content Snippet (Daily Snapshot)
                    if appState.subscriptionTier == .pro { // CORRECTED: Check .pro
                        if isLoading { // Loading means decoding in progress
                            ProgressView().tint(styles.colors.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 60)
                        } else if decodeError { // Use decodeError state
                            // [4.2] Improved Error Message
                            Text("Couldn't load reflection.\nPlease try again later.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.error)
                                .multilineTextAlignment(.center) // Center align error
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 60)
                        } else if let snapshot = snapshotText, !snapshot.isEmpty {
                             VStack(alignment: .leading, spacing: styles.layout.spacingS) { // Use spacing S for less gap
                                 Text(snapshot)
                                     .font(styles.typography.bodyFont) // Ensure bodyFont
                                     .foregroundColor(styles.colors.text) // Ensure primary text color
                                     .lineLimit(3) // Allow more lines for snapshot

                                // Button removed
                             }

                        } else {
                             // Handles case where jsonString was nil or decoding resulted in empty data
                            Text("Today's reflection available after journaling.")
                                .font(styles.typography.bodyFont) // Ensure bodyFont
                                .foregroundColor(styles.colors.text) // Ensure primary text color
                                .frame(minHeight: 60, alignment: .center)
                        }
                    } else {
                         Text("Unlock daily AI reflections with Premium.") // User-facing text can remain "Premium"
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
        .onTapGesture { if appState.subscriptionTier == .pro { showingFullScreen = true } } // CORRECTED: Check .pro
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

// MARK: - Reusable New Badge View [5.1]
struct NewBadgeView: View {
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        Text("NEW")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(styles.colors.accentContrastText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(styles.colors.accent.opacity(0.9))
            .clipShape(Capsule())
    }
}


#Preview {
    // Pass nil for preview as InsightsView now handles loading
    ScrollView {
        VStack {
            DailyReflectionInsightCard(jsonString: """
            {
                "snapshotText": "This is a preview snapshot.",
                "reflectionPrompts": ["Prompt 1?", "Prompt 2?"]
            }
            """, generatedDate: Date()) // Preview with fresh data

            DailyReflectionInsightCard(jsonString: """
            {
                "snapshotText": "This is older data.",
                "reflectionPrompts": ["Prompt A?", "Prompt B?"]
            }
            """, generatedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())) // Preview with old data

             DailyReflectionInsightCard(jsonString: nil, generatedDate: nil) // Preview empty

        }
        .padding()
    }
    .environmentObject(AppState())
    .environmentObject(DatabaseService()) // Keep DB if detail view needs it
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .background(Color.gray.opacity(0.1))
}