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

    // State for stored raw insight data
    @State private var summaryJson: String? = nil
    @State private var summaryDate: Date? = nil
    @State private var trendJson: String? = nil
    @State private var trendDate: Date? = nil
    @State private var recommendationsJson: String? = nil
    @State private var recommendationsDate: Date? = nil
    @State private var isLoadingInsights: Bool = false

    private let styles = UIStyles.shared

    private var isWeeklySummaryFresh: Bool {
        guard let generatedDate = summaryDate else { return false }
        return Calendar.current.dateComponents([.hour], from: generatedDate, to: Date()).hour ?? 25 < 24
    }

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

                    // Initial Empty State or Content
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
                        // Regular Content Header
                        VStack(alignment: .center, spacing: styles.layout.spacingL) {
                            Text("My Insights")
                                .font(styles.typography.headingFont).foregroundColor(styles.colors.text).padding(.bottom, 4)
                            Text("Discover patterns, make better choices.")
                                .font(styles.typography.bodyLarge).foregroundColor(styles.colors.accent).multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, styles.layout.paddingXL)
                        .padding(.vertical, styles.layout.spacingXL * 1.5)
                        .padding(.top, 80).padding(.bottom, 40)
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [styles.colors.appBackground, styles.colors.appBackground.opacity(0.9)]), startPoint: .top, endPoint: .bottom))

                        // Loading Indicator or Cards
                        if isLoadingInsights && summaryJson == nil && trendJson == nil && recommendationsJson == nil {
                            // Show loading only on initial load when everything is nil
                            ProgressView("Loading Insights...")
                                .padding(.vertical, 50)
                                .tint(styles.colors.accent)
                        } else {
                            VStack(spacing: styles.layout.cardSpacing) {
                                // Subscription Tier Toggle (for testing)
                                #if DEBUG
                                HStack {
                                    Text("Sub:").font(styles.typography.bodySmall).foregroundColor(styles.colors.textSecondary)
                                    Picker("", selection: $appState.subscriptionTier) {
                                        Text("Free").tag(SubscriptionTier.free)
                                        Text("Premium").tag(SubscriptionTier.premium)
                                    }
                                    .pickerStyle(SegmentedPickerStyle()).frame(width: 150) // Smaller picker
                                    Spacer()
                                }
                                .padding(.horizontal, styles.layout.paddingXL).padding(.top, 8)
                                #endif

                                // Today's Highlights Section
                                styles.sectionHeader("Today's Highlights")

                                // Streak Card
                                StreakInsightCard(streak: appState.currentStreak)
                                    .padding(.horizontal, styles.layout.paddingXL)

                                // Weekly Summary Card (Pass raw data)
                                WeeklySummaryInsightCard(
                                    jsonString: summaryJson,
                                    generatedDate: summaryDate,
                                    isFresh: isWeeklySummaryFresh,
                                    subscriptionTier: appState.subscriptionTier
                                )
                                .padding(.horizontal, styles.layout.paddingXL)

                                // Deeper Insights Section
                                styles.sectionHeader("Deeper Insights")

                                // AI Reflection Card
                                ChatInsightCard()
                                    .padding(.horizontal, styles.layout.paddingXL)
                                    .accessibilityLabel("AI Reflection")

                                // Mood Analysis Card (Pass raw data)
                                MoodTrendsInsightCard(
                                    jsonString: trendJson,
                                    generatedDate: trendDate,
                                    subscriptionTier: appState.subscriptionTier
                                )
                                .padding(.horizontal, styles.layout.paddingXL)
                                .accessibilityLabel("Mood Analysis")

                                // Recommendations Card (Pass raw data)
                                RecommendationsInsightCard(
                                    jsonString: recommendationsJson,
                                    generatedDate: recommendationsDate,
                                    subscriptionTier: appState.subscriptionTier
                                )
                                .padding(.horizontal, styles.layout.paddingXL)
                                .padding(.bottom, styles.layout.paddingXL + 80)

                            } // End VStack for cards
                        } // End else (isLoadingInsights or has data)
                    } // End else (hasAnyEntries)
                } // End ScrollView
                .coordinateSpace(name: "scrollView")
                .disabled(mainScrollingDisabled)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    // Scroll handling logic (unchanged)
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
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[InsightsView] Received insightsDidUpdate notification. Reloading insights.")
             // Only set loading state briefly if we already have some data,
             // otherwise let the cards handle their own loading appearance.
             if summaryJson != nil || trendJson != nil || recommendationsJson != nil {
                 // Maybe a very short loading flash? Or just let cards update.
                 // For now, just reload without setting isLoadingInsights = true
                 // isLoadingInsights = true // Optional: Briefly show global loading
             }
             loadStoredInsights() // Reload data
         }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToTab"))) { notification in
            if let userInfo = notification.userInfo, let tabIndex = userInfo["tabIndex"] as? Int {
                NotificationCenter.default.post(name: NSNotification.Name("SwitchTab"), object: nil, userInfo: ["tabIndex": tabIndex])
            }
        }
    } // End body

    // --- Data Loading ---
    private func loadStoredInsights() {
        // Set loading true only if NO data exists yet
        if summaryJson == nil && trendJson == nil && recommendationsJson == nil {
            isLoadingInsights = true
        }
        print("[InsightsView] Loading stored insights from DB...")

        Task {
            // Run DB calls in background task
            let summaryResult = await Task.detached { try? self.databaseService.loadLatestInsight(type: "weeklySummary") }.value
            let moodTrendResult = await Task.detached { try? self.databaseService.loadLatestInsight(type: "moodTrend") }.value
            let recommendationsResult = await Task.detached { try? self.databaseService.loadLatestInsight(type: "recommendation") }.value

            // Update state back on main thread
            await MainActor.run {
                if let (json, date) = summaryResult {
                    self.summaryJson = json
                    self.summaryDate = date
                    print("[InsightsView] Loaded Weekly Summary JSON (Generated: \(date.formatted()))")
                } else {
                    self.summaryJson = nil
                    self.summaryDate = nil
                    print("[InsightsView] No stored Weekly Summary found.")
                }

                if let (json, date) = moodTrendResult {
                    self.trendJson = json
                    self.trendDate = date
                    print("[InsightsView] Loaded Mood Trend JSON (Generated: \(date.formatted()))")
                } else {
                    self.trendJson = nil
                    self.trendDate = nil
                    print("[InsightsView] No stored Mood Trend found.")
                }

                if let (json, date) = recommendationsResult {
                    self.recommendationsJson = json
                    self.recommendationsDate = date
                    print("[InsightsView] Loaded Recommendations JSON (Generated: \(date.formatted()))")
                } else {
                    self.recommendationsJson = nil
                    self.recommendationsDate = nil
                    print("[InsightsView] No stored Recommendations found.")
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