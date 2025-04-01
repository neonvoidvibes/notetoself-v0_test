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
    
    // Animation states
    @State private var headerAppeared = false
    @State private var cardsAppeared = false
    @State private var selectedSection: String? = nil

    private let styles = UIStyles.shared

    private var isWeeklySummaryFresh: Bool {
        guard let generatedDate = summaryDate else { return false }
        return Calendar.current.dateComponents([.hour], from: generatedDate, to: Date()).hour ?? 25 < 24
    }

    private var hasAnyEntries: Bool {
        !appState.journalEntries.isEmpty
    }
    
    // Determine if the weekly summary should be shown in highlights section
    private var showWeeklySummaryInHighlights: Bool {
        // Check if today is Sunday
        let isSunday = Calendar.current.component(.weekday, from: Date()) == 1
        
        // Check if user has been journaling for at least 6 days
        let hasBeenJournalingLongEnough: Bool = {
            guard let oldestEntry = appState.journalEntries.last else { return false }
            let daysSinceFirstEntry = Calendar.current.dateComponents([.day], from: oldestEntry.date, to: Date()).day ?? 0
            return daysSinceFirstEntry >= 6
        }()
        
        return isSunday && hasBeenJournalingLongEnough
    }

    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    styles.colors.appBackground,
                    styles.colors.appBackground.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with animated accent
                ZStack(alignment: .center) {
                    // Title truly centered with animated accent
                    VStack(spacing: 8) {
                        Text("Insights")
                            .font(styles.typography.title1)
                            .foregroundColor(styles.colors.text)
                            .shadow(color: styles.colors.accent.opacity(0.3), radius: 2, x: 0, y: 0)

                        // Animated accent bar
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        styles.colors.accent.opacity(0.7),
                                        styles.colors.accent
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: headerAppeared ? 30 : 0, height: 3)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: headerAppeared)
                    }

                    // Menu button on left
                    HStack {
                        Button(action: {
                            NotificationCenter.default.post(name: NSNotification.Name("ToggleSettings"), object: nil)
                        }) {
                            VStack(spacing: 6) {
                                HStack {
                                    Rectangle().fill(styles.colors.accent).frame(width: 28, height: 2)
                                    Spacer()
                                }
                                HStack {
                                    Rectangle().fill(styles.colors.accent).frame(width: 20, height: 2)
                                    Spacer()
                                }
                            }
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(styles.colors.secondaryBackground.opacity(0.5))
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                        }

                        Spacer()
                    }
                    .padding(.horizontal, styles.layout.paddingXL)
                }
                .padding(.top, 12)
                .padding(.bottom, 12)

                // Main content ScrollView
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scrollView")).minY
                            )
                        }.frame(height: 0)

                        // Initial Empty State or Content
                        if !hasAnyEntries {
                            emptyStateView
                        } else {
                            // Regular Content Header with animation
                            VStack(alignment: .center, spacing: styles.layout.spacingL) {
                                Text("My Insights")
                                    .font(styles.typography.headingFont)
                                    .foregroundColor(styles.colors.text)
                                    .padding(.bottom, 4)
                                    .shadow(color: styles.colors.accent.opacity(0.3), radius: 2, x: 0, y: 0)
                                
                                Text("Discover patterns, make better choices.")
                                    .font(styles.typography.bodyLarge)
                                    .foregroundColor(styles.colors.accent)
                                    .multilineTextAlignment(.center)
                                    .shadow(color: styles.colors.accent.opacity(0.3), radius: 1, x: 0, y: 0)
                            }
                            .padding(.horizontal, styles.layout.paddingXL)
                            .padding(.vertical, styles.layout.spacingXL * 1.5)
                            .padding(.top, 80)
                            .padding(.bottom, 40)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    // Subtle gradient background
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            styles.colors.appBackground,
                                            styles.colors.appBackground.opacity(0.85)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    
                                    // Subtle pattern overlay
                                    GeometryReader { geo in
                                        ForEach(0..<10) { i in
                                            Circle()
                                                .fill(styles.colors.accent.opacity(0.03))
                                                .frame(width: CGFloat.random(in: 40...100))
                                                .position(
                                                    x: CGFloat.random(in: 0...geo.size.width),
                                                    y: CGFloat.random(in: 0...geo.size.height)
                                                )
                                        }
                                    }
                                }
                            )
                            .opacity(headerAppeared ? 1 : 0)
                            .offset(y: headerAppeared ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: headerAppeared)

                            // Loading Indicator or Cards
                            if isLoadingInsights && summaryJson == nil && trendJson == nil && recommendationsJson == nil {
                                loadingView
                            } else {
                                insightsContent(scrollProxy: scrollProxy)
                            }
                        }
                    }
                    .coordinateSpace(name: "scrollView")
                    .disabled(mainScrollingDisabled)
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // Scroll handling logic
                        let scrollingDown = value < lastScrollPosition
                        if abs(value - lastScrollPosition) > 10 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if scrollingDown { tabBarOffset = 100; tabBarVisible = false }
                                else { tabBarOffset = 0; tabBarVisible = true }
                            }
                            lastScrollPosition = value
                        }
                    }
                }
            }
        }
        .onAppear {
            loadStoredInsights()
            
            // Trigger animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                headerAppeared = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                cardsAppeared = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
            print("[InsightsView] Received insightsDidUpdate notification. Reloading insights.")
            loadStoredInsights()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToTab"))) { notification in
            if let userInfo = notification.userInfo, let tabIndex = userInfo["tabIndex"] as? Int {
                NotificationCenter.default.post(name: NSNotification.Name("SwitchTab"), object: nil, userInfo: ["tabIndex": tabIndex])
            }
        }
    }
    
    // MARK: - Component Views
    
    private var emptyStateView: some View {
        VStack(spacing: styles.layout.spacingL) {
            Spacer(minLength: 100)
            
            // Animated icon
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(styles.colors.accent.opacity(0.1 - Double(i) * 0.03))
                        .frame(width: 120 + CGFloat(i * 20), height: 120 + CGFloat(i * 20))
                        .scaleEffect(headerAppeared ? 1 : 0.5)
                        .opacity(headerAppeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1 + Double(i) * 0.1), value: headerAppeared)
                }
                
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 60))
                    .foregroundColor(styles.colors.accent.opacity(0.7))
                    .shadow(color: styles.colors.accent.opacity(0.5), radius: 5, x: 0, y: 0)
                    .scaleEffect(headerAppeared ? 1 : 0.5)
                    .opacity(headerAppeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.4), value: headerAppeared)
            }
            
            Text("Unlock Your Insights")
                .font(styles.typography.title1)
                .foregroundColor(styles.colors.text)
                .shadow(color: styles.colors.accent.opacity(0.3), radius: 2, x: 0, y: 0)
                .offset(y: headerAppeared ? 0 : 20)
                .opacity(headerAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: headerAppeared)
            
            Text("Start journaling regularly to discover patterns and receive personalized insights here.")
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, styles.layout.paddingXL)
                .offset(y: headerAppeared ? 0 : 20)
                .opacity(headerAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: headerAppeared)
            
            Spacer()
        }
        .padding(.vertical, 50)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            // Custom loading animation
            ZStack {
                Circle()
                    .stroke(styles.colors.tertiaryBackground, lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [styles.colors.accent, styles.colors.accent.opacity(0.5)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: headerAppeared ? 360 : 0))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: headerAppeared)
            }
            
            Text("Loading Insights...")
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.accent)
        }
        .padding(.vertical, 50)
    }
    
    @ViewBuilder
    private func insightsContent(scrollProxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: styles.layout.cardSpacing, pinnedViews: [.sectionHeaders]) {
            // Debug subscription toggle (only in DEBUG)
            #if DEBUG
            Section {
                HStack {
                    Text("Sub:").font(styles.typography.bodySmall).foregroundColor(styles.colors.textSecondary)
                    Picker("", selection: $appState.subscriptionTier) {
                        Text("Free").tag(SubscriptionTier.free)
                        Text("Premium").tag(SubscriptionTier.premium)
                    }
                    .pickerStyle(SegmentedPickerStyle()).frame(width: 150)
                    Spacer()
                }
                .padding(.horizontal, styles.layout.paddingXL)
                .padding(.top, 8)
            }
            #endif
            
            // Today's Highlights Section
            Section(header: AnimatedSectionHeader(
                title: "Today's Highlights",
                isSelected: selectedSection == "highlights",
                onTap: { selectedSection = selectedSection == "highlights" ? nil : "highlights" }
            )) {
                // Streak Card
                StreakInsightCard(
                    streak: appState.currentStreak,
                    scrollProxy: scrollProxy,
                    cardId: "streakCard"
                )
                .id("streakCard")
                .padding(.horizontal, styles.layout.paddingXL)
                .scaleEffect(cardsAppeared ? 1 : 0.95)
                .opacity(cardsAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: cardsAppeared)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                
                // Chat Insight Card - moved to Today's Highlights section
                ChatInsightCard(
                    scrollProxy: scrollProxy,
                    cardId: "chatCard"
                )
                .id("chatCard")
                .padding(.horizontal, styles.layout.paddingXL)
                .accessibilityLabel("AI Reflection")
                .scaleEffect(cardsAppeared ? 1 : 0.95)
                .opacity(cardsAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: cardsAppeared)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                
                // Weekly Summary Card - only show in highlights if it's Sunday and user has been journaling for 6+ days
                if showWeeklySummaryInHighlights {
                    WeeklySummaryInsightCard(
                        jsonString: summaryJson,
                        generatedDate: summaryDate,
                        isFresh: isWeeklySummaryFresh,
                        subscriptionTier: appState.subscriptionTier,
                        scrollProxy: scrollProxy,
                        cardId: "summaryCard"
                    )
                    .id("summaryCard")
                    .padding(.horizontal, styles.layout.paddingXL)
                    .scaleEffect(cardsAppeared ? 1 : 0.95)
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: cardsAppeared)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
            }
            
            // Deeper Insights Section
            Section(header: AnimatedSectionHeader(
                title: "Deeper Insights",
                isSelected: selectedSection == "deeper",
                onTap: { selectedSection = selectedSection == "deeper" ? nil : "deeper" }
            )) {
                // Mood Trends Card
                MoodTrendsInsightCard(
                    jsonString: trendJson,
                    generatedDate: trendDate,
                    subscriptionTier: appState.subscriptionTier,
                    scrollProxy: scrollProxy,
                    cardId: "trendCard"
                )
                .id("trendCard")
                .padding(.horizontal, styles.layout.paddingXL)
                .accessibilityLabel("Mood Analysis")
                .scaleEffect(cardsAppeared ? 1 : 0.95)
                .opacity(cardsAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: cardsAppeared)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                
                // Recommendations Card
                RecommendationsInsightCard(
                    jsonString: recommendationsJson,
                    generatedDate: recommendationsDate,
                    subscriptionTier: appState.subscriptionTier,
                    scrollProxy: scrollProxy,
                    cardId: "recsCard"
                )
                .id("recsCard")
                .padding(.horizontal, styles.layout.paddingXL)
                .scaleEffect(cardsAppeared ? 1 : 0.95)
                .opacity(cardsAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: cardsAppeared)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                
                // Weekly Summary Card - moved to the end when not in highlights
                if !showWeeklySummaryInHighlights {
                    WeeklySummaryInsightCard(
                        jsonString: summaryJson,
                        generatedDate: summaryDate,
                        isFresh: isWeeklySummaryFresh,
                        subscriptionTier: appState.subscriptionTier,
                        scrollProxy: scrollProxy,
                        cardId: "summaryCard"
                    )
                    .id("summaryCard")
                    .padding(.horizontal, styles.layout.paddingXL)
                    .scaleEffect(cardsAppeared ? 1 : 0.95)
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: cardsAppeared)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
            }
            
            // Bottom padding
            Section {
                Spacer().frame(height: styles.layout.paddingXL + 80)
            }
        }
    }

    // --- Data Loading ---
    private func loadStoredInsights() {
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

                isLoadingInsights = false
                print("[InsightsView] Finished loading insights.")
            }
        }
    }
}

// Replace the AnimatedSectionHeader implementation with this simplified version without chevrons
struct AnimatedSectionHeader: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(styles.typography.sectionHeader)
                    .foregroundColor(isSelected ? styles.colors.accent : styles.colors.text)
                    .shadow(color: isSelected ? styles.colors.accent.opacity(0.3) : .clear, radius: 1, x: 0, y: 0)
                
                Spacer()
            }
            .padding(.leading, styles.layout.paddingXL)
            .padding(.trailing, styles.layout.paddingL)
            .padding(.vertical, styles.layout.spacingS)
            .contentShape(Rectangle())
            .background(styles.colors.appBackground)
            .onTapGesture {
                onTap()
            }
            
            // Animated accent line
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            styles.colors.accent.opacity(isSelected ? 0.8 : 0.3),
                            styles.colors.accent.opacity(isSelected ? 0.5 : 0.1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: isSelected ? 2 : 1)
                .padding(.horizontal, styles.layout.paddingXL)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .background(styles.colors.appBackground)
    }
}

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

