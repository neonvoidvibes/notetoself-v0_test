import SwiftUI

struct DailyReflectionInsightCard: View {
    @EnvironmentObject var appState: AppState
    // Removed databaseService dependency

    // Accept data from parent
    let jsonString: String?
    let generatedDate: Date? // Keep generatedDate, might be useful later

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    // State for DECODED result
    @State private var insightResult: DailyReflectionResult? = nil

    // Computed properties remain the same, relying on insightResult state
    private var snapshotText: String? { insightResult?.snapshotText }
    private var reflectionPrompts: [String]? { insightResult?.reflectionPrompts }

    // Computed property to check if content is available
    private var hasContent: Bool {
        // Consider content available if the result is decoded and snapshot is not empty
        return insightResult?.snapshotText?.isEmpty == false
    }

    var body: some View {
        // Always use expandableCard structure
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            showOpenButton: hasContent, // Pass hasContent to control button visibility
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header
                    HStack {
                        Text("Daily Reflection")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        Spacer()
                        Image(systemName: "brain.head.profile")
                             .foregroundColor(styles.colors.accent)
                             .font(.system(size: 20))
                         if appState.subscriptionTier == .free {
                            Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                        }
                    }

                    // Content Snippet (Conditional Display)
                    if appState.subscriptionTier == .pro {
                        if hasContent {
                             // Display snapshot text if content is available
                             if let snapshot = snapshotText, !snapshot.isEmpty {
                                 VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                                     Text(snapshot)
                                         .font(styles.typography.bodyFont)
                                         .foregroundColor(styles.colors.text)
                                         .lineLimit(3)
                                 }
                             } else {
                                 EmptyStateView(message: "Processing reflection...")
                             }
                        } else {
                            // Display NEW explanatory text if no content
                            EmptyStateView(message: "Add a journal note to see your daily reflection.")
                        }
                    } else {
                         LockedContentView(message: "Unlock daily AI reflections with Premium.")
                    }
                }
                // Removed bottom padding here, let content/VStack handle it
            }
        )
        .contentShape(Rectangle())
        // Only allow opening if content exists AND user is subscribed
        .onTapGesture {
             if hasContent && appState.subscriptionTier == .pro {
                 showingFullScreen = true
             } else {
                 print("[DailyReflectionCard] Tap ignored (No content or Free Tier).")
             }
        }
        .opacity(hasContent ? 1.0 : 0.7) // Dim card slightly if no content
        .onAppear { decodeJSON() } // Decode initial JSON
        .onChange(of: jsonString) { decodeJSON() } // Re-decode if JSON changes
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

    // Decode function remains the same
    @MainActor
    private func decodeJSON() {
        guard let json = jsonString, !json.isEmpty else {
            insightResult = nil // Set to nil if no JSON
            return
        }

        print("[DailyReflectionCard] Decoding JSON...")

        if let data = json.data(using: .utf8) {
            do {
                let result = try JSONDecoder().decode(DailyReflectionResult.self, from: data)
                // Check if snapshot text is actually present
                if !(result.snapshotText?.isEmpty ?? true) {
                    self.insightResult = result
                    print("[DailyReflectionCard] Decode success.")
                } else {
                    self.insightResult = nil // Treat empty snapshot as no content
                    print("[DailyReflectionCard] Decoded successfully, but snapshot is empty.")
                }
            } catch {
                print("‼️ [DailyReflectionCard] Failed to decode DailyReflectionResult: \(error). JSON: \(json)")
                self.insightResult = nil // Set to nil on decode error
            }
        } else {
            print("‼️ [DailyReflectionCard] Failed to convert JSON string to Data.")
            self.insightResult = nil // Set to nil on data conversion error
        }
    }
}


#Preview {
    // Pass nil for preview as InsightsView now handles loading
    ScrollView {
        VStack {
             // Preview with Content
             DailyReflectionInsightCard(jsonString: """
             {
                 "snapshotText": "This is a preview snapshot reflecting on today's key feeling of accomplishment.",
                 "reflectionPrompts": ["What made today feel accomplished?", "How can you carry this forward?"]
             }
             """, generatedDate: Date())

              // Preview No Content (should show card with explanation, no Open button)
              DailyReflectionInsightCard(jsonString: nil, generatedDate: nil)

              // Preview Empty JSON String (should show card with explanation, no Open button)
              DailyReflectionInsightCard(jsonString: "", generatedDate: nil)

              // Preview JSON with Empty Snapshot (should show card with explanation, no Open button)
              DailyReflectionInsightCard(jsonString: """
               {
                   "snapshotText": "",
                   "reflectionPrompts": ["Prompt A?", "Prompt B?"]
               }
               """, generatedDate: Date())

        }
        .padding()
    }
    .environmentObject(AppState()) // Provide AppState
    .environmentObject(DatabaseService()) // Keep DB if detail view needs it
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .background(Color.gray.opacity(0.1))
}