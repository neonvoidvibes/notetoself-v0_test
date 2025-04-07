import SwiftUI

struct LearnInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    // Keep internal loading for now
    @State private var insightResult: LearnInsightResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "learnInsights"

    // [5.1] Check if insight is fresh (within 24 hours)
    private var isFresh: Bool {
        guard let genDate = generatedDate else { return false }
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
                        Text("Learn") // Card Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        Spacer()

                        // [5.1] Add NEW Badge conditionally
                        if isFresh && appState.subscriptionTier == .premium {
                            NewBadgeView()
                        }

                        Image(systemName: "graduationcap.circle.fill") // Icon
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
                             // [4.2] Improved Error Message
                             Text("Couldn't load Learn insights.\nPlease try again later.")
                                 .font(styles.typography.bodySmall)
                                 .foregroundColor(styles.colors.error)
                                 .multilineTextAlignment(.center)
                                 .frame(maxWidth: .infinity, alignment: .center)
                                 .frame(minHeight: 60)
                         } else if let result = insightResult {
                            // Show Takeaway Snippet Primarily with Icon
                             HStack(alignment: .top, spacing: styles.layout.spacingM) {
                                 // Icon for Takeaway/Learning
                                 Image(systemName: "lightbulb.fill") // Learning icon
                                     .foregroundColor(styles.colors.accent)
                                     .font(.system(size: 18))
                                     .frame(width: 24, height: 24)
                                     .padding(.top, 2)

                                 VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                                     if let takeaway = result.takeawayText, !takeaway.isEmpty {
                                         Text(takeaway)
                                             .font(styles.typography.bodyFont)
                                             .foregroundColor(styles.colors.text)
                                             .lineLimit(3) // Allow more lines
                                     } else {
                                          Text("Weekly learning analysis pending...")
                                             .font(styles.typography.bodyFont)
                                             .foregroundColor(styles.colors.text)
                                             .lineLimit(3)
                                     }
                                 }
                             }
                              .padding(.bottom, styles.layout.spacingS)

                             // Helping Text
                             Text("Tap for takeaway details & next step.")
                                 .font(styles.typography.caption)
                                 .foregroundColor(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .leading)

                         } else {
                              Text("Learning insights available with regular journaling.")
                                  .font(styles.typography.bodyFont)
                                  .foregroundColor(styles.colors.text)
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

     // Keep internal loading logic
     private func loadInsight() {
        guard !isLoading else { return }
        isLoading = true
        loadError = false
        print("[LearnInsightCard] Loading insight...")
        Task {
             do {
                 if let (json, date) = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                      decodeJSON(json: json, date: date)
                 } else {
                     await MainActor.run {
                         insightResult = nil; generatedDate = nil; isLoading = false
                         print("[LearnInsightCard] No stored insight found.")
                     }
                 }
             } catch {
                 print("‼️ [LearnInsightCard] Error loading insight: \(error)")
                 await MainActor.run {
                     insightResult = nil; generatedDate = nil; isLoading = false; loadError = true
                 }
             }
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
                self.generatedDate = nil // Nil date on error
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