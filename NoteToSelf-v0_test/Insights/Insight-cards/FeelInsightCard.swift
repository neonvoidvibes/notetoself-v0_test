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

    // Helper to get Mood enum from name string
     private func moodFromName(_ name: String?) -> Mood? {
         guard let name = name else { return nil }
         return Mood.allCases.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
     }

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
                            .foregroundColor(styles.colors.text)
                        Spacer()
                        Image(systemName: "heart.circle.fill") // Icon
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
                            Text("Could not load Feel insights.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.error)
                                .frame(minHeight: 60)
                        } else if let result = insightResult {
                            // Display Dominant Mood Icon + Snapshot Text in HStack
                            HStack(alignment: .top, spacing: styles.layout.spacingM) {
                                // Dominant Mood Icon (Visual Element)
                                if let dominantMoodName = result.dominantMood, let moodEnum = moodFromName(dominantMoodName) {
                                     moodEnum.icon
                                         .foregroundColor(moodEnum.color)
                                         .font(.system(size: 24)) // Slightly larger icon for emphasis
                                         .frame(width: 24, height: 24) // Fixed size
                                         .padding(.top, 2) // Align icon slightly better with text
                                } else {
                                     // Placeholder if no dominant mood
                                     Image(systemName: "circle.dashed")
                                          .foregroundColor(styles.colors.textSecondary)
                                          .font(.system(size: 24))
                                          .frame(width: 24, height: 24)
                                          .padding(.top, 2)
                                }

                                // Snapshot Text
                                VStack(alignment: .leading, spacing: styles.layout.spacingXS){ // Wrap text in VStack if needed
                                    if let snapshot = result.moodSnapshotText, !snapshot.isEmpty {
                                        Text(snapshot)
                                            .font(styles.typography.bodyFont)
                                            .foregroundColor(styles.colors.text)
                                            .lineLimit(3) // Allow enough lines for snapshot
                                    } else {
                                        Text("Emotional snapshot analysis pending.")
                                             .font(styles.typography.bodyFont)
                                             .foregroundColor(styles.colors.text)
                                    }
                                }
                            }
                             .padding(.bottom, styles.layout.spacingS)

                             // Helping Text
                             Text("Tap for mood chart & details.")
                                 .font(styles.typography.caption)
                                 .foregroundColor(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .leading)

                        } else {
                            Text("Emotional insights available with regular journaling.")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)
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
        print("[FeelInsightCard] Loading insight...")
        Task {
            do {
                if let (json, date) = try? await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                    await decodeJSON(json: json, date: date)
                } else {
                    await MainActor.run {
                        insightResult = nil; generatedDate = nil; isLoading = false
                        print("[FeelInsightCard] No stored insight found.")
                    }
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
                decoder.dateDecodingStrategy = .iso8601
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