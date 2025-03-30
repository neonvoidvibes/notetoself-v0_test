import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled

    @State private var selectedMonth: Date = Date() // Keep for potential calendar card re-integration
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
    @State private var isLoadingInsights: Bool = false

    // Access to shared styles
    private let styles = UIStyles.shared

    // Check if weekly summary is fresh (generated in the past 24 hours)
    private var isWeeklySummaryFresh: Bool {
        guard let generatedDate = storedWeeklySummaryDate else { return false }
        return Calendar.current.dateComponents([.hour], from: generatedDate, to: Date()).hour ?? 25 < 24
    }

    var body: some View {
        ZStack {
            styles.colors.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                ZStack(alignment: .center) {
                    // Title truly centered
                    VStack(spacing: 8) {
                        Text("Insights")
                            .font(styles.typography.title1)
                            .foregroundColor(styles.colors.text)

                        Rectangle()
                            .fill(styles.colors.accent)
                            .frame(width: 20, height: 3)
                    }

                    // Menu button on left
                    HStack {
                        Button(action: {
                            NotificationCenter.default.post(name: NSNotification.Name("ToggleSettings"), object: nil)
                        }) {
                            VStack(spacing: 6) { // Increased spacing between bars
                                HStack {
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 28, height: 2) // Top bar - slightly longer
                                    Spacer()
                                }
                                HStack {
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 20, height: 2) // Bottom bar (shorter)
                                    Spacer()
                                }
                            }
                            .frame(width: 36, height: 36)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, styles.layout.paddingXL)
                }
                .padding(.top, 8) // Further reduced top padding
                .padding(.bottom, 8)

                // Main content in ScrollView
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scrollView")).minY
                        )
                    }
                    .frame(height: 0)

                    // Inspiring prompt section
                    VStack(alignment: .center, spacing: styles.layout.spacingL) {
                        // Inspiring header with larger font
                        Text("My Insights")
                            .font(styles.typography.headingFont)
                            .foregroundColor(styles.colors.text)
                            .padding(.bottom, 4)

                        // Inspiring quote with larger font
                        Text("Discover patterns, make better choices.")
                            .font(styles.typography.bodyLarge)
                            .foregroundColor(styles.colors.accent)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, styles.layout.paddingXL)
                    .padding(.vertical, styles.layout.spacingXL * 1.5)
                    .padding(.top, 80) // Extra top padding for spaciousness
                    .padding(.bottom, 40) // Extra bottom padding
                    .frame(maxWidth: .infinity)
                    .background(
                        // Subtle gradient background for the inspiring section
                        LinearGradient(
                            gradient: Gradient(colors: [
                                styles.colors.appBackground,
                                styles.colors.appBackground.opacity(0.9)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    if isLoadingInsights {
                        ProgressView("Loading Insights...")
                            .padding(.vertical, 50)
                            .tint(styles.colors.accent)
                    } else {
                        VStack(spacing: styles.layout.cardSpacing) {
                            // TOGGLE FOR SUBSCRIPTION TIER - FOR TESTING ONLY
                            // Comment out this section when not needed
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

                            // Today's Highlights Section
                            styles.sectionHeader("Today's Highlights")

                            // 1. Streak Card (Uses AppState directly, no AI)
                            StreakInsightCard(streak: appState.currentStreak)
                                .padding(.horizontal, styles.layout.paddingXL)

                            // Weekly Summary Card (Uses stored AI result)
                            WeeklySummaryInsightCard(
                                summaryResult: storedWeeklySummary,
                                generatedDate: storedWeeklySummaryDate,
                                isFresh: isWeeklySummaryFresh
                            )
                            .padding(.horizontal, styles.layout.paddingXL)


                            // Deeper Insights Section
                            styles.sectionHeader("Deeper Insights")

                            // AI Reflection Card (Uses ChatManager directly, no AI insight model)
                            ChatInsightCard()
                                .padding(.horizontal, styles.layout.paddingXL)
                                .accessibilityLabel("AI Reflection")

                            // Mood Analysis Card (Uses stored AI result)
                            MoodTrendsInsightCard(
                                trendResult: storedMoodTrend,
                                generatedDate: storedMoodTrendDate
                            )
                            .padding(.horizontal, styles.layout.paddingXL)
                            .accessibilityLabel("Mood Analysis")


                            // Recommendations Card (Uses stored AI result)
                            RecommendationsInsightCard(
                                recommendationResult: storedRecommendations,
                                generatedDate: storedRecommendationsDate
                            )
                            .padding(.horizontal, styles.layout.paddingXL)
                            .padding(.bottom, styles.layout.paddingXL + 80) // Extra padding for tab bar

                        } // End VStack for cards
                    } // End else (isLoadingInsights)
                } // End ScrollView
                .coordinateSpace(name: "scrollView")
                .disabled(mainScrollingDisabled)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    let scrollingDown = value < lastScrollPosition
                    if abs(value - lastScrollPosition) > 10 {
                        if scrollingDown {
                            tabBarOffset = 100
                            tabBarVisible = false
                        } else {
                            tabBarOffset = 0
                            tabBarVisible = true
                        }
                        lastScrollPosition = value
                    }
                }
            } // End VStack
        } // End ZStack
        .onAppear {
            loadStoredInsights()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToTab"))) { notification in
            if let userInfo = notification.userInfo, let tabIndex = userInfo["tabIndex"] as? Int {
                // Post a notification to switch to the specified tab
                NotificationCenter.default.post(
                    name: NSNotification.Name("SwitchTab"),
                    object: nil,
                    userInfo: ["tabIndex": tabIndex]
                )
            }
        }
    } // End body

    // --- Data Loading ---
    private func loadStoredInsights() {
        guard appState.subscriptionTier == .premium else {
             print("[InsightsView] Skipping insight loading (Free tier).")
             // Clear any previously loaded insights if user downgrades
             storedWeeklySummary = nil
             storedMoodTrend = nil
             storedRecommendations = nil
             storedWeeklySummaryDate = nil
             storedMoodTrendDate = nil
             storedRecommendationsDate = nil
             return
        }

        Task {
            isLoadingInsights = true
            print("[InsightsView] Loading stored insights from DB...")

            // Wrap DB calls in a Task to run them off the main thread
             async let summaryDataFetch: (jsonData: String, generatedDate: Date)? = try databaseService.loadLatestInsight(type: "weeklySummary")
             async let moodTrendDataFetch: (jsonData: String, generatedDate: Date)? = try databaseService.loadLatestInsight(type: "moodTrend")
             async let recommendationsDataFetch: (jsonData: String, generatedDate: Date)? = try databaseService.loadLatestInsight(type: "recommendation")


            // Await results
            // Use try await here as the async let itself can throw if the underlying task throws
            let summaryData = try? await summaryDataFetch
            let moodTrendData = try? await moodTrendDataFetch
            let recommendationsData = try? await recommendationsDataFetch


            // Process Weekly Summary
            // Remove try? from result variable access
            if let (json, date) = summaryData {
                if let data = json.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(WeeklySummaryResult.self, from: data) {
                    storedWeeklySummary = decoded
                    storedWeeklySummaryDate = date
                    print("[InsightsView] Loaded Weekly Summary (Generated: \(date.formatted()))")
                } else {
                    print("⚠️ [InsightsView] Failed to decode Weekly Summary JSON.")
                    storedWeeklySummary = WeeklySummaryResult.empty() // Show empty state
                    storedWeeklySummaryDate = nil
                }
            } else {
                 print("[InsightsView] No stored Weekly Summary found.")
                 storedWeeklySummary = nil // Ensure it's nil if not found
                 storedWeeklySummaryDate = nil
            }

            // Process Mood Trend
             // Remove try? from result variable access
             if let (json, date) = moodTrendData {
                 if let data = json.data(using: .utf8),
                    let decoded = try? JSONDecoder().decode(MoodTrendResult.self, from: data) {
                     storedMoodTrend = decoded
                     storedMoodTrendDate = date
                     print("[InsightsView] Loaded Mood Trend (Generated: \(date.formatted()))")
                 } else {
                     print("⚠️ [InsightsView] Failed to decode Mood Trend JSON.")
                     storedMoodTrend = MoodTrendResult.empty()
                     storedMoodTrendDate = nil
                 }
             } else {
                  print("[InsightsView] No stored Mood Trend found.")
                  storedMoodTrend = nil
                  storedMoodTrendDate = nil
             }

            // Process Recommendations
             // Remove try? from result variable access
             if let (json, date) = recommendationsData {
                 if let data = json.data(using: .utf8),
                    let decoded = try? JSONDecoder().decode(RecommendationResult.self, from: data) {
                     storedRecommendations = decoded
                     storedRecommendationsDate = date
                     print("[InsightsView] Loaded Recommendations (Generated: \(date.formatted()))")
                 } else {
                     print("⚠️ [InsightsView] Failed to decode Recommendations JSON.")
                     storedRecommendations = RecommendationResult.empty()
                     storedRecommendationsDate = nil
                 }
             } else {
                  print("[InsightsView] No stored Recommendations found.")
                  storedRecommendations = nil
                  storedRecommendationsDate = nil
             }


            isLoadingInsights = false
            print("[InsightsView] Finished loading insights.")
        }
    }
} // End InsightsView struct

// MARK: - Preview Provider (Correctly placed outside the main struct)
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
            // REMOVED: .environmentObject(llmService)
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
                        .onAppear {
                            Task {
                                await loadData()
                                isLoading = false
                            }
                        }
                } else {
                    content
                }
            }
        }

        func loadData() async {
             print("Preview: Starting data load...")
             let dbService = InsightsView_Previews.databaseService
             let state = InsightsView_Previews.appState
             let chatMgr = InsightsView_Previews.chatManager

             do {
                 // Load journal entries into AppState
                 let entries = try dbService.loadAllJournalEntries()
                 await MainActor.run { state.journalEntries = entries }
                 print("Preview: Loaded \(entries.count) entries into AppState")

                 // Load chats into ChatManager
                 let chats = try dbService.loadAllChats()
                 await MainActor.run {
                     chatMgr.chats = chats
                     if let firstChat = chats.first {
                         chatMgr.currentChat = firstChat
                     } else {
                          chatMgr.currentChat = Chat()
                     }
                 }
                 print("Preview: Loaded \(chats.count) chats into ChatManager")

             } catch {
                 print("‼️ Preview data loading error: \(error)")
             }
             print("Preview: Data loading finished.")
        }
    }
}