import SwiftUI
import Charts

// MARK: - Skeleton Card View [4.1]
struct SkeletonCardView: View {
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingL) {
            // Header Placeholder
            HStack {
                RoundedRectangle(cornerRadius: styles.layout.radiusM) // Title placeholder
                    .fill(styles.colors.secondaryBackground.opacity(0.5))
                    .frame(width: 120, height: 20)
                Spacer()
                RoundedRectangle(cornerRadius: styles.layout.radiusM) // Icon/Badge placeholder
                    .fill(styles.colors.secondaryBackground.opacity(0.5))
                    .frame(width: 50, height: 20)
            }

            // Content Placeholder
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .fill(styles.colors.secondaryBackground.opacity(0.5))
                .frame(height: 60) // Approximate height for content/chart area

             // Optional: Placeholder for "Open" button area
             HStack {
                  Spacer()
                  RoundedRectangle(cornerRadius: styles.layout.radiusM)
                      .fill(styles.colors.secondaryBackground.opacity(0.3))
                      .frame(width: 80, height: 28)
             }
        }
        .padding(styles.layout.cardInnerPadding) // Match card padding
        .background(styles.colors.cardBackground)
        .cornerRadius(styles.layout.radiusM) // Match card corner radius
        .overlay( // Match card border
             RoundedRectangle(cornerRadius: styles.layout.radiusM)
                 .stroke(styles.colors.divider, lineWidth: 1)
         )
        .shimmer() // Apply shimmer effect
    }
}


// MARK: - Main Insights View
struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager // Keep if needed by AI Reflection Card
    @EnvironmentObject var databaseService: DatabaseService
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled

    // Tab Bar State (Keep if still used by parent)
    @Binding var tabBarOffset: CGFloat
    @Binding var lastScrollPosition: CGFloat
    @Binding var tabBarVisible: Bool

    // State for stored raw insight data
    @State private var dailyReflectionJson: String? = nil // #1
    @State private var dailyReflectionDate: Date? = nil
    @State private var weekInReviewJson: String? = nil // #2
    @State private var weekInReviewDate: Date? = nil

    // Grouped Insights
    @State private var feelInsightsJson: String? = nil // #3
    @State private var feelInsightsDate: Date? = nil
    @State private var thinkInsightsJson: String? = nil // #4
    @State private var thinkInsightsDate: Date? = nil
    @State private var actInsightsJson: String? = nil // #5
    @State private var actInsightsDate: Date? = nil
    @State private var learnInsightsJson: String? = nil // #6
    @State private var learnInsightsDate: Date? = nil

    // Remaining Old Cards (Keep for now)
    @State private var journeyJson: String? = nil // For Journey Narrative
    @State private var journeyDate: Date? = nil


    @State private var isLoadingInsights: Bool = false // Controls *initial* skeleton display
    @State private var lastLoadTimestamp: Date? = nil // [2.1] State for timestamp

    // Animation states
    @State private var headerAppeared = false
    @State private var cardsAppeared = false

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    // Calculate if Week in Review is fresh (< 24 hours)
     private var isWeekInReviewFresh: Bool {
         guard let generatedDate = weekInReviewDate else { return false }
         return Calendar.current.dateComponents([.hour], from: generatedDate, to: Date()).hour ?? 25 < 24
     }

    private var hasAnyEntries: Bool {
        !appState.journalEntries.isEmpty
    }

    // [2.1] Formatter for the timestamp
    private var timestampFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
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
                         Button(action: { NotificationCenter.default.post(name: .toggleSettingsNotification, object: nil) }) { // Use standard name
                             VStack(spacing: 6) {
                                 HStack { Rectangle().fill(styles.colors.accent).frame(width: 28, height: 2); Spacer() }
                                 HStack { Rectangle().fill(styles.colors.accent).frame(width: 20, height: 2); Spacer() }
                             }.frame(width: 36, height: 36)
                         }
                         Spacer()
                     }.padding(.horizontal, styles.layout.paddingXL)
                 }
                 .padding(.top, 12)
                 .padding(.bottom, 12) // Restore original bottom padding


                // Main content ScrollView
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        GeometryReader { geometry in // For scroll offset detection
                            Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scrollView")).minY)
                        }.frame(height: 0)

                         // --- Timestamp Display moved here ---
                         if let timestamp = lastLoadTimestamp {
                              HStack { // Use HStack for alignment if needed
                                  Spacer() // Center align
                                  Text("Last updated: \(timestamp, formatter: timestampFormatter)")
                                      .font(styles.typography.caption)
                                      .foregroundColor(styles.colors.textSecondary.opacity(0.8))
                                  Spacer()
                              }
                              .padding(.top, 0) // Minimal top padding
                              .padding(.bottom, styles.layout.spacingM) // Space before cards
                              .padding(.horizontal, styles.layout.paddingXL) // Match card padding
                         } else if isLoadingInsights && hasAnyEntries { // Show placeholder only during initial load AND if entries exist
                              HStack {
                                  Spacer()
                                  Text("Loading insights...")
                                      .font(styles.typography.caption)
                                      .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                                  Spacer()
                              }
                               .padding(.top, 0)
                               .padding(.bottom, styles.layout.spacingM)
                               .padding(.horizontal, styles.layout.paddingXL)
                         }
                         // --- End Timestamp ---


                        // Initial Empty State or Content
                        if !hasAnyEntries {
                            emptyStateView // Show modified empty state
                        } else {
                            // [4.1] Use Skeleton Cards during initial load, otherwise show cards
                             insightsCardList(scrollProxy: scrollProxy)
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
            // [4.1] Trigger initial load only if no timestamp exists yet
             if lastLoadTimestamp == nil {
                  isLoadingInsights = true
                  loadStoredInsights()
             } else {
                 // Optionally trigger a background refresh without showing skeletons
                 // loadStoredInsights() // Or maybe skip if timestamp is recent enough
             }

            // Trigger animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { headerAppeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { cardsAppeared = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
            print("[InsightsView] Received insightsDidUpdate notification. Reloading insights.")
            loadStoredInsights() // Reload data on notification (don't set isLoadingInsights = true here)
        }
        // REMOVED the .onReceive listener for .switchToTabNotification
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

            // --- Daily Reflection Card ---
              if isLoadingInsights && dailyReflectionJson == nil {
                  SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
              } else {
                  DailyReflectionInsightCard(
                       jsonString: dailyReflectionJson,
                       generatedDate: dailyReflectionDate,
                       scrollProxy: scrollProxy,
                       cardId: "dailyReflectionCard"
                   )
                   .id("dailyReflectionCard")
                   .padding(.horizontal, styles.layout.paddingXL)
                   .opacity(cardsAppeared ? 1 : 0)
                   .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: cardsAppeared)
              }

             // --- Week in Review Card ---
              if isLoadingInsights && weekInReviewJson == nil {
                  SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
              } else {
                  WeekInReviewCard(
                       jsonString: weekInReviewJson,
                       generatedDate: weekInReviewDate,
                       scrollProxy: scrollProxy,
                       cardId: "weekInReviewCard"
                   )
                   .id("weekInReviewCard")
                   .padding(.horizontal, styles.layout.paddingXL)
                   .opacity(cardsAppeared ? 1 : 0)
                   .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: cardsAppeared)
              }

            // --- Add New Entry CTA ---
             VStack(spacing: styles.layout.spacingM) {
                 Text("Capture your thoughts and feelings as they happen.")
                     .font(styles.typography.bodyFont)
                     .foregroundColor(styles.colors.textSecondary)
                     .multilineTextAlignment(.center)
                     .padding(.horizontal) // Add horizontal padding to text

                 Button("Add New Entry") {
                     print("[InsightsView] Add New Entry button tapped.") // Debug Print
                     // Trigger sheet presentation in JournalView
                     appState.presentNewJournalEntrySheet = true
                     print("[InsightsView] Set presentNewJournalEntrySheet = true") // Debug Print
                     // Switch to Journal tab
                     print("[InsightsView] Posting switchToTabNotification (index 0)") // Debug Print
                     NotificationCenter.default.post(
                         name: .switchToTabNotification, // Use standard name
                         object: nil,
                         userInfo: ["tabIndex": 0] // Index 0 = Journal
                     )
                 }
                 .buttonStyle(UIStyles.PrimaryButtonStyle())
             }
             .padding(.horizontal, styles.layout.paddingXL) // Padding for the whole CTA VStack
             .padding(.vertical, styles.layout.spacingL) // Vertical padding


            // --- Feel Card ---
            if isLoadingInsights && feelInsightsJson == nil {
                SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
            } else {
                FeelInsightCard(
                    scrollProxy: scrollProxy,
                    cardId: "feelCard"
                )
                .id("feelCard")
                .padding(.horizontal, styles.layout.paddingXL)
                .opacity(cardsAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: cardsAppeared)
            }

            // --- Think Card ---
            if isLoadingInsights && thinkInsightsJson == nil {
                SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
            } else {
                 ThinkInsightCard(
                     scrollProxy: scrollProxy,
                     cardId: "thinkCard"
                 )
                 .id("thinkCard")
                 .padding(.horizontal, styles.layout.paddingXL)
                 .opacity(cardsAppeared ? 1 : 0)
                 .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: cardsAppeared)
             }

             // --- Act Card ---
            if isLoadingInsights && actInsightsJson == nil {
                SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
            } else {
                  ActInsightCard(
                      scrollProxy: scrollProxy,
                      cardId: "actCard"
                  )
                  .id("actCard")
                  .padding(.horizontal, styles.layout.paddingXL)
                  .opacity(cardsAppeared ? 1 : 0)
                  .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: cardsAppeared)
              }

             // --- Learn Card ---
             if isLoadingInsights && learnInsightsJson == nil {
                 SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
             } else {
                   LearnInsightCard(
                       scrollProxy: scrollProxy,
                       cardId: "learnCard"
                   )
                   .id("learnCard")
                   .padding(.horizontal, styles.layout.paddingXL)
                   .opacity(cardsAppeared ? 1 : 0)
                   .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: cardsAppeared)
               }

            // --- Reflect CTA ---
             VStack(spacing: styles.layout.spacingM) {
                 Text("Discuss your insights and explore patterns with AI.")
                     .font(styles.typography.bodyFont)
                     .foregroundColor(styles.colors.textSecondary)
                     .multilineTextAlignment(.center)
                     .padding(.horizontal) // Add horizontal padding to text

                 Button("Start Reflection") {
                     print("[InsightsView] Posting switchToTabNotification (index 2)") // Debug Print
                     NotificationCenter.default.post(
                         name: .switchToTabNotification, // Use standard name
                         object: nil,
                         userInfo: ["tabIndex": 2] // Index 2 = Reflect
                     )
                 }
                 .buttonStyle(UIStyles.PrimaryButtonStyle())
             }
              .padding(.horizontal, styles.layout.paddingXL) // Padding for the whole CTA VStack
              .padding(.vertical, styles.layout.spacingL) // Vertical padding


            // Bottom padding
            Spacer().frame(height: styles.layout.paddingXL + 80) // Keep bottom padding
        }
        .padding(.top, 0) // No top padding needed on LazyVStack itself
    }


    // MARK: - Component Views
    private var emptyStateView: some View {
         VStack(spacing: styles.layout.spacingL) {
             Spacer(minLength: 60) // Adjust spacer if needed
             ZStack {
                 // ... (Circles animation remains the same) ...
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

             // [7.2] Updated Text
             Text("Add more journal entries to unlock pattern analysis and personalized insights here.")
                 .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                 .multilineTextAlignment(.center).padding(.horizontal, styles.layout.paddingXL)
                 .offset(y: headerAppeared ? 0 : 20).opacity(headerAppeared ? 1 : 0)
                 .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: headerAppeared)

             // [7.1] Add Journal Entry Button
             Button("Add Journal Entry") {
                 print("[InsightsView] Empty State - Posting switchToTabNotification (index 0)") // Debug Print
                 NotificationCenter.default.post(
                     name: .switchToTabNotification, // Use standard name
                     object: nil,
                     userInfo: ["tabIndex": 0] // Index 0 is Journal Tab
                 )
             }
             .buttonStyle(UIStyles.PrimaryButtonStyle())
             .padding(.horizontal, styles.layout.paddingXL * 1.5) // Make button slightly narrower
             .padding(.top, styles.layout.spacingL) // Space above button
             .offset(y: headerAppeared ? 0 : 20) // Match text animation
             .opacity(headerAppeared ? 1 : 0)
             .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: headerAppeared)

             Spacer() // Pushes content towards center vertically
         }.padding(.vertical, 50)
     }


    // Helper to check if all insight states are nil
    private func areAllInsightsNil() -> Bool {
        return dailyReflectionJson == nil &&
               weekInReviewJson == nil &&
               feelInsightsJson == nil &&
               thinkInsightsJson == nil &&
               actInsightsJson == nil &&
               learnInsightsJson == nil &&
               journeyJson == nil
    }


    // --- Data Loading ---
    private func loadStoredInsights() {
         // Set initial loading state only if starting completely fresh
          if lastLoadTimestamp == nil {
              isLoadingInsights = true
          }
         print("[InsightsView] Loading stored insights from DB...")
         Task {
             // ... (async let fetches remain the same) ...
             async let dailyReflectionFetch = try? self.databaseService.loadLatestInsight(type: "dailyReflection")
             async let weekInReviewFetch = try? self.databaseService.loadLatestInsight(type: "weekInReview")
             async let feelFetch = try? self.databaseService.loadLatestInsight(type: "feelInsights")
             async let thinkFetch = try? self.databaseService.loadLatestInsight(type: "thinkInsights")
             async let actFetch = try? self.databaseService.loadLatestInsight(type: "actInsights")
             async let learnFetch = try? self.databaseService.loadLatestInsight(type: "learnInsights")
             async let journeyFetch = try? self.databaseService.loadLatestInsight(type: "journeyNarrative")

             let dailyReflectionResult = await dailyReflectionFetch
             let weekInReviewResult = await weekInReviewFetch
             let feelResult = await feelFetch
             let thinkResult = await thinkFetch
             let actResult = await actFetch
             let learnResult = await learnFetch
             let journeyResult = await journeyFetch

             await MainActor.run {
                 // Update state variables...
                 if let (json, date) = dailyReflectionResult { self.dailyReflectionJson = json; self.dailyReflectionDate = date } else { self.dailyReflectionJson = nil; self.dailyReflectionDate = nil }
                 if let (json, date) = weekInReviewResult { self.weekInReviewJson = json; self.weekInReviewDate = date } else { self.weekInReviewJson = nil; self.weekInReviewDate = nil }
                 if let (json, date) = feelResult { self.feelInsightsJson = json; self.feelInsightsDate = date } else { self.feelInsightsJson = nil; self.feelInsightsDate = nil }
                 if let (json, date) = thinkResult { self.thinkInsightsJson = json; self.thinkInsightsDate = date } else { self.thinkInsightsJson = nil; self.thinkInsightsDate = nil }
                 if let (json, date) = actResult { self.actInsightsJson = json; self.actInsightsDate = date } else { self.actInsightsJson = nil; self.actInsightsDate = nil }
                 if let (json, date) = learnResult { self.learnInsightsJson = json; self.learnInsightsDate = date } else { self.learnInsightsJson = nil; self.learnInsightsDate = nil }
                 if let (json, date) = journeyResult { self.journeyJson = json; self.journeyDate = date } else { self.journeyJson = nil; self.journeyDate = nil }

                 // Set isLoadingInsights to false AFTER data is loaded/processed
                 isLoadingInsights = false
                 lastLoadTimestamp = Date() // Update timestamp
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
         // Preview showing the empty state specifically
          PreviewDataLoadingContainer(loadData: false) { // Corrected initializer call
              InsightsView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true))
                  .environmentObject(AppState()) // Provide an empty AppState
                  .environmentObject(chatManager) // Pass chatManager even if empty
                  .environmentObject(databaseService)
                  .environmentObject(subscriptionManager)
                  .environmentObject(ThemeManager.shared)
                  .environmentObject(UIStyles.shared)
          }
          .previewDisplayName("Empty State")

         // Preview showing the loaded state
          PreviewDataLoadingContainer(loadData: true) { // Corrected initializer call
               InsightsView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true))
                   .environmentObject(appState) // Use the one with loaded data
                   .environmentObject(chatManager)
                   .environmentObject(databaseService)
                   .environmentObject(subscriptionManager)
                   .environmentObject(ThemeManager.shared)
                   .environmentObject(UIStyles.shared)
           }
           .previewDisplayName("Loaded State")
     }

     // Keep PreviewDataLoadingContainer but allow skipping data load
     // Make initializer public or internal if needed across modules
     struct PreviewDataLoadingContainer<Content: View>: View {
         @ViewBuilder let content: Content
         let loadData: Bool // Add flag
         @State private var isLoading = true

         // Corrected Initializer with labels
          init(loadData: Bool, @ViewBuilder content: () -> Content) {
              self.loadData = loadData
              self.content = content()
          }


         var body: some View {
             Group {
                 if isLoading && loadData { // Only show loader if loadData is true
                      ProgressView("Loading Preview Data...").frame(maxWidth: .infinity, maxHeight: .infinity).background(UIStyles.shared.colors.appBackground).onAppear { Task { await performDataLoad(); isLoading = false } }
                 } else if isLoading && !loadData { // If not loading data, just set isLoading to false
                      Color.clear.onAppear { isLoading = false }
                 }
                 else { content }
             }
         }
         func performDataLoad() async { // Renamed function
              guard loadData else { return } // Skip if flag is false
              print("Preview: Starting data load...")
              let dbService = InsightsView_Previews.databaseService
              let state = InsightsView_Previews.appState
              let chatMgr = InsightsView_Previews.chatManager
              do {
                  let entries = try dbService.loadAllJournalEntries()
                  await MainActor.run { state._journalEntries = entries } // Modify underlying storage
                  print("Preview: Loaded \(entries.count) entries")
                  let chats = try dbService.loadAllChats()
                  await MainActor.run { chatMgr.chats = chats; if let first = chats.first { chatMgr.currentChat = first } else { chatMgr.currentChat = Chat() } }
                  print("Preview: Loaded \(chats.count) chats")
              } catch { print("‼️ Preview data loading error: \(error)") }
              print("Preview: Data loading finished.")
         }
     }
}