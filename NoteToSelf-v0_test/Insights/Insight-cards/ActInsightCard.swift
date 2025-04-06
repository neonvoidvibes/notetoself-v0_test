import SwiftUI

struct ActInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    @State private var insightResult: ActInsightResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "actInsights"

    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header
                    HStack {
                        Text("Act") // Card Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.accent) // Use accent color for headline
                        Spacer()
                        Image(systemName: "figure.walk.motion") // Example icon
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
                             Text("Could not load Act insights.")
                                 .font(styles.typography.bodySmall)
                                 .foregroundColor(styles.colors.error)
                                 .frame(minHeight: 60)
                         } else if let result = insightResult {
                             // Action Forecast Snippet
                             if let forecast = result.actionForecastText, !forecast.isEmpty {
                                 Text(forecast)
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                                     .lineLimit(2)
                             } else {
                                 Text("Action Forecast: Analysis pending.")
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                             }

                             // Recommendations Snippet (show first one)
                             if let firstRec = result.personalizedRecommendations?.first {
                                 Text("Suggestion: \(firstRec.title)")
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                                     .lineLimit(1)
                                     .padding(.top, styles.layout.spacingS)
                             } else if result.personalizedRecommendations != nil { // Check if array exists but is empty
                                  Text("Recommendations: Check back later.")
                                       .font(styles.typography.bodySmall)
                                       .foregroundColor(styles.colors.textSecondary)
                                       .padding(.top, styles.layout.spacingS)
                             } else {
                                 Text("Recommendations: Analysis pending.")
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                                     .padding(.top, styles.layout.spacingS)
                             }

                         } else {
                              Text("Actionable insights available with regular journaling.")
                                  .font(styles.typography.bodySmall)
                                  .foregroundColor(styles.colors.textSecondary)
                                  .frame(minHeight: 60)
                         }
                    } else {
                         Text("Unlock actionable suggestions with Premium.")
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
            print("[ActInsightCard] Received insightsDidUpdate notification.")
            loadInsight()
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Act Insights") {
                  ActDetailContent(
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
        print("[ActInsightCard] Loading insight...")
        Task {
            do {
                if let (json, date) = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                     decodeJSON(json: json, date: date)
                } else {
                    await MainActor.run {
                        insightResult = nil; generatedDate = nil; isLoading = false
                        print("[ActInsightCard] No stored insight found.")
                    }
                }
            } catch {
                 await MainActor.run {
                     print("‼️ [ActInsightCard] Failed to load insight: \(error)")
                     insightResult = nil; generatedDate = nil; loadError = true; isLoading = false
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
                self.generatedDate = nil
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