import SwiftUI

struct LearnInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    @State private var insightResult: LearnInsightResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "learnInsights"

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
                            .foregroundColor(styles.colors.accent) // Use accent color for headline
                        Spacer()
                        Image(systemName: "graduationcap.circle.fill") // Example icon
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
                             Text("Could not load Learn insights.")
                                 .font(styles.typography.bodySmall)
                                 .foregroundColor(styles.colors.error)
                                 .frame(minHeight: 60)
                         } else if let result = insightResult {
                            // Show takeaway snippet
                             if let takeaway = result.takeawayText, !takeaway.isEmpty {
                                 Text(takeaway)
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                                     .lineLimit(2)
                             } else {
                                 Text("Key Takeaway: Analysis pending.")
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                             }
                             // Show next step snippet
                              if let nextStep = result.nextStepText, !nextStep.isEmpty {
                                  Text("Next Step: \(nextStep)")
                                      .font(styles.typography.bodySmall)
                                      .foregroundColor(styles.colors.textSecondary)
                                      .lineLimit(1)
                                      .padding(.top, styles.layout.spacingS)
                              } else {
                                   Text("Next Step: Analysis pending.")
                                       .font(styles.typography.bodySmall)
                                       .foregroundColor(styles.colors.textSecondary)
                                       .padding(.top, styles.layout.spacingS)
                              }

                         } else {
                              Text("Learning insights available with regular journaling.")
                                  .font(styles.typography.bodySmall)
                                  .foregroundColor(styles.colors.textSecondary)
                                  .frame(minHeight: 60)
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

     private func loadInsight() {
        guard !isLoading else { return }
        isLoading = true
        loadError = false
        print("[LearnInsightCard] Loading insight...")
        Task {
            do {
                if let (json, date) = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                     decodeJSON(json: json, date: date)
                } else {
                    await MainActor.run {
                        insightResult = nil; generatedDate = nil; isLoading = false
                        print("[LearnInsightCard] No stored insight found.")
                    }
                }
            } catch {
                 await MainActor.run {
                     print("‼️ [LearnInsightCard] Failed to load insight: \(error)")
                     insightResult = nil; generatedDate = nil; loadError = true; isLoading = false
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
                self.generatedDate = nil
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