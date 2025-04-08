import SwiftUI

struct DailyReflectionInsightCard: View {
    @EnvironmentObject var appState: AppState
    // Removed databaseService dependency

    // Accept data from parent
    let jsonString: String?
    let generatedDate: Date?

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    // State for DECODED result
    @State private var insightResult: DailyReflectionResult? = nil
    // isLoading and decodeError removed, handled by presence/absence of insightResult

    // Computed properties remain the same, relying on insightResult state
    private var snapshotText: String? { insightResult?.snapshotText }
    private var reflectionPrompts: [String]? { insightResult?.reflectionPrompts }

    // Check if insight is fresh (within 24 hours)
    private var isFresh: Bool {
        guard let genDate = generatedDate else { return false }
        return Calendar.current.dateComponents([.hour], from: genDate, to: Date()).hour ?? 25 < 24
    }

    // Computed property to check if content is available
    private var hasContent: Bool {
        // Consider content available if the result is decoded and snapshot is not empty
        return insightResult?.snapshotText?.isEmpty == false
    }

    var body: some View {
        // Conditional Content: Button or Card
        if hasContent {
            // --- Card View (Content Available) ---
            styles.expandableCard(
                scrollProxy: scrollProxy,
                cardId: cardId,
                content: {
                    VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                        // Header
                        HStack {
                            Text("Daily Reflection")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)
                            Spacer()

                            // Show "New" badge only if content exists and is fresh
                            if isFresh {
                                NewBadgeView()
                            }

                            // Icon
                            Image(systemName: "brain.head.profile")
                                 .foregroundColor(styles.colors.accent)
                                 .font(.system(size: 20))
                        }

                        // Content Snippet (Daily Snapshot)
                        // No gating needed here as `hasContent` already checked subscription indirectly
                        if let snapshot = snapshotText, !snapshot.isEmpty {
                             VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                                 Text(snapshot)
                                     .font(styles.typography.bodyFont)
                                     .foregroundColor(styles.colors.text)
                                     .lineLimit(3)
                             }
                        } else {
                             // Fallback (shouldn't be reached if hasContent is true)
                             Text("Loading reflection...")
                                 .font(styles.typography.bodyFont)
                                 .foregroundColor(styles.colors.textSecondary)
                                 .frame(minHeight: 60, alignment: .center)
                        }
                    }
                    .padding(.bottom, styles.layout.paddingL)
                }
            )
            .contentShape(Rectangle())
            // Allow opening detail view only if content exists
            .onTapGesture { showingFullScreen = true }
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

        } else {
            // --- Button View (No Content Available) ---
            Button {
                // Action to switch to Journal Tab (Index 0)
                print("[DailyReflectionCard] Go to Journal button tapped.")
                NotificationCenter.default.post(
                    name: .switchToTabNotification,
                    object: nil,
                    userInfo: ["tabIndex": 0]
                )
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill") // Icon for adding entry
                        .font(.system(size: 18))
                    Text("Add Journal Entry for Daily Reflection")
                        .font(styles.typography.bodyFont.weight(.medium)) // Use body font, medium weight
                }
                .foregroundColor(styles.colors.accentContrastText) // Use contrast text color
                .frame(maxWidth: .infinity) // Make button full width
                .padding(.vertical, styles.layout.paddingM) // Standard vertical padding
            }
            .background(styles.colors.accent) // Use accent color for background
            .cornerRadius(styles.layout.radiusM) // Standard corner radius
            .padding(.horizontal, styles.layout.paddingXL) // Match card horizontal padding
            // No .onTapGesture here, button action handles the tap
             .onAppear { decodeJSON() } // Still attempt decode on appear in case JSON becomes available later
             .onChange(of: jsonString) { decodeJSON() } // Still re-decode if JSON changes
        }
    }

    // Decode function now uses the passed-in jsonString
    @MainActor
    private func decodeJSON() {
        guard let json = jsonString, !json.isEmpty else {
            insightResult = nil // Set to nil if no JSON
            return
        }

        // No loading state needed as UI switches between button/card based on result
        print("[DailyReflectionCard] Decoding JSON...")

        if let data = json.data(using: .utf8) {
            do {
                let result = try JSONDecoder().decode(DailyReflectionResult.self, from: data)
                // Only update if the snapshot text is actually present
                if !(result.snapshotText?.isEmpty ?? true) {
                    self.insightResult = result
                    print("[DailyReflectionCard] Decode success.")
                } else {
                    // Treat empty snapshot as no content
                    self.insightResult = nil
                    print("[DailyReflectionCard] Decoded successfully, but snapshot is empty. Treating as no content.")
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

// MARK: - Reusable New Badge View
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
             // Preview with Content
             DailyReflectionInsightCard(jsonString: """
             {
                 "snapshotText": "This is a preview snapshot reflecting on today's key feeling of accomplishment.",
                 "reflectionPrompts": ["What made today feel accomplished?", "How can you carry this forward?"]
             }
             """, generatedDate: Date())

             // Preview with OLD Content (should still show card, but no "NEW" badge)
             DailyReflectionInsightCard(jsonString: """
             {
                 "snapshotText": "Older reflection content.",
                 "reflectionPrompts": ["Old prompt 1?", "Old prompt 2?"]
             }
             """, generatedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()))

              // Preview No Content (should show button)
              DailyReflectionInsightCard(jsonString: nil, generatedDate: nil)

              // Preview Empty JSON String (should show button)
              DailyReflectionInsightCard(jsonString: "", generatedDate: nil)

              // Preview JSON with Empty Snapshot (should show button)
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