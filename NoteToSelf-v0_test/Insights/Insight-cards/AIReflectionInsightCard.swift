import SwiftUI

// Renamed from ChatInsightCard to AIReflectionInsightCard
struct AIReflectionInsightCard: View { // Ensure struct name matches file name
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager // Keep for potential context/history link
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false // State for full screen presentation
    @State private var animateGradient: Bool = false // Keep animation

    @ObservedObject private var styles = UIStyles.shared

    // State for the decoded result and loading/error status
    @State private var reflectionResult: AIReflectionResult? = nil
    @State private var generatedDate: Date? = nil // Add state for date
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "aiReflection" // Consistent identifier

    // Computed properties to access result data safely
     private var insightMessage: String {
         if isLoading { return "Loading reflection..."}
         if loadError { return "Could not load reflection."}
         return reflectionResult?.insightMessage ?? "How are you feeling today?" // Default message
     }
     private var reflectionPrompts: [String] {
         reflectionResult?.reflectionPrompts ?? [ // Default prompts
             "What's been on your mind lately?",
             "What are you grateful for today?",
             "What challenge are you currently facing?"
         ]
     }

    var body: some View {
        styles.expandableCard( // Removed isExpanded
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                 // Collapsed View: Standard Header + AI message snippet
                 VStack(alignment: .leading, spacing: styles.layout.spacingL) { // Increased spacing
                     // Standard Header with AI icon
                     HStack {
                         Text("AI Insights") // Updated Title
                             .font(styles.typography.title3) // Revert to title3
                             .foregroundColor(styles.colors.text)
                         Spacer()
                         // AI Avatar Icon in header
                         ZStack {
                              Circle()
                                  .fill(styles.colors.accent.opacity(0.2)) // Subtle background
                                  .frame(width: 30, height: 30)
                              Image(systemName: "sparkles")
                                  .foregroundColor(styles.colors.accent)
                                  .font(.system(size: 16))
                          }
                     }

                     // Insight Snippet (using bodyFont)
                      HStack { // Wrap in HStack for ProgressView
                          Text(insightMessage)
                              .font(styles.typography.bodyFont)
                              .foregroundColor(loadError ? styles.colors.error : styles.colors.text) // Use error color
                              .lineLimit(3) // Allow slightly more text if needed
                              .frame(maxWidth: .infinity, alignment: .leading)
                          if isLoading {
                              ProgressView().tint(styles.colors.accent)
                          }
                      }
                      .frame(minHeight: 40) // Consistent height


                      // Helping Text
                      Text("Tap to reflect deeper on today’s thoughts.")
                          .font(styles.typography.caption)
                          .foregroundColor(styles.colors.accent)
                          .frame(maxWidth: .infinity, alignment: .leading)

                 }
                 .padding(.bottom, styles.layout.paddingL) // INCREASED bottom padding
            } // Removed detailContent closure
        )
        .contentShape(Rectangle())
        .onTapGesture { showingFullScreen = true } // Trigger fullscreen on tap
        // Add loading logic
        .onAppear(perform: loadInsight)
         // Add listener for explicit insight updates
         .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[AIReflectionCard] Received insightsDidUpdate notification.")
             loadInsight()
         }
        .fullScreenCover(isPresented: $showingFullScreen) {
            InsightFullScreenView(title: "AI Insights") {
                AIReflectionDetailContent(
                    insightMessage: insightMessage,
                    reflectionPrompts: reflectionPrompts,
                    generatedDate: generatedDate // Pass date correctly
                )
            }
            .environmentObject(styles) // Pass styles
            .environmentObject(appState) // Pass appState if detail view needs it
        }
    } // End body

    // Function to load and decode the insight
    private func loadInsight() {
        guard !isLoading else { return }
        isLoading = true
        loadError = false
        print("[AIReflectionCard] Loading insight...")

        Task {
            do {
                // Use await as loadLatestInsight might become async
                if let (json, date) = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) { // Capture date
                    if let data = json.data(using: .utf8) {
                        let result = try JSONDecoder().decode(AIReflectionResult.self, from: data)
                        await MainActor.run {
                            reflectionResult = result
                            generatedDate = date // Store date
                            isLoading = false
                             print("[AIReflectionCard] Insight loaded and decoded.")
                        }
                    } else {
                        throw NSError(domain: "AIReflectionCard", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to Data"])
                    }
                } else {
                    await MainActor.run {
                        reflectionResult = nil
                        generatedDate = nil // Clear date
                        isLoading = false
                        print("[AIReflectionCard] No stored insight found.")
                    }
                }
            } catch {
                 await MainActor.run {
                     print("‼️ [AIReflectionCard] Failed to load/decode insight: \(error)")
                     reflectionResult = nil
                     generatedDate = nil // Clear date
                     loadError = true
                     isLoading = false
                 }
            }
        }
    }
} // End struct AIReflectionInsightCard

// Update preview provider name to match struct
#Preview {
    ScrollView{
        AIReflectionInsightCard() // Use correct struct name
            .padding()
            .environmentObject(AppState()) // Provide mock data if needed
            .environmentObject(ChatManager(databaseService: DatabaseService(), llmService: LLMService.shared, subscriptionManager: SubscriptionManager.shared))
             .environmentObject(DatabaseService()) // Also provide DatabaseService
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}