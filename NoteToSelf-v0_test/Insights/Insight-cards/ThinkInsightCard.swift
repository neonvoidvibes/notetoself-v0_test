import SwiftUI

struct ThinkInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    // Keep internal loading for now
    @State private var insightResult: ThinkInsightResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "thinkInsights"

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
                        Text("Thinking Patterns") // [6.1] Updated Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        Spacer()

                        // [5.1] Add NEW Badge conditionally
                        if isFresh && appState.subscriptionTier == .pro { // CORRECTED: Check .pro
                            NewBadgeView()
                        }

                        Image(systemName: "lightbulb.circle.fill") // [10.1] Updated icon
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: 20))
                        if appState.subscriptionTier == .free { // Gating check is correct (.free)
                            HStack(spacing: 4) { // Group badge and lock
                                ProBadgeView()
                                Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                            }
                       }
                    }

                    // Content Snippets
                    if appState.subscriptionTier == .pro { // CORRECTED: Check .pro
                         if isLoading {
                             ProgressView().tint(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .center)
                                 .frame(minHeight: 60)
                         } else if loadError {
                             // [4.2] Improved Error Message
                             Text("Couldn't load Think insights.\nPlease try again later.")
                                 .font(styles.typography.bodySmall)
                                 .foregroundColor(styles.colors.error)
                                 .multilineTextAlignment(.center)
                                 .frame(maxWidth: .infinity, alignment: .center)
                                 .frame(minHeight: 60)
                         } else if let result = insightResult {
                            // Show Theme Overview Snippet Primarily with Icon
                             HStack(alignment: .top, spacing: styles.layout.spacingM) {
                                 // Icon for Themes
                                 Image(systemName: "tag.fill")
                                     .foregroundColor(styles.colors.accent)
                                     .font(.system(size: 18)) // Slightly smaller icon
                                     .frame(width: 24, height: 24) // Fixed size
                                     .padding(.top, 2)

                                 VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                                     if let overview = result.themeOverviewText, !overview.isEmpty {
                                         Text(overview)
                                             .font(styles.typography.bodyFont)
                                             .foregroundColor(styles.colors.text)
                                             .lineLimit(3) // Allow more lines
                                     } else {
                                         Text("Recurring themes analysis pending...")
                                             .font(styles.typography.bodyFont)
                                             .foregroundColor(styles.colors.text)
                                             .lineLimit(3)
                                     }
                                 }
                             }
                              .padding(.bottom, styles.layout.spacingS)

                             // Helping Text
                             Text("Tap for theme details & value reflection.")
                                 .font(styles.typography.caption)
                                 .foregroundColor(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .leading)

                         } else {
                              Text("Strategic insights available with regular journaling.")
                                  .font(styles.typography.bodyFont)
                                  .foregroundColor(styles.colors.text)
                                  .frame(minHeight: 60, alignment: .center)
                         }
                    } else {
                         // Use LockedContentView with updated text
                         LockedContentView(message: "Unlock strategic thinking insights with Pro.")
                             .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, styles.layout.paddingL)
            }
        )
        .contentShape(Rectangle())
        // [8.2] Updated tap gesture to handle locked state
        .onTapGesture {
            if appState.subscriptionTier == .pro {
                // Pro users can open if content is loaded (or even if loading/error to see status)
                showingFullScreen = true
            } else {
                // Free user tapped locked card
                print("[ThinkInsightCard] Locked card tapped. Triggering upgrade flow...")
                // TODO: [8.2] Implement presentation of upgrade/paywall screen for 'Think Insights'.
            }
        }
        .opacity(appState.subscriptionTier == .free ? 0.7 : 1.0) // [8.1] Dim card slightly when locked
        .onAppear(perform: loadInsight)
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
            print("[ThinkInsightCard] Received insightsDidUpdate notification.")
            loadInsight()
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Thinking Patterns") { // [6.1] Updated Detail Title
                  ThinkDetailContent(
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
        print("[ThinkInsightCard] Loading insight...")
        Task {
             do {
                 if let (json, date) = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                      decodeJSON(json: json, date: date)
                 } else {
                     await MainActor.run {
                         insightResult = nil; generatedDate = nil; isLoading = false
                         print("[ThinkInsightCard] No stored insight found.")
                     }
                 }
             } catch {
                 print("‼️ [ThinkInsightCard] Error loading insight: \(error)")
                 await MainActor.run {
                     insightResult = nil; generatedDate = nil; isLoading = false; loadError = true
                 }
             }
        }
    }

    @MainActor
    private func decodeJSON(json: String, date: Date) {
        print("[ThinkInsightCard] Decoding JSON...")
        if let data = json.data(using: .utf8) {
            do {
                let result = try JSONDecoder().decode(ThinkInsightResult.self, from: data)
                self.insightResult = result
                self.generatedDate = date
                self.loadError = false
                print("[ThinkInsightCard] Decode success.")
            } catch {
                print("‼️ [ThinkInsightCard] Failed to decode ThinkInsightResult: \(error). JSON: \(json)")
                self.insightResult = nil
                self.generatedDate = nil // Nil date on error
                self.loadError = true
            }
        } else {
            print("‼️ [ThinkInsightCard] Failed to convert JSON string to Data.")
            self.insightResult = nil
            self.generatedDate = nil
            self.loadError = true
        }
        self.isLoading = false
    }
}

#Preview {
    ScrollView {
        ThinkInsightCard()
            .padding()
            .environmentObject(AppState())
            .environmentObject(DatabaseService())
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}