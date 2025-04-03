import SwiftUI

// Renamed from ChatInsightCard to AIReflectionInsightCard
struct AIReflectionInsightCard: View { // Ensure struct name matches file name
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager // Keep for potential context/history link
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    @State private var animateGradient: Bool = false // Keep animation

    @ObservedObject private var styles = UIStyles.shared

    // State for the decoded result and loading/error status
    @State private var reflectionResult: AIReflectionResult? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "aiReflection" // Consistent identifier

    // Computed properties to access result data safely
     private var insightMessage: String {
         reflectionResult?.insightMessage ?? "How are you feeling today?" // Default message
     }
     private var reflectionPrompts: [String] {
         reflectionResult?.reflectionPrompts ?? [ // Default prompts
             "What's been on your mind lately?",
             "What are you grateful for today?",
             "What challenge are you currently facing?"
         ]
     }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: AI Avatar, Insight Snippet, Helping Text
                HStack(spacing: styles.layout.spacingM) {
                    // AI Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        styles.colors.accent,
                                        styles.colors.accent.opacity(0.7)
                                    ]),
                                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                                )
                            )
                            .frame(width: 50, height: 50) // Slightly larger avatar
                        Image(systemName: "sparkles") // Keep sparkles
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    .onAppear { // Keep animation logic
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            animateGradient.toggle()
                        }
                    }

                    // Insight Snippet & Helping Text
                    VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                        Text("AI Reflection") // Clearer title
                           .font(styles.typography.smallLabelFont)
                           .foregroundColor(styles.colors.textSecondary)

                        Text(insightMessage)
                            .font(styles.typography.bodyFont) // Main font for snippet
                            .foregroundColor(styles.colors.text)
                            .lineLimit(2) // Limit lines in collapsed view

                        Text("Tap to reflect deeper on today’s thoughts.") // Helping text
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.accent)
                    }
                    Spacer() // Push content left
                }
                .padding(.vertical, styles.layout.paddingS) // Add vertical padding
            },
            detailContent: {
                // Expanded View: Use AIReflectionDetailContent, pass result data
                AIReflectionDetailContent(
                    insightMessage: insightMessage,
                    reflectionPrompts: reflectionPrompts // Pass loaded/default prompts
                )
            }
        )
        // Add loading logic
        .onAppear(perform: loadInsight)
        .onChange(of: appState.journalEntries.count) { _, _ in loadInsight() } // Reload on entry change
         // Add listener for explicit insight updates
         .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[AIReflectionCard] Received insightsDidUpdate notification.")
             loadInsight()
         }
    }

    // Function to load and decode the insight
    private func loadInsight() {
        guard !isLoading else { return }
        isLoading = true
        loadError = false
        print("[AIReflectionCard] Loading insight...")

        Task {
            do {
                // Use await as loadLatestInsight might become async
                if let (json, _) = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                    if let data = json.data(using: .utf8) {
                        let result = try JSONDecoder().decode(AIReflectionResult.self, from: data)
                        await MainActor.run {
                            reflectionResult = result
                            isLoading = false
                             print("[AIReflectionCard] Insight loaded and decoded.")
                        }
                    } else {
                        throw NSError(domain: "AIReflectionCard", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to Data"])
                    }
                } else {
                    await MainActor.run {
                        reflectionResult = nil
                        isLoading = false
                        print("[AIReflectionCard] No stored insight found.")
                    }
                }
            } catch {
                 await MainActor.run {
                     print("‼️ [AIReflectionCard] Failed to load/decode insight: \(error)")
                     reflectionResult = nil
                     loadError = true
                     isLoading = false
                 }
            }
        }
    }
}

// Update preview provider name to match struct
#Preview {
    ScrollView{
        AIReflectionInsightCard() // Use correct struct name
            // Note: The card itself loads data, but the detail preview needs explicit data.
            // If we want the detail view in preview to show something, we'd need to
            // either pass mock data to the detail view directly in its preview,
            // or set mock data in the card's @State for preview purposes.
            // For now, the card preview itself will load (or show defaults).
            .padding()
            .environmentObject(AppState()) // Provide mock data if needed
            .environmentObject(ChatManager(databaseService: DatabaseService(), llmService: LLMService.shared, subscriptionManager: SubscriptionManager.shared))
             .environmentObject(DatabaseService()) // Also provide DatabaseService
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}