import SwiftUI

struct LearnInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    @State private var insightResult: LearnInsightResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "learnInsights"

    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header - Headline uses standard text color now
                    HStack {
                        Text("Learn") // Card Title - Standard Color
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text) // Use standard text color
                        Spacer()
                        Image(systemName: "graduationcap.circle.fill") // Example icon
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: 20))
                        if appState.subscriptionTier == .free { // Gating
                           Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                       }
                    }

                    // Content Snippets
                    if appState.subscriptionTier == .premium {
                         if isLoading {
                             ProgressView().tint(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .center)
                                 .frame(minHeight: 60)
                         } else if loadError {
                             Text("Could not load Learn insights.")
                                 .font(styles.typography.bodySmall)
                                 .foregroundColor(styles.colors.error)
                                 .frame(minHeight: 60)
                         } else if let result = insightResult {
                            // Show takeaway snippet prominently
                             VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                                 Text("KEY TAKEAWAY")
                                     .font(styles.typography.caption.weight(.bold))
                                     .foregroundColor(styles.colors.textSecondary)
                                 Text(result.takeawayText ?? "Analysis pending...")
                                     .font(styles.typography.bodySmall.weight(.medium)) // Slightly bolder
                                     .foregroundColor(styles.colors.textSecondary)
                                     .lineLimit(3) // Allow more lines for takeaway
                             }

                         } else {
                              Text("Learning insights available with regular journaling.")
                                  .font(styles.typography.bodySmall)
                                  .foregroundColor(styles.colors.textSecondary)
                                  .frame(minHeight: 60, alignment: .center)
                         }
                    } else {
                         Text("Unlock learning summaries and growth insights with Premium.")
                             .font(styles.typography.bodySmall)
                             .foregroundColor(styles.colors.textSecondary)
                             .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                             .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, styles.layout.paddingL)
            }
        )
        .contentShape(Rectangle())
        .onTapGesture { if appState.subscriptionTier == .premium { showingFullScreen = true } }
        .onAppear(perform: loadInsight)
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
            print("[LearnInsightCard] Received insightsDidUpdate notification.")
            loadInsight()
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Learn Insights") {
                  LearnDetailContent(
                      result: insightResult ?? .empty(),
                      generatedDate: generatedDate
                  )
              }
              .environmentObject(styles)
              .environmentObject(appState)
        }
    }

     private func loadInsight() {
        guard !isLoading else { return }
        isLoading = true
        loadError = false
        print("[LearnInsightCard] Loading insight...")
        Task {
            do {
                // Changed to use try? to handle nil case gracefully without throwing
                if let (json, date) = try? await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                     await decodeJSON(json: json, date: date) // Pass both json and date
                } else {
                    await MainActor.run {
                        insightResult = nil; generatedDate = nil; isLoading = false
                        print("[LearnInsightCard] No stored insight found.")
                    }
                }
            }
            // Removed catch block as try? handles errors by returning nil
        }
    }

    @MainActor
    private func decodeJSON(json: String, date: Date) {
        print("[LearnInsightCard] Decoding JSON...")
        if let data = json.data(using: .utf8) {
            do {
                let result = try JSONDecoder().decode(LearnInsightResult.self, from: data)
                self.insightResult = result
                self.generatedDate = date
                self.loadError = false
                print("[LearnInsightCard] Decode success.")
            } catch {
                print("‼️ [LearnInsightCard] Failed to decode LearnInsightResult: \(error). JSON: \(json)")
                self.insightResult = nil
                self.generatedDate = date // Keep date?
                // self.generatedDate = nil // Set date to nil on error
                self.loadError = true
            }
        } else {
            print("‼️ [LearnInsightCard] Failed to convert JSON string to Data.")
            self.insightResult = nil
            self.generatedDate = nil
            self.loadError = true
        }
        self.isLoading = false
    }
}

#Preview {
    ScrollView {
        LearnInsightCard()
            .padding()
            .environmentObject(AppState())
            .environmentObject(DatabaseService())
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}