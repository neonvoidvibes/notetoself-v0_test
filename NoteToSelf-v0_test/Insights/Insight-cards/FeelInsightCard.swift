import SwiftUI
import Charts // For mood trend chart

struct FeelInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    // Keep internal loading logic for now
    @State private var insightResult: FeelInsightResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "feelInsights"


    // Helper to get Mood enum from name string
     private func moodFromName(_ name: String?) -> Mood? {
         guard let name = name else { return nil }
         return Mood.allCases.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
     }

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
                        Text("Emotional Patterns") // [6.1] Updated Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        Spacer()

                        // [5.1] Add NEW Badge conditionally
                        if isFresh && appState.subscriptionTier == .pro { // CORRECTED: Check .pro
                            NewBadgeView()
                        }

                        Image(systemName: "bolt") // Icon
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
                                .frame(minHeight: 100) // Increase min height to account for chart
                        } else if loadError {
                            // [4.2] Improved Error Message
                            Text("Couldn't load Feel insights.\nPlease try again later.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.error)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 100) // Increase min height
                        } else if let result = insightResult {
                            // Display Dominant Mood Icon + Snapshot Text in HStack
                            HStack(alignment: .top, spacing: styles.layout.spacingM) {
                                // Dominant Mood Icon (Visual Element)
                                if let dominantMoodName = result.dominantMood, let moodEnum = moodFromName(dominantMoodName) {
                                     moodEnum.icon
                                         .foregroundColor(moodEnum.color)
                                         .font(.system(size: 24))
                                         .frame(width: 24, height: 24)
                                         .padding(.top, 2)
                                } else {
                                     Image(systemName: "circle.dashed")
                                          .foregroundColor(styles.colors.textSecondary)
                                          .font(.system(size: 24))
                                          .frame(width: 24, height: 24)
                                          .padding(.top, 2)
                                }

                                // Snapshot Text
                                VStack(alignment: .leading, spacing: styles.layout.spacingXS){
                                    if let snapshot = result.moodSnapshotText, !snapshot.isEmpty {
                                        Text(snapshot)
                                            .font(styles.typography.bodyFont)
                                            .foregroundColor(styles.colors.text)
                                            .lineLimit(2) // Limit snapshot text to 2 lines
                                    } else {
                                        Text("Emotional snapshot analysis pending.")
                                             .font(styles.typography.bodyFont)
                                             .foregroundColor(styles.colors.text)
                                             .lineLimit(2)
                                    }
                                }
                            }
                            .padding(.bottom, styles.layout.spacingS) // Space between text and chart

                            // [3.1] Mini Sparkline Chart
                             if #available(iOS 16.0, *) {
                                 if let chartData = result.moodTrendChartData, !chartData.isEmpty {
                                     MiniSparklineChart(
                                         data: chartData,
                                         gradient: LinearGradient(
                                             colors: [styles.colors.accent, styles.colors.accent.opacity(0.5)], // Use accent gradient
                                             startPoint: .leading,
                                             endPoint: .trailing
                                         )
                                     )
                                      // Add padding around chart
                                     .padding(.vertical, styles.layout.spacingXS)
                                 } else {
                                     // Optional: Placeholder if chart data is missing but insight exists
                                     Rectangle()
                                          .fill(styles.colors.secondaryBackground.opacity(0.5))
                                          .frame(height: 50)
                                          .cornerRadius(styles.layout.radiusM)
                                          .overlay(Text("Chart data unavailable").font(.caption).foregroundColor(styles.colors.textSecondary))
                                          .padding(.vertical, styles.layout.spacingXS)
                                 }
                             }

                             // Helping Text
                             Text("Tap for mood chart & details.")
                                 .font(styles.typography.caption)
                                 .foregroundColor(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .leading)
                                 .padding(.top, styles.layout.spacingXS) // Space above helping text

                        } else {
                            Text("Emotional insights available with regular journaling.")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)
                                .frame(minHeight: 100, alignment: .center) // Increase min height
                        }
                    } else {
                         // Use LockedContentView with updated text
                         LockedContentView(message: "Unlock emotional pattern insights with Pro.")
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
                print("[FeelInsightCard] Locked card tapped. Triggering upgrade flow...")
                // TODO: [8.2] Implement presentation of upgrade/paywall screen for 'Feel Insights'.
            }
        }
        .opacity(appState.subscriptionTier == .free ? 0.7 : 1.0) // [8.1] Dim card slightly when locked
        .onAppear(perform: loadInsight) // Still load internally on appear
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
            print("[FeelInsightCard] Received insightsDidUpdate notification.")
            loadInsight() // Reload internal data on notification
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Emotional Patterns") { // [6.1] Updated Detail Title
                  FeelDetailContent(
                      result: insightResult ?? .empty(),
                      generatedDate: generatedDate
                  )
              }
              .environmentObject(styles)
              .environmentObject(appState)
        }
    }

    // Keep internal loading logic for now
    private func loadInsight() {
        guard !isLoading else { return }
        isLoading = true
        loadError = false
        print("[FeelInsightCard] Loading insight...")
        Task {
            do {
                if let (json, date) = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                    decodeJSON(json: json, date: date)
                } else {
                    await MainActor.run {
                        insightResult = nil; generatedDate = nil; isLoading = false
                        print("[FeelInsightCard] No stored insight found.")
                    }
                }
            } catch {
                print("‼️ [FeelInsightCard] Error loading insight: \(error)")
                await MainActor.run {
                    insightResult = nil; generatedDate = nil; isLoading = false; loadError = true
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
                // Decoder strategy already set in Models.swift for MoodTrendPoint
                // decoder.dateDecodingStrategy = .iso8601
                let result = try decoder.decode(FeelInsightResult.self, from: data)
                self.insightResult = result
                self.generatedDate = date
                self.loadError = false
                print("[FeelInsightCard] Decode success.")
            } catch {
                print("‼️ [FeelInsightCard] Failed to decode FeelInsightResult: \(error). JSON: \(json)")
                self.insightResult = nil
                self.generatedDate = nil // Nil date on error
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