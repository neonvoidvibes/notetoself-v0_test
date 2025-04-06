import SwiftUI

struct DailyReflectionInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    @State private var insightResult: DailyReflectionResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "dailyReflection"

    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header
                    HStack {
                        Text("AI Insights") // Card Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text) // Standard color
                        Spacer()
                        // AI Avatar Icon
                         ZStack {
                              Circle()
                                  .fill(styles.colors.accent.opacity(0.2))
                                  .frame(width: 30, height: 30)
                              Image(systemName: "sparkles")
                                  .foregroundColor(styles.colors.accent)
                                  .font(.system(size: 16))
                          }
                         if appState.subscriptionTier == .free { // Gating
                            Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                        }
                    }

                    // Content Snippet (Daily Snapshot)
                    if appState.subscriptionTier == .premium {
                        if isLoading {
                            ProgressView().tint(styles.colors.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 60)
                        } else if loadError {
                            Text("Could not load daily reflection.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.error)
                                .frame(minHeight: 60)
                        } else if let result = insightResult, let snapshot = result.snapshotText, !snapshot.isEmpty {
                             VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                                 Text(snapshot)
                                     .font(styles.typography.bodyFont)
                                     .foregroundColor(styles.colors.text)
                                     .lineLimit(3) // Allow more lines for snapshot
                             }
                             .padding(.bottom, styles.layout.spacingS)

                             // Helping Text
                             Text("Tap for reflection prompts & chat.")
                                 .font(styles.typography.caption)
                                 .foregroundColor(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .leading)

                        } else {
                            Text("Today's reflection available after journaling.")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)
                                .frame(minHeight: 60, alignment: .center)
                        }
                    } else {
                         Text("Unlock daily AI reflections with Premium.")
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
            print("[DailyReflectionCard] Received insightsDidUpdate notification.")
            loadInsight()
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Daily Reflection") {
                  DailyReflectionDetailContent(
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
        print("[DailyReflectionCard] Loading insight...")
        Task {
            do {
                if let (json, date) = try? await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                     await decodeJSON(json: json, date: date)
                } else {
                    await MainActor.run {
                        insightResult = nil; generatedDate = nil; isLoading = false
                        print("[DailyReflectionCard] No stored insight found.")
                    }
                }
            }
        }
    }

    @MainActor
    private func decodeJSON(json: String, date: Date) {
        print("[DailyReflectionCard] Decoding JSON...")
        if let data = json.data(using: .utf8) {
            do {
                let result = try JSONDecoder().decode(DailyReflectionResult.self, from: data)
                self.insightResult = result
                self.generatedDate = date
                self.loadError = false
                print("[DailyReflectionCard] Decode success.")
            } catch {
                print("‼️ [DailyReflectionCard] Failed to decode DailyReflectionResult: \(error). JSON: \(json)")
                self.insightResult = nil
                self.generatedDate = nil
                self.loadError = true
            }
        } else {
            print("‼️ [DailyReflectionCard] Failed to convert JSON string to Data.")
            self.insightResult = nil
            self.generatedDate = nil
            self.loadError = true
        }
        self.isLoading = false
    }
}

#Preview {
    ScrollView {
        DailyReflectionInsightCard()
            .padding()
            .environmentObject(AppState())
            .environmentObject(DatabaseService())
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}