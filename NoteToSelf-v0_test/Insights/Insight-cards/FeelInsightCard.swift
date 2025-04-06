import SwiftUI
import Charts // For mood trend chart

struct FeelInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    @State private var insightResult: FeelInsightResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "feelInsights"

    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header
                    HStack {
                        Text("Feel") // Card Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.accent) // Use accent color for headline
                        Spacer()
                        Image(systemName: "heart.circle.fill") // Example icon
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: 20))
                         if appState.subscriptionTier == .free { // Gating
                            Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                        }
                    }

                    // Content Snippets (Mood Trend + Snapshot)
                    if appState.subscriptionTier == .premium {
                        if isLoading {
                            ProgressView().tint(styles.colors.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 60)
                        } else if loadError {
                            Text("Could not load Feel insights.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.error)
                                .frame(minHeight: 60)
                        } else if let result = insightResult {
                            // Display Mood Trend (Simplified text for collapsed view)
                            if let trendData = result.moodTrendChartData, !trendData.isEmpty {
                                Text("Mood Trend: Recent shifts noted.") // Simple text representation
                                    .font(styles.typography.bodySmall)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .lineLimit(1)
                            } else {
                                Text("Mood Trend: Keep journaling to see trends.")
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                            }

                            // Display Mood Snapshot Text
                            if let snapshot = result.moodSnapshotText, !snapshot.isEmpty {
                                Text(snapshot)
                                    .font(styles.typography.bodySmall)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .lineLimit(2) // Allow a bit more text
                            } else {
                                 Text("Mood Snapshot: Analysis pending more data.")
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                            }
                        } else {
                            Text("Emotional insights available with regular journaling.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.textSecondary)
                                .frame(minHeight: 60)
                        }
                    } else {
                         Text("Unlock emotional pattern insights with Premium.")
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
            print("[FeelInsightCard] Received insightsDidUpdate notification.")
            loadInsight()
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Feel Insights") {
                  FeelDetailContent(
                      result: insightResult ?? .empty(), // Pass result or empty state
                      generatedDate: generatedDate
                  )
              }
              .environmentObject(styles)
              .environmentObject(appState) // Pass necessary environment objects
        }
    }

    private func loadInsight() {
        guard !isLoading else { return }
        isLoading = true
        loadError = false
        print("[FeelInsightCard] Loading insight...")
        Task {
            do {
                if let (json, date) = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                     decodeJSON(json: json, date: date)
                } else {
                    await MainActor.run {
                        insightResult = nil; generatedDate = nil; isLoading = false
                        print("[FeelInsightCard] No stored insight found.")
                    }
                }
            } catch {
                 await MainActor.run {
                     print("‼️ [FeelInsightCard] Failed to load insight: \(error)")
                     insightResult = nil; generatedDate = nil; loadError = true; isLoading = false
                 }
            }
        }
    }

    @MainActor
    private func decodeJSON(json: String, date: Date) {
        print("[FeelInsightCard] Decoding JSON...")
        if let data = json.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601 // Match encoding strategy
                let result = try decoder.decode(FeelInsightResult.self, from: data)
                self.insightResult = result
                self.generatedDate = date
                self.loadError = false
                print("[FeelInsightCard] Decode success.")
            } catch {
                print("‼️ [FeelInsightCard] Failed to decode FeelInsightResult: \(error). JSON: \(json)")
                self.insightResult = nil
                self.generatedDate = date // Keep date even if decode fails? Or nil? Let's nil it.
                self.generatedDate = nil
                self.loadError = true
            }
        } else {
            print("‼️ [FeelInsightCard] Failed to convert JSON string to Data.")
            self.insightResult = nil
            self.generatedDate = nil
            self.loadError = true
        }
        self.isLoading = false
    }
}

#Preview {
    ScrollView {
        FeelInsightCard()
            .padding()
            .environmentObject(AppState())
            .environmentObject(DatabaseService())
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}