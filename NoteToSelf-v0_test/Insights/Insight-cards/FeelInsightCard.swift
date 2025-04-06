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

    // Helper to get a simple trend direction indicator
    private var trendIndicator: String {
        guard let data = insightResult?.moodTrendChartData, data.count >= 2 else { return "" }
        let lastValue = data.last?.moodValue ?? 0
        let firstValue = data.first?.moodValue ?? 0
        if lastValue > firstValue + 0.5 { return "arrow.up.right" }
        if lastValue < firstValue - 0.5 { return "arrow.down.right" }
        return "arrow.forward" // Changed from "" to "arrow.forward" for neutral trend
    }

    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header - Headline uses standard text color now
                    HStack {
                        Text("Feel") // Card Title - Standard Color
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text) // Use standard text color
                        Spacer()
                        Image(systemName: "heart.circle.fill") // Example icon
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: 20))
                         if appState.subscriptionTier == .free { // Gating
                            Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                        }
                    }

                    // Content Snippets (More dynamic layout)
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
                            HStack(alignment: .top, spacing: styles.layout.spacingM) {
                                // Left side: Trend Indicator
                                VStack {
                                    Image(systemName: trendIndicator)
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(styles.colors.accent)
                                    Text("Trend")
                                        .font(styles.typography.caption)
                                        .foregroundColor(styles.colors.textSecondary)
                                }
                                .frame(width: 50) // Give indicator some space

                                // Right side: Snapshot text
                                VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                                    Text("Mood Snapshot")
                                        .font(styles.typography.bodyLarge.weight(.semibold)) // Use BodyLarge
                                        .foregroundColor(styles.colors.text) // Use standard text color

                                    if let snapshot = result.moodSnapshotText, !snapshot.isEmpty {
                                        Text(snapshot)
                                            .font(styles.typography.bodySmall)
                                            .foregroundColor(styles.colors.textSecondary)
                                            .lineLimit(3) // Allow more lines for snapshot
                                    } else {
                                        Text("Snapshot analysis pending more data.")
                                            .font(styles.typography.bodySmall)
                                            .foregroundColor(styles.colors.textSecondary)
                                    }
                                }
                                Spacer() // Push text left
                            }
                        } else {
                            Text("Emotional insights available with regular journaling.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.textSecondary)
                                .frame(minHeight: 60, alignment: .center)
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
                // Changed to use try? to handle nil case gracefully without throwing
                if let (json, date) = try? await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                    await decodeJSON(json: json, date: date) // Pass both json and date
                } else {
                    await MainActor.run {
                        insightResult = nil; generatedDate = nil; isLoading = false
                        print("[FeelInsightCard] No stored insight found.")
                    }
                }
            }
            // Removed catch block as try? handles errors by returning nil
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
                self.generatedDate = date // Keep date even if decode fails? Or nil? Let's keep it for now.
                // self.generatedDate = nil // Set date to nil on error
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