import SwiftUI

struct ActInsightCard: View {
     @EnvironmentObject var appState: AppState
     @EnvironmentObject var databaseService: DatabaseService

     // var scrollProxy: ScrollViewProxy? = nil // Removed
     var cardId: String? = nil

     @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    // Keep internal loading for now
    @State private var insightResult: ActInsightResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "actInsights"

     // Helper to get icon based on category string
     private func iconForCategory(_ category: String?) -> String {
         guard let category = category else { return "star.fill" }
         switch category.lowercased() {
         case "experiment": return "testtube.2"
         case "habit": return "repeat.circle.fill"
         case "reflection": return "text.bubble.fill"
         case "planning": return "calendar.badge.clock"
         case "wellbeing": return "heart.fill"
         default: return "sparkles" // Default for other/unknown
         }
     }

    // [5.1] Check if insight is fresh (within 24 hours)
    private var isFresh: Bool {
        guard let genDate = generatedDate else { return false }
        return Calendar.current.dateComponents([.hour], from: genDate, to: Date()).hour ?? 25 < 24
    }

    var body: some View {
        styles.expandableCard(
            // scrollProxy: scrollProxy, // Removed
            // cardId: cardId, // Removed
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header
                    HStack {
                        Text("Actionable Steps") // [6.1] Updated Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        Spacer()

                        // [5.1] Add NEW Badge conditionally
                        if isFresh && appState.subscriptionTier == .pro { // CORRECTED: Check .pro
                            NewBadgeView()
                        }

                        Image(systemName: "play") // Icon
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: 30)) // Increased size
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
                             Text("Couldn't load Act insights.\nPlease try again later.")
                                 .font(styles.typography.bodySmall)
                                 .foregroundColor(styles.colors.error)
                                 .multilineTextAlignment(.center)
                                 .frame(maxWidth: .infinity, alignment: .center)
                                 .frame(minHeight: 60)
                         } else if let result = insightResult {
                            // Show Action Forecast Snippet Primarily with Icon
                             HStack(alignment: .top, spacing: styles.layout.spacingM) {
                                  // Icon for Forecast
                                  Image(systemName: "chart.line.uptrend.xyaxis") // Forecast icon
                                      .foregroundColor(styles.colors.accent)
                                      .font(.system(size: 18))
                                      .frame(width: 24, height: 24)
                                      .padding(.top, 2)

                                 VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                                     if let forecast = result.actionForecastText, !forecast.isEmpty {
                                         Text(forecast)
                                             .font(styles.typography.bodyFont)
                                             .foregroundColor(styles.colors.text)
                                             .lineLimit(3) // Allow more lines
                                     } else {
                                          Text("Action forecast pending...")
                                             .font(styles.typography.bodyFont)
                                             .foregroundColor(styles.colors.text)
                                             .lineLimit(3)
                                     }
                                 }
                             }
                              .padding(.bottom, styles.layout.spacingS)

                             // Helping Text
                             Text("Tap for forecast details & suggestions.")
                                 .font(styles.typography.caption)
                                 .foregroundColor(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .leading)

                         } else {
                              Text("Actionable insights available with regular journaling.")
                                  .font(styles.typography.bodyFont)
                                  .foregroundColor(styles.colors.text)
                                  .frame(minHeight: 60, alignment: .center)
                         }
                    } else {
                         // Use LockedContentView with updated text
                         LockedContentView(message: "Unlock actionable suggestions with Pro.")
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
                print("[ActInsightCard] Locked card tapped. Triggering upgrade flow...")
                // TODO: [8.2] Implement presentation of upgrade/paywall screen for 'Act Insights'.
            }
        }
        .opacity(appState.subscriptionTier == .free ? 0.7 : 1.0) // [8.1] Dim card slightly when locked
        .onAppear(perform: loadInsight)
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
            print("[ActInsightCard] Received insightsDidUpdate notification.")
            loadInsight()
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Actionable Steps") { // [6.1] Updated Detail Title
                  ActDetailContent(
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
        print("[ActInsightCard] Loading insight...")
        Task {
             do {
                 // Adjust tuple destructuring to ignore the third element (contextItem)
                 if let (json, date, _) = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                     decodeJSON(json: json, date: date)
                 } else {
                     await MainActor.run {
                         insightResult = nil; generatedDate = nil; isLoading = false
                         print("[ActInsightCard] No stored insight found.")
                     }
                 }
             } catch {
                 print("‼️ [ActInsightCard] Error loading insight: \(error)")
                 await MainActor.run {
                     insightResult = nil; generatedDate = nil; isLoading = false; loadError = true
                 }
             }
        }
    }

    @MainActor
    private func decodeJSON(json: String, date: Date) {
        print("[ActInsightCard] Decoding JSON...")
        if let data = json.data(using: .utf8) {
            do {
                let result = try JSONDecoder().decode(ActInsightResult.self, from: data)
                self.insightResult = result
                self.generatedDate = date
                self.loadError = false
                print("[ActInsightCard] Decode success.")
            } catch {
                print("‼️ [ActInsightCard] Failed to decode ActInsightResult: \(error). JSON: \(json)")
                self.insightResult = nil
                self.generatedDate = nil // Nil date on error
                self.loadError = true
            }
        } else {
            print("‼️ [ActInsightCard] Failed to convert JSON string to Data.")
            self.insightResult = nil
            self.generatedDate = nil
            self.loadError = true
        }
        self.isLoading = false
    }
}

#Preview {
    ScrollView {
        ActInsightCard()
            .padding()
            .environmentObject(AppState())
            .environmentObject(DatabaseService())
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}