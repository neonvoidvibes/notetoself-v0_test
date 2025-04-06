import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager // Keep if needed by AI Reflection Card
    @EnvironmentObject var databaseService: DatabaseService
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled

    // Tab Bar State (Keep if still used by parent)
    @Binding var tabBarOffset: CGFloat
    @Binding var lastScrollPosition: CGFloat
    @Binding var tabBarVisible: Bool

    // State for stored raw insight data (Existing + New Top Cards)
    @State private var dailyReflectionJson: String? = nil // NEW #1
    @State private var dailyReflectionDate: Date? = nil // NEW #1
    @State private var weekInReviewJson: String? = nil // NEW #2
    @State private var weekInReviewDate: Date? = nil // NEW #2

    @State private var summaryJson: String? = nil // Original Weekly Summary
    @State private var summaryDate: Date? = nil
    @State private var reflectionJson: String? = nil // Original AI Reflection
    @State private var reflectionDate: Date? = nil
    @State private var journeyJson: String? = nil // For Journey Narrative
    @State private var journeyDate: Date? = nil
    // State for new grouped insights
    @State private var feelInsightsJson: String? = nil // #3
    @State private var feelInsightsDate: Date? = nil
    @State private var thinkInsightsJson: String? = nil // #4
    @State private var thinkInsightsDate: Date? = nil
    @State private var actInsightsJson: String? = nil // #5
    @State private var actInsightsDate: Date? = nil
    @State private var learnInsightsJson: String? = nil // #6
    @State private var learnInsightsDate: Date? = nil

    @State private var isLoadingInsights: Bool = false

    // Animation states
    @State private var headerAppeared = false
    @State private var cardsAppeared = false

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    // Calculate if Week in Review is fresh (< 24 hours)
     private var isWeekInReviewFresh: Bool {
         guard let generatedDate = weekInReviewDate else { return false }
         return Calendar.current.dateComponents([.hour], from: generatedDate, to: Date()).hour ?? 25 < 24
     }

    // Calculate if original Weekly Summary is fresh (Sun 3AM logic) - Keep if original card stays
    private var isWeeklySummaryFresh: Bool {
        guard let generatedDate = summaryDate else { return false }
        let calendar = Calendar.current
        let now = Date()
        let generatedWeekday = calendar.component(.weekday, from: generatedDate) // 1 = Sunday
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: generatedDate)
        components.weekday = 1; components.hour = 3; components.minute = 0; components.second = 0
        guard let sunday3AM = calendar.date(from: components) else { return false }
        let endOfWindow = calendar.date(byAdding: .hour, value: 45, to: sunday3AM)!
        let generatedAfterStart = generatedDate >= sunday3AM
        let isWithinWindow = now < endOfWindow
        return generatedAfterStart && isWithinWindow
    }

    private var hasAnyEntries: Bool {
        !appState.journalEntries.isEmpty
    }

    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground.ignoresSafeArea() // Simpler background

            VStack(spacing: 0) {
                // Header
                 ZStack(alignment: .center) {
                     VStack(spacing: 8) {
                         Text("Insights")
                             .font(styles.typography.title1)
                             .foregroundColor(styles.colors.text)
                         Rectangle()
                             .fill(LinearGradient(gradient: Gradient(colors: [styles.colors.accent.opacity(0.7), styles.colors.accent]), startPoint: .leading, endPoint: .trailing))
                             .frame(width: headerAppeared ? 30 : 0, height: 3)
                             .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: headerAppeared)
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
                 .padding(.top, 12)
                 .padding(.bottom, 12)

                // Main content ScrollView
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        GeometryReader { geometry in // For scroll offset detection
                            Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scrollView")).minY)
                        }.frame(height: 0)

                        // Initial Empty State or Content
                        if !hasAnyEntries {
                            emptyStateView // Keep existing empty state
                        } else {
                            // Loading Indicator or Cards
                            if isLoadingInsights && areAllInsightsNil() { // Check if ALL insights are nil before showing global loader
                                loadingView // Keep existing loading view
                            } else {
                                // Display Cards in Fixed Order
                                insightsCardList(scrollProxy: scrollProxy)
                            }
                        }
                    }
                    .coordinateSpace(name: "scrollView")
                    .disabled(mainScrollingDisabled)
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // Scroll handling logic (Keep existing)
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
            loadStoredInsights() // Load data on appear
            // Trigger animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { headerAppeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { cardsAppeared = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
            print("[InsightsView] Received insightsDidUpdate notification. Reloading insights.")
            loadStoredInsights() // Reload data on notification
        }
        // Keep tab switching logic if needed
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToTab"))) { notification in
             if let userInfo = notification.userInfo, let tabIndex = userInfo["tabIndex"] as? Int {
                 NotificationCenter.default.post(name: NSNotification.Name("SwitchTab"), object: nil, userInfo: ["tabIndex": tabIndex])
             }
         }
    }

    // MARK: - Card List View
    @ViewBuilder
    private func insightsCardList(scrollProxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: styles.layout.cardSpacing) { // Use standard card spacing

             #if DEBUG // Keep debug toggle
             HStack {
                 Text("Sub:").font(styles.typography.bodySmall).foregroundColor(styles.colors.textSecondary)
                 Picker("", selection: $appState.subscriptionTier) {
                     Text("Free").tag(SubscriptionTier.free)
                     Text("Premium").tag(SubscriptionTier.premium)
                 }.pickerStyle(SegmentedPickerStyle()).frame(width: 150)
                 Spacer()
             }.padding(.horizontal, styles.layout.paddingXL).padding(.top, 8)
             #endif

            // --- NEW TOP CARDS ---

             // 1. AI Insights (Daily Reflection) Card (#1)
              DailyReflectionInsightCard(
                   jsonString: dailyReflectionJson, // Pass loaded data
                   generatedDate: dailyReflectionDate, // Pass loaded date
                   scrollProxy: scrollProxy,
                   cardId: "dailyReflectionCard"
               )
               .id("dailyReflectionCard")
               .padding(.horizontal, styles.layout.paddingXL)
               .opacity(cardsAppeared ? 1 : 0)
               .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: cardsAppeared)

             // 2. Week in Review Card (#2)
              WeekInReviewCard(
                   jsonString: weekInReviewJson, // Pass loaded data
                   generatedDate: weekInReviewDate, // Pass loaded date
                   scrollProxy: scrollProxy,
                   cardId: "weekInReviewCard"
               )
               .id("weekInReviewCard")
               .padding(.horizontal, styles.layout.paddingXL)
               .opacity(cardsAppeared ? 1 : 0)
               .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: cardsAppeared)


            // --- NEW GROUPED CARDS ---

             // 3. Feel Card (#3)
              FeelInsightCard( // Keep internal loading for grouped cards for now
                  scrollProxy: scrollProxy,
                  cardId: "feelCard"
              )
              .id("feelCard")
              .padding(.horizontal, styles.layout.paddingXL)
              .opacity(cardsAppeared ? 1 : 0)
              .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: cardsAppeared)


              // 4. Think Card (#4)
               ThinkInsightCard( // Keep internal loading
                   scrollProxy: scrollProxy,
                   cardId: "thinkCard"
               )
               .id("thinkCard")
               .padding(.horizontal, styles.layout.paddingXL)
               .opacity(cardsAppeared ? 1 : 0)
               .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: cardsAppeared)


               // 5. Act Card (#5)
                ActInsightCard( // Keep internal loading
                    scrollProxy: scrollProxy,
                    cardId: "actCard"
                )
                .id("actCard")
                .padding(.horizontal, styles.layout.paddingXL)
                .opacity(cardsAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: cardsAppeared)


                // 6. Learn Card (#6)
                 LearnInsightCard( // Keep internal loading
                     scrollProxy: scrollProxy,
                     cardId: "learnCard"
                 )
                 .id("learnCard")
                 .padding(.horizontal, styles.layout.paddingXL)
                 .opacity(cardsAppeared ? 1 : 0)
                 .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: cardsAppeared)


            // --- OLD CARDS (If kept) ---
            // Weekly Summary Card (Original) - Uses passed data
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
            .opacity(cardsAppeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.7), value: cardsAppeared)

            // AI Reflection Card (Original) - Uses internal loading
             AIReflectionInsightCard(
                 scrollProxy: scrollProxy,
                 cardId: "aiReflectionCard"
             )
             .id("aiReflectionCard")
             .padding(.horizontal, styles.layout.paddingXL)
             .opacity(cardsAppeared ? 1 : 0)
             .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8), value: cardsAppeared)

            // Bottom padding
            Spacer().frame(height: styles.layout.paddingXL + 80) // Keep bottom padding
        }
        .padding(.top, 20) // Add some top padding before cards start
    }


    // MARK: - Component Views (Keep emptyStateView and loadingView)
    private var emptyStateView: some View {
         VStack(spacing: styles.layout.spacingL) { // Keep existing empty state
             Spacer(minLength: 100)
             ZStack {
                 ForEach(0..<3) { i in
                     Circle().fill(styles.colors.accent.opacity(0.1 - Double(i) * 0.03))
                         .frame(width: 120 + CGFloat(i * 20), height: 120 + CGFloat(i * 20))
                         .scaleEffect(headerAppeared ? 1 : 0.5).opacity(headerAppeared ? 1 : 0)
                         .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1 + Double(i) * 0.1), value: headerAppeared)
                 }
                 Image(systemName: "sparkles.rectangle.stack")
                     .font(.system(size: 60)).foregroundColor(styles.colors.accent.opacity(0.7))
                     .shadow(color: styles.colors.accent.opacity(0.5), radius: 5, x: 0, y: 0)
                     .scaleEffect(headerAppeared ? 1 : 0.5).opacity(headerAppeared ? 1 : 0)
                     .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.4), value: headerAppeared)
             }
             Text("Unlock Your Insights").font(styles.typography.title1).foregroundColor(styles.colors.text)
                 .shadow(color: styles.colors.accent.opacity(0.3), radius: 2, x: 0, y: 0)
                 .offset(y: headerAppeared ? 0 : 20).opacity(headerAppeared ? 1 : 0)
                 .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: headerAppeared)
             Text("Start journaling regularly to discover patterns and receive personalized insights here.")
                 .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                 .multilineTextAlignment(.center).padding(.horizontal, styles.layout.paddingXL)
                 .offset(y: headerAppeared ? 0 : 20).opacity(headerAppeared ? 1 : 0)
                 .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: headerAppeared)
             Spacer()
         }.padding(.vertical, 50)
     }

    private var loadingView: some View {
         VStack(spacing: 20) { // Keep existing loading view
             ZStack {
                 Circle().stroke(styles.colors.tertiaryBackground, lineWidth: 4).frame(width: 60, height: 60)
                 Circle().trim(from: 0, to: 0.7)
                     .stroke(LinearGradient(gradient: Gradient(colors: [styles.colors.accent, styles.colors.accent.opacity(0.5)]), startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                     .frame(width: 60, height: 60).rotationEffect(Angle(degrees: headerAppeared ? 360 : 0))
                     .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: headerAppeared)
             }
             Text("Loading Insights...").font(styles.typography.bodyFont).foregroundColor(styles.colors.accent)
         }.padding(.vertical, 50)
     }

    // Helper to check if all insight states are nil
    private func areAllInsightsNil() -> Bool {
        return dailyReflectionJson == nil && // Check NEW
               weekInReviewJson == nil && // Check NEW
               summaryJson == nil &&
               reflectionJson == nil &&
               feelInsightsJson == nil &&
               thinkInsightsJson == nil &&
               actInsightsJson == nil &&
               learnInsightsJson == nil &&
               journeyJson == nil
    }


    // --- Data Loading ---
    private func loadStoredInsights() {
         if areAllInsightsNil() {
             isLoadingInsights = true
         }
         print("[InsightsView] Loading stored insights from DB...")
         Task {
             // Load NEW Top Cards insights
             async let dailyReflectionFetch = try? self.databaseService.loadLatestInsight(type: "dailyReflection")
             async let weekInReviewFetch = try? self.databaseService.loadLatestInsight(type: "weekInReview")

             // Load Grouped Cards insights
             async let feelFetch = try? self.databaseService.loadLatestInsight(type: "feelInsights")
             async let thinkFetch = try? self.databaseService.loadLatestInsight(type: "thinkInsights")
             async let actFetch = try? self.databaseService.loadLatestInsight(type: "actInsights")
             async let learnFetch = try? self.databaseService.loadLatestInsight(type: "learnInsights")

             // Load Existing/Old insights
             async let summaryFetch = try? self.databaseService.loadLatestInsight(type: "weeklySummary")
             async let reflectionFetch = try? self.databaseService.loadLatestInsight(type: "aiReflection")
             async let journeyFetch = try? self.databaseService.loadLatestInsight(type: "journeyNarrative")

             // Await results
             let dailyReflectionResult = await dailyReflectionFetch
             let weekInReviewResult = await weekInReviewFetch
             let feelResult = await feelFetch
             let thinkResult = await thinkFetch
             let actResult = await actFetch
             let learnResult = await learnFetch
             let summaryResult = await summaryFetch
             let reflectionResult = await reflectionFetch
             let journeyResult = await journeyFetch


             await MainActor.run {
                 // Update state for NEW Top Cards
                 if let (json, date) = dailyReflectionResult { self.dailyReflectionJson = json; self.dailyReflectionDate = date } else { self.dailyReflectionJson = nil; self.dailyReflectionDate = nil }
                 if let (json, date) = weekInReviewResult { self.weekInReviewJson = json; self.weekInReviewDate = date } else { self.weekInReviewJson = nil; self.weekInReviewDate = nil }

                 // Update state for NEW Grouped Cards
                 if let (json, date) = feelResult { self.feelInsightsJson = json; self.feelInsightsDate = date } else { self.feelInsightsJson = nil; self.feelInsightsDate = nil }
                 if let (json, date) = thinkResult { self.thinkInsightsJson = json; self.thinkInsightsDate = date } else { self.thinkInsightsJson = nil; self.thinkInsightsDate = nil }
                 if let (json, date) = actResult { self.actInsightsJson = json; self.actInsightsDate = date } else { self.actInsightsJson = nil; self.actInsightsDate = nil }
                 if let (json, date) = learnResult { self.learnInsightsJson = json; self.learnInsightsDate = date } else { self.learnInsightsJson = nil; self.learnInsightsDate = nil }

                 // Update state for Existing/Old Cards
                 if let (json, date) = summaryResult { self.summaryJson = json; self.summaryDate = date } else { self.summaryJson = nil; self.summaryDate = nil }
                 if let (json, date) = reflectionResult { self.reflectionJson = json; self.reflectionDate = date } else { self.reflectionJson = nil; self.reflectionDate = nil }
                 if let (json, date) = journeyResult { self.journeyJson = json; self.journeyDate = date } else { self.journeyJson = nil; self.journeyDate = nil }


                 isLoadingInsights = false
                 print("[InsightsView] Finished loading insights.")
             }
         }
     }
}

// Preview Provider
struct InsightsView_Previews: PreviewProvider {
     @StateObject static var databaseService = DatabaseService()
     static var llmService = LLMService.shared
     @StateObject static var subscriptionManager = SubscriptionManager.shared
     @StateObject static var appState = AppState()
     @StateObject static var chatManager = ChatManager(databaseService: databaseService, llmService: llmService, subscriptionManager: subscriptionManager)

     static var previews: some View {
         PreviewDataLoadingContainer {
             InsightsView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true))
                 .environmentObject(appState)
                 .environmentObject(chatManager)
                 .environmentObject(databaseService)
                 .environmentObject(subscriptionManager)
                 .environmentObject(ThemeManager.shared)
                 .environmentObject(UIStyles.shared) // Add UIStyles to environment
         }
     }

     struct PreviewDataLoadingContainer<Content: View>: View {
         @ViewBuilder let content: Content
         @State private var isLoading = true
         var body: some View {
             Group {
                 if isLoading { ProgressView("Loading Preview Data...").frame(maxWidth: .infinity, maxHeight: .infinity).background(UIStyles.shared.colors.appBackground).onAppear { Task { await loadData(); isLoading = false } } }
                 else { content }
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
                  print("Preview: Loaded \(entries.count) entries")
                  let chats = try dbService.loadAllChats()
                  await MainActor.run { chatMgr.chats = chats; if let first = chats.first { chatMgr.currentChat = first } else { chatMgr.currentChat = Chat() } }
                  print("Preview: Loaded \(chats.count) chats")
              } catch { print("‼️ Preview data loading error: \(error)") }
              print("Preview: Data loading finished.")
         }
     }
}