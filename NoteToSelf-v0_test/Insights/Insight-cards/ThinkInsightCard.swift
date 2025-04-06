import SwiftUI

struct ThinkInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    @State private var insightResult: ThinkInsightResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "thinkInsights"

    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header
                    HStack {
                        Text("Think") // Card Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.accent) // Use accent color for headline
                        Spacer()
                        Image(systemName: "brain.head.profile") // Example icon
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
                             Text("Could not load Think insights.")
                                 .font(styles.typography.bodySmall)
                                 .foregroundColor(styles.colors.error)
                                 .frame(minHeight: 60)
                         } else if let result = insightResult {
                             if let overview = result.themeOverviewText, !overview.isEmpty {
                                 Text(overview)
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                                     .lineLimit(2)
                             } else {
                                 Text("Theme Overview: Analysis pending.")
                                      .font(styles.typography.bodySmall)
                                      .foregroundColor(styles.colors.textSecondary)
                             }
                             if let reflection = result.valueReflectionText, !reflection.isEmpty {
                                 Text(reflection)
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                                     .lineLimit(2)
                                     .padding(.top, styles.layout.spacingS) // Add spacing between snippets
                             } else {
                                  Text("Value Reflection: Analysis pending.")
                                       .font(styles.typography.bodySmall)
                                       .foregroundColor(styles.colors.textSecondary)
                                       .padding(.top, styles.layout.spacingS)
                             }
                         } else {
                              Text("Strategic insights available with regular journaling.")
                                  .font(styles.typography.bodySmall)
                                  .foregroundColor(styles.colors.textSecondary)
                                  .frame(minHeight: 60)
                         }
                     } else {
                          Text("Unlock strategic thinking insights with Premium.")
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
            print("[ThinkInsightCard] Received insightsDidUpdate notification.")
            loadInsight()
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Think Insights") {
                  ThinkDetailContent(
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
        print("[ThinkInsightCard] Loading insight...")
        Task {
            do {
                if let (json, date) = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                     decodeJSON(json: json, date: date)
                } else {
                    await MainActor.run {
                        insightResult = nil; generatedDate = nil; isLoading = false
                        print("[ThinkInsightCard] No stored insight found.")
                    }
                }
            } catch {
                 await MainActor.run {
                     print("‼️ [ThinkInsightCard] Failed to load insight: \(error)")
                     insightResult = nil; generatedDate = nil; loadError = true; isLoading = false
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
                self.generatedDate = nil
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