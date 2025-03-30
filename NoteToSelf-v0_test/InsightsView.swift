import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var databaseService: DatabaseService
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled

    @State private var selectedMonth: Date = Date()
    @Binding var tabBarOffset: CGFloat
    @Binding var lastScrollPosition: CGFloat
    @Binding var tabBarVisible: Bool

    // State for stored insights
    @State private var storedWeeklySummary: WeeklySummaryResult? = nil
    @State private var storedWeeklySummaryDate: Date? = nil
    @State private var storedMoodTrend: MoodTrendResult? = nil
    @State private var storedMoodTrendDate: Date? = nil
    @State private var storedRecommendations: RecommendationResult? = nil
    @State private var storedRecommendationsDate: Date? = nil
    @State private var isLoadingInsights: Bool = false // Keep loading state

    private let styles = UIStyles.shared

    private var isWeeklySummaryFresh: Bool {
        guard let generatedDate = storedWeeklySummaryDate else { return false }
        return Calendar.current.dateComponents([.hour], from: generatedDate, to: Date()).hour ?? 25 < 24
    }

    // Computed property to check if the user has any entries at all
    private var hasAnyEntries: Bool {
        !appState.journalEntries.isEmpty
    }

    var body: some View {
        ZStack {
            styles.colors.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header (remains the same)
                ZStack(alignment: .center) {
                    VStack(spacing: 8) {
                        Text("Insights")
                            .font(styles.typography.title1)
                            .foregroundColor(styles.colors.text)
                        Rectangle().fill(styles.colors.accent).frame(width: 20, height: 3)
                    }
                    HStack {
                        Button(action: { NotificationCenter.default.post(name: NSNotification.Name("ToggleSettings"), object: nil) }) {
                            VStack(spacing: 6) {
                                HStack { Rectangle().fill(styles.colors.accent).frame(width: 28, height: 2); Spacer() }
                                HStack { Rectangle().fill(styles.colors.accent).frame(width: 20, height: 2); Spacer() }
                            }.frame(width: 36, height: 36)
                        }
                        Spacer()
                    }.padding(.horizontal, styles.layout.paddingXL)
                }
                .padding(.top, 8)
                .padding(.bottom, 8)

                // Main content ScrollView
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scrollView")).minY)
                    }.frame(height: 0)

                    // Initial Empty State (if no entries at all)
                    if !hasAnyEntries {
                        VStack(spacing: styles.layout.spacingL) {
                            Spacer(minLength: 100)
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 60))
                                .foregroundColor(styles.colors.accent.opacity(0.7))
                            Text("Unlock Your Insights")
                                .font(styles.typography.title1)
                                .foregroundColor(styles.colors.text)
                            Text("Start journaling regularly to discover patterns and receive personalized insights here.")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, styles.layout.paddingXL)
                            Spacer()
                        }
                        .padding(.vertical, 50)
                    } else {
                        // Regular Content (Header + Cards)
                        VStack(alignment: .center, spacing: styles.layout.spacingL) {
                            Text("My Insights")
                                .font(styles.typography.headingFont)
                                .foregroundColor(styles.colors.text)
                                .padding(.bottom, 4)
                            Text("Discover patterns, make better choices.")
                                .font(styles.typography.bodyLarge)
                                .foregroundColor(styles.colors.accent)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, styles.layout.paddingXL)
                        .padding(.vertical, styles.layout.spacingXL * 1.5)
                        .padding(.top, 80)
                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [styles.colors.appBackground, styles.colors.appBackground.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                        )

                        // Loading Indicator or Cards
                        if isLoadingInsights {
                            ProgressView("Loading Insights...")
                                .padding(.vertical, 50)
                                .tint(styles.colors.accent)
                        } else {
                            VStack(spacing: styles.layout.cardSpacing) {
                                // Subscription Tier Toggle (for testing)
                                #if DEBUG
                                HStack {
                                    Text("Subscription Mode:")
                                        .font(styles.typography.bodySmall)
                                        .foregroundColor(styles.colors.textSecondary)
                                    Picker("", selection: $appState.subscriptionTier) {
                                        Text("Free").tag(SubscriptionTier.free)
                                        Text("Premium").tag(SubscriptionTier.premium)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .frame(width: 200)
                                }
                                .padding(.horizontal, styles.layout.paddingXL)
                                .padding(.top, 8)
                                #endif

                                // Today's Highlights Section
                                styles.sectionHeader("Today's Highlights")

                                // Streak Card
                                StreakInsightCard(streak: appState.currentStreak)
                                    .padding(.horizontal, styles.layout.paddingXL)

                                // Weekly Summary Card
                                WeeklySummaryInsightCard(
                                    summaryResult: storedWeeklySummary,
                                    generatedDate: storedWeeklySummaryDate,
                                    isFresh: isWeeklySummaryFresh,
                                    subscriptionTier: appState.subscriptionTier // Pass tier
                                )
                                .padding(.horizontal, styles.layout.paddingXL)

                                // Deeper Insights Section
                                styles.sectionHeader("Deeper Insights")

                                // AI Reflection Card
                                ChatInsightCard()
                                    .padding(.horizontal, styles.layout.paddingXL)
                                    .accessibilityLabel("AI Reflection")

                                // Mood Analysis Card
                                MoodTrendsInsightCard(
                                    trendResult: storedMoodTrend,
                                    generatedDate: storedMoodTrendDate,
                                    subscriptionTier: appState.subscriptionTier // Pass tier
                                )
                                .padding(.horizontal, styles.layout.paddingXL)
                                .accessibilityLabel("Mood Analysis")

                                // Recommendations Card
                                RecommendationsInsightCard(
                                    recommendationResult: storedRecommendations,
                                    generatedDate: storedRecommendationsDate,
                                    subscriptionTier: appState.subscriptionTier // Pass tier
                                )
                                .padding(.horizontal, styles.layout.paddingXL)
                                .padding(.bottom, styles.layout.paddingXL + 80)

                            } // End VStack for cards
                        } // End else (isLoadingInsights)
                    } // End else (hasAnyEntries)
                } // End ScrollView
                .coordinateSpace(name: "scrollView")
                .disabled(mainScrollingDisabled)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    let scrollingDown = value < lastScrollPosition
                    if abs(value - lastScrollPosition) > 10 {
                        if scrollingDown { tabBarOffset = 100; tabBarVisible = false }
                        else { tabBarOffset = 0; tabBarVisible = true }
                        lastScrollPosition = value
                    }
                }
            } // End Outer VStack
        } // End ZStack
        .onAppear {
            loadStoredInsights()
        }
        // Add listener for insight updates
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[InsightsView] Received insightsDidUpdate notification. Reloading insights.")
             loadStoredInsights()
         }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToTab"))) { notification in
            if let userInfo = notification.userInfo, let tabIndex = userInfo["tabIndex"] as? Int {
                NotificationCenter.default.post(name: NSNotification.Name("SwitchTab"), object: nil, userInfo: ["tabIndex": tabIndex])
            }
        }
    } // End body

    // --- Data Loading ---
    private func loadStoredInsights() {
        // Don't skip loading based on tier here, let cards handle display logic
        // guard appState.subscriptionTier == .premium else { ... }

        Task {
            isLoadingInsights = true // Set loading state
            print("[InsightsView] Loading stored insights from DB...")

            // Run DB calls in background task
            let summaryResult = await Task.detached { try? self.databaseService.loadLatestInsight(type: "weeklySummary") }.value
            let moodTrendResult = await Task.detached { try? self.databaseService.loadLatestInsight(type: "moodTrend") }.value
            let recommendationsResult = await Task.detached { try? self.databaseService.loadLatestInsight(type: "recommendation") }.value

            // Process results back on main thread
            await MainActor.run {
                // Process Weekly Summary
                if let (json, date) = summaryResult {
                    if let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode(WeeklySummaryResult.self, from: data) {
                        storedWeeklySummary = decoded
                        storedWeeklySummaryDate = date
                        print("[InsightsView] Loaded Weekly Summary (Generated: \(date.formatted()))")
                    } else {
                        print("⚠️ [InsightsView] Failed to decode Weekly Summary JSON.")
                        storedWeeklySummary = nil // Clear potentially stale data
                        storedWeeklySummaryDate = nil
                    }
                } else {
                     print("[InsightsView] No stored Weekly Summary found.")
                     storedWeeklySummary = nil
                     storedWeeklySummaryDate = nil
                }

                // Process Mood Trend
                if let (json, date) = moodTrendResult {
                     if let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode(MoodTrendResult.self, from: data) {
                         storedMoodTrend = decoded
                         storedMoodTrendDate = date
                         print("[InsightsView] Loaded Mood Trend (Generated: \(date.formatted()))")
                     } else {
                         print("⚠️ [InsightsView] Failed to decode Mood Trend JSON.")
                         storedMoodTrend = nil
                         storedMoodTrendDate = nil
                     }
                 } else {
                      print("[InsightsView] No stored Mood Trend found.")
                      storedMoodTrend = nil
                      storedMoodTrendDate = nil
                 }

                // Process Recommendations
                 if let (json, date) = recommendationsResult {
                     if let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode(RecommendationResult.self, from: data) {
                         storedRecommendations = decoded
                         storedRecommendationsDate = date
                         print("[InsightsView] Loaded Recommendations (Generated: \(date.formatted()))")
                     } else {
                         print("⚠️ [InsightsView] Failed to decode Recommendations JSON.")
                         storedRecommendations = nil
                         storedRecommendationsDate = nil
                     }
                 } else {
                      print("[InsightsView] No stored Recommendations found.")
                      storedRecommendations = nil
                      storedRecommendationsDate = nil
                 }

                isLoadingInsights = false // Clear loading state
                print("[InsightsView] Finished loading insights.")
            } // End MainActor.run
        } // End Task
    }
} // End InsightsView struct

// MARK: - Preview Provider
struct InsightsView_Previews: PreviewProvider {
    @StateObject static var databaseService = DatabaseService()
    static var llmService = LLMService.shared
    @StateObject static var subscriptionManager = SubscriptionManager.shared
    @StateObject static var appState = AppState()
    @StateObject static var chatManager = ChatManager(
        databaseService: databaseService,
        llmService: llmService,
        subscriptionManager: subscriptionManager
    )

    static var previews: some View {
        PreviewDataLoadingContainer {
            InsightsView(
                tabBarOffset: .constant(0),
                lastScrollPosition: .constant(0),
                tabBarVisible: .constant(true)
            )
            .environmentObject(appState)
            .environmentObject(chatManager)
            .environmentObject(databaseService)
            .environmentObject(subscriptionManager)
        }
    }

    // Helper container view to load preview data asynchronously
    struct PreviewDataLoadingContainer<Content: View>: View {
        @ViewBuilder let content: Content
        @State private var isLoading = true

        var body: some View {
            Group {
                if isLoading {
                    ProgressView("Loading Preview Data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(UIStyles.shared.colors.appBackground)
                        .onAppear { Task { await loadData(); isLoading = false } }
                } else { content }
            }
        }

        func loadData() async {
             print("Preview: Starting data load...")
             let dbService = InsightsView_Previews.databaseService
             let state = InsightsView_Previews.appState
             let chatMgr = InsightsView_Previews.chatManager
             do {
                 let entries = try dbService.loadAllJournalEntries()
                 await MainActor.run { state.journalEntries = entries }
                 print("Preview: Loaded \(entries.count) entries into AppState")
                 let chats = try dbService.loadAllChats()
                 await MainActor.run {
                     chatMgr.chats = chats
                     if let firstChat = chats.first { chatMgr.currentChat = firstChat }
                     else { chatMgr.currentChat = Chat() }
                 }
                 print("Preview: Loaded \(chats.count) chats into ChatManager")
             } catch { print("‼️ Preview data loading error: \(error)") }
             print("Preview: Data loading finished.")
        }
    }
}