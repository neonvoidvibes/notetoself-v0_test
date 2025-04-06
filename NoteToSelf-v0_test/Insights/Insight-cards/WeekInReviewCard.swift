import SwiftUI

struct WeekInReviewCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    @State private var insightResult: WeekInReviewResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "weekInReview"

    // Calculate if the insight is fresh (generated within last 24 hours)
    private var isFresh: Bool {
        guard let genDate = generatedDate else { return false }
        return Calendar.current.dateComponents([.hour], from: genDate, to: Date()).hour ?? 25 < 24
    }

    // Format the date range string
    private var summaryPeriod: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // e.g., "Oct 20"

        guard let start = insightResult?.startDate, let end = insightResult?.endDate else {
            // Attempt to calculate based on today if no data loaded
            let calendar = Calendar.current
            guard let today = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date()),
                  let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
                  let startOfWeek = calendar.date(byAdding: .day, value: -7, to: sunday), // Previous Sunday
                  let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else { // Previous Saturday
                return "Previous Week"
            }
            return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
        }
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header with Date Range and NEW badge
                    HStack {
                        Text("Week in Review") // Card Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text) // Standard color

                        Spacer()

                         Text(summaryPeriod) // Date range on the right
                             .font(styles.typography.caption.weight(.medium))
                             .foregroundColor(styles.colors.textSecondary)

                        if isFresh && appState.subscriptionTier == .premium {
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(styles.colors.accentContrastText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(styles.colors.accent.opacity(0.9))
                                .clipShape(Capsule())
                        }
                        if appState.subscriptionTier == .free { // Gating
                            Image(systemName: "lock.fill")
                                .foregroundColor(styles.colors.textSecondary)
                                .padding(.leading, 4) // Space before lock
                        }
                    }

                    // Content Snippet (Summary Text)
                    if appState.subscriptionTier == .premium {
                        if isLoading {
                            ProgressView().tint(styles.colors.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 60)
                        } else if loadError {
                            Text("Could not load weekly review.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.error)
                                .frame(minHeight: 60)
                        } else if let result = insightResult, let summary = result.summaryText, !summary.isEmpty {
                             VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                                 Text(summary)
                                     .font(styles.typography.bodyFont)
                                     .foregroundColor(styles.colors.text)
                                     .lineLimit(3) // Allow more lines for summary
                             }
                              .padding(.bottom, styles.layout.spacingS)

                             // Helping Text
                             Text("Tap for weekly patterns & insights.")
                                 .font(styles.typography.caption)
                                 .foregroundColor(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .leading)

                        } else {
                            Text("Weekly review available after a week of journaling.")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)
                                .frame(minHeight: 60, alignment: .center)
                        }
                    } else {
                         Text("Unlock weekly reviews and pattern analysis with Premium.")
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
            print("[WeekInReviewCard] Received insightsDidUpdate notification.")
            loadInsight()
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Week in Review") {
                  WeekInReviewDetailContent(
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
        print("[WeekInReviewCard] Loading insight...")
        Task {
            do {
                if let (json, date) = try? await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                     await decodeJSON(json: json, date: date)
                } else {
                    await MainActor.run {
                        insightResult = nil; generatedDate = nil; isLoading = false
                        print("[WeekInReviewCard] No stored insight found.")
                    }
                }
            }
        }
    }

    @MainActor
    private func decodeJSON(json: String, date: Date) {
        print("[WeekInReviewCard] Decoding JSON...")
        if let data = json.data(using: .utf8) {
            do {
                 let decoder = JSONDecoder()
                 decoder.dateDecodingStrategy = .iso8601 // Match encoding strategy
                let result = try decoder.decode(WeekInReviewResult.self, from: data)
                self.insightResult = result
                self.generatedDate = date
                self.loadError = false
                print("[WeekInReviewCard] Decode success.")
            } catch {
                print("‼️ [WeekInReviewCard] Failed to decode WeekInReviewResult: \(error). JSON: \(json)")
                self.insightResult = nil
                self.generatedDate = nil
                self.loadError = true
            }
        } else {
            print("‼️ [WeekInReviewCard] Failed to convert JSON string to Data.")
            self.insightResult = nil
            self.generatedDate = nil
            self.loadError = true
        }
        self.isLoading = false
    }
}

#Preview {
    ScrollView {
        WeekInReviewCard()
            .padding()
            .environmentObject(AppState())
            .environmentObject(DatabaseService())
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}