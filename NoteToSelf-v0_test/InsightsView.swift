import SwiftUI
import Charts

// MARK: - Skeleton Card View [4.1] - Keep As Is
struct SkeletonCardView: View {
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingL) {
            HStack {
                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                    .fill(styles.colors.secondaryBackground.opacity(0.5))
                    .frame(width: 120, height: 20)
                Spacer()
                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                    .fill(styles.colors.secondaryBackground.opacity(0.5))
                    .frame(width: 50, height: 20)
            }
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .fill(styles.colors.secondaryBackground.opacity(0.5))
                .frame(height: 60)
             HStack {
                  Spacer()
                  RoundedRectangle(cornerRadius: styles.layout.radiusM)
                      .fill(styles.colors.secondaryBackground.opacity(0.3))
                      .frame(width: 80, height: 28)
             }
        }
        .padding(styles.layout.cardInnerPadding)
        .background(styles.colors.cardBackground)
        .cornerRadius(styles.layout.radiusM)
        .overlay(
             RoundedRectangle(cornerRadius: styles.layout.radiusM)
                 .stroke(styles.colors.divider, lineWidth: 1)
         )
        .shimmer()
    }
}


// MARK: - Main Insights View (Rewritten with VStack)
struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var databaseService: DatabaseService
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled // Keep for disabling scroll if needed

    // Tab Bar State - No longer used for scroll tracking, but keep if parent needs them
    @Binding var tabBarOffset: CGFloat
    @Binding var lastScrollPosition: CGFloat
    @Binding var tabBarVisible: Bool

    // --- State Variables (Keep As Is) ---
    @State private var dailyReflectionJson: String? = nil
    @State private var dailyReflectionDate: Date? = nil
    @State private var weekInReviewJson: String? = nil
    @State private var weekInReviewDate: Date? = nil
    @State private var feelInsightsJson: String? = nil
    @State private var feelInsightsDate: Date? = nil
    @State private var thinkInsightsJson: String? = nil
    @State private var thinkInsightsDate: Date? = nil
    @State private var actInsightsJson: String? = nil
    @State private var actInsightsDate: Date? = nil
    @State private var learnInsightsJson: String? = nil
    @State private var learnInsightsDate: Date? = nil
    @State private var journeyJson: String? = nil
    @State private var journeyDate: Date? = nil
    @State private var isLoadingInsights: Bool = false
    @State private var lastLoadTimestamp: Date? = nil
    @State private var headerAppeared = false
    @State private var cardsAppeared = false
    @ObservedObject private var styles = UIStyles.shared

    // --- Computed Properties (Keep As Is) ---
    private var isWeekInReviewActive: Bool {
        guard let generatedDate = weekInReviewDate else { return false }
        let hoursSinceGenerated = Calendar.current.dateComponents([.hour], from: generatedDate, to: Date()).hour ?? 46
        return hoursSinceGenerated < 45
    }

    private var hasAnyEntries: Bool { !appState.journalEntries.isEmpty }

    private var timestampFormatter: DateFormatter {
        let formatter = DateFormatter(); formatter.dateStyle = .medium; formatter.timeStyle = .short; return formatter
    }

    private var dailyReflectionHasContent: Bool {
        guard let json = dailyReflectionJson, !json.isEmpty, let data = json.data(using: .utf8) else { return false }
        if let result = try? JSONDecoder().decode(DailyReflectionResult.self, from: data), !(result.snapshotText?.isEmpty ?? true) { return true }
        return false
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            styles.colors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // --- Header (Keep As Is) ---
                headerView

                // --- ScrollView with VStack ---
                ScrollView {
                    // --- Daily Tagline ---
                    // Use dynamic tagline based on the day
                    DailyTaglineView(tagline: Taglines.getTagline(for: .insights), iconName: "chart.bar.fill") // Insights icon
  
                    // Main content container using VStack
                    VStack(spacing: styles.layout.cardSpacing) { // Use cardSpacing for VStack
                        // Timestamp Display (Keep As Is)
                        timestampView

                        // --- Content: Empty State or Cards ---
                        if !hasAnyEntries {
                            emptyStateView // Keep empty state
                        } else {
                            // --- Cards & CTAs (Order matters) ---
                            dailyReflectionSection
                            addNewNoteCTA // Conditional CTA
                            weekInReviewSection
                            feelInsightSection
                            thinkInsightSection
                            actInsightSection
                            learnInsightSection
                            reflectCTASection // Reflect CTA
                            engagementHookSection // Engagement Hook
                        }
                    }
                    .padding(.top, styles.layout.spacingM) // Add padding above first element
                    .padding(.bottom, styles.layout.paddingXL + 80) // Padding below last element
                }
                .coordinateSpace(name: "scrollView") // Keep coordinate space if needed elsewhere
                .disabled(mainScrollingDisabled) // Keep scroll disabling capability
            }
        }
        .onAppear {
            // Trigger initial load
             if lastLoadTimestamp == nil { isLoadingInsights = true; loadStoredInsights() }
            // Trigger animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { headerAppeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { cardsAppeared = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
            print("[InsightsView] Received insightsDidUpdate notification. Reloading insights.")
            loadStoredInsights() // Reload data
        }
    }

    // MARK: - Subviews (Rebuilt Sections)

    private var headerView: some View {
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
                Button(action: { NotificationCenter.default.post(name: .toggleSettingsNotification, object: nil) }) {
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
    }

    @ViewBuilder private var timestampView: some View {
        if let timestamp = lastLoadTimestamp {
             HStack {
                 Spacer()
                 Text("Last updated: \(timestamp, formatter: timestampFormatter)")
                     .font(styles.typography.caption)
                     .foregroundColor(styles.colors.textSecondary.opacity(0.8))
                 Spacer()
             }
             .padding(.horizontal, styles.layout.paddingXL)
        } else if isLoadingInsights && hasAnyEntries {
             HStack {
                 Spacer()
                 Text("Loading insights...")
                     .font(styles.typography.caption)
                     .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                 Spacer()
             }
              .padding(.horizontal, styles.layout.paddingXL)
        }
    }

    private var emptyStateView: some View {
         VStack(spacing: styles.layout.spacingL) {
             Spacer(minLength: 60)
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
             Text("Add more journal entries to unlock pattern analysis and personalized insights here.")
                 .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                 .multilineTextAlignment(.center).padding(.horizontal, styles.layout.paddingXL)
                 .offset(y: headerAppeared ? 0 : 20).opacity(headerAppeared ? 1 : 0)
                 .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: headerAppeared)
             Button("Add New Note") {
                 appState.objectWillChange.send()
                 appState.presentNewJournalEntrySheet = true
             }
             .buttonStyle(UIStyles.PrimaryButtonStyle())
             .padding(.horizontal, styles.layout.paddingXL * 1.5)
             .padding(.top, styles.layout.spacingL)
             .offset(y: headerAppeared ? 0 : 20)
             .opacity(headerAppeared ? 1 : 0)
             .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: headerAppeared)
             Spacer()
         }.padding(.vertical, 50)
     }

    // --- Card Sections ---
    @ViewBuilder private var dailyReflectionSection: some View {
        if isLoadingInsights && dailyReflectionJson == nil {
            SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
        } else {
            DailyReflectionInsightCard(
                 jsonString: dailyReflectionJson,
                 generatedDate: dailyReflectionDate,
                 cardId: "dailyReflectionCard"
             )
             .id("dailyReflectionCard")
             .padding(.horizontal, styles.layout.paddingXL)
             .opacity(cardsAppeared ? 1 : 0)
             .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: cardsAppeared)
             // Note: Vertical padding handled by VStack spacing or card's internal padding
        }
    }

    @ViewBuilder private var addNewNoteCTA: some View {
        if hasAnyEntries && !dailyReflectionHasContent { // Show only if entries exist but reflection doesn't
             VStack(spacing: styles.layout.spacingM) {
                 Text("Capture your thoughts and feelings as they happen.")
                     .font(styles.typography.bodyFont)
                     .foregroundColor(styles.colors.textSecondary)
                     .multilineTextAlignment(.center)
                     .padding(.horizontal)
                 Button("Add New Note") {
                     appState.objectWillChange.send()
                     appState.presentNewJournalEntrySheet = true
                 }
                 .buttonStyle(UIStyles.PrimaryButtonStyle())
             }
             .padding(.horizontal, styles.layout.paddingXL)
             .transition(.opacity.combined(with: .scale))
         }
    }

    @ViewBuilder private var weekInReviewSection: some View {
        if isWeekInReviewActive || (isLoadingInsights && weekInReviewJson == nil) { // Show skeleton only if loading AND it *might* appear
            if isLoadingInsights && weekInReviewJson == nil {
                 SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
            } else if isWeekInReviewActive { // Only show card if active
                WeekInReviewCard(
                     jsonString: weekInReviewJson,
                     generatedDate: weekInReviewDate,
                     cardId: "weekInReviewCard"
                 )
                 .id("weekInReviewCard")
                 .padding(.horizontal, styles.layout.paddingXL)
                 .opacity(cardsAppeared ? 1 : 0)
                 .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: cardsAppeared)
            }
        } else {
            EmptyView() // Don't show anything if not active and not loading
        }
    }

    @ViewBuilder private var feelInsightSection: some View {
        if isLoadingInsights && feelInsightsJson == nil {
            SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
        } else {
            FeelInsightCard(cardId: "feelCard")
            .id("feelCard")
            .padding(.horizontal, styles.layout.paddingXL)
            .opacity(cardsAppeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: cardsAppeared)
        }
    }

    @ViewBuilder private var thinkInsightSection: some View {
        if isLoadingInsights && thinkInsightsJson == nil {
            SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
        } else {
             ThinkInsightCard(cardId: "thinkCard")
             .id("thinkCard")
             .padding(.horizontal, styles.layout.paddingXL)
             .opacity(cardsAppeared ? 1 : 0)
             .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: cardsAppeared)
         }
    }

    @ViewBuilder private var actInsightSection: some View {
        if isLoadingInsights && actInsightsJson == nil {
            SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
        } else {
              ActInsightCard(cardId: "actCard")
              .id("actCard")
              .padding(.horizontal, styles.layout.paddingXL)
              .opacity(cardsAppeared ? 1 : 0)
              .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: cardsAppeared)
          }
    }

    @ViewBuilder private var learnInsightSection: some View {
         if isLoadingInsights && learnInsightsJson == nil {
             SkeletonCardView().padding(.horizontal, styles.layout.paddingXL)
         } else {
               LearnInsightCard(cardId: "learnCard")
               .id("learnCard")
               .padding(.horizontal, styles.layout.paddingXL)
               .opacity(cardsAppeared ? 1 : 0)
               .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: cardsAppeared)
           }
    }

    private var reflectCTASection: some View {
         VStack(spacing: styles.layout.spacingM) {
             Text("Discuss your insights and explore patterns with AI.")
                 .font(styles.typography.bodyFont)
                 .foregroundColor(styles.colors.textSecondary)
                 .multilineTextAlignment(.center)
                 .padding(.horizontal)
             Button("Start Reflection") {
                 chatManager.startNewChat()
                 NotificationCenter.default.post(name: .switchToTabNotification, object: nil, userInfo: ["tabIndex": 2])
             }
             .buttonStyle(UIStyles.PrimaryButtonStyle())
         }
          .padding(.horizontal, styles.layout.paddingXL)
    }

    private var engagementHookSection: some View {
        VStack(alignment: .center, spacing: styles.layout.spacingM) {
            Image(systemName: "pencil.line")
                .font(.system(size: 40))
                .foregroundColor(styles.colors.accent)
                .padding(.bottom, styles.layout.spacingS)
            Text("What Insight Do You Crave?")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
                .multilineTextAlignment(.center)
            Text("Your journey is unique, and this app is evolving. What new insight type would help you most right now? Share your ideas and help shape the future of Note to Self!")
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
            Button { print("[InsightsView] 'Share Your Ideas' button tapped.") } label: {
                 Text("Share Your Ideas")
                     .foregroundColor(styles.colors.accent)
                     .font(styles.typography.bodyLarge)
            }
            .buttonStyle(UIStyles.GhostButtonStyle())
            .padding(.top, styles.layout.spacingS)
        }
        .padding(.vertical, styles.layout.paddingXL)
        .padding(.horizontal, styles.layout.paddingL)
        .background(styles.colors.secondaryBackground.opacity(0.5))
        .cornerRadius(styles.layout.radiusL)
        .padding(.horizontal, styles.layout.paddingXL)
    }

    // --- Data Loading (Keep As Is) ---
    private func loadStoredInsights() {
        if lastLoadTimestamp == nil { isLoadingInsights = true }
        print("[InsightsView] Loading stored insights from DB...")
        Task {
            async let dailyReflectionFetch = try? databaseService.loadLatestInsight(type: "dailyReflection")
            async let weekInReviewFetch = try? databaseService.loadLatestInsight(type: "weekInReview")
            async let feelFetch = try? databaseService.loadLatestInsight(type: "feelInsights")
            async let thinkFetch = try? databaseService.loadLatestInsight(type: "thinkInsights")
            async let actFetch = try? databaseService.loadLatestInsight(type: "actInsights")
            async let learnFetch = try? databaseService.loadLatestInsight(type: "learnInsights")
            async let journeyFetch = try? databaseService.loadLatestInsight(type: "journeyNarrative")

            let dailyReflectionResult = await dailyReflectionFetch
            let weekInReviewResult = await weekInReviewFetch
            let feelResult = await feelFetch
            let thinkResult = await thinkFetch
            let actResult = await actFetch
            let learnResult = await learnFetch
            let journeyResult = await journeyFetch

            await MainActor.run {
                if let (json, date, _) = dailyReflectionResult { dailyReflectionJson = json; dailyReflectionDate = date } else { dailyReflectionJson = nil; dailyReflectionDate = nil }
                if let (json, date, _) = weekInReviewResult { weekInReviewJson = json; weekInReviewDate = date } else { weekInReviewJson = nil; weekInReviewDate = nil }
                if let (json, date, _) = feelResult { feelInsightsJson = json; feelInsightsDate = date } else { feelInsightsJson = nil; feelInsightsDate = nil }
                if let (json, date, _) = thinkResult { thinkInsightsJson = json; thinkInsightsDate = date } else { thinkInsightsJson = nil; thinkInsightsDate = nil }
                if let (json, date, _) = actResult { actInsightsJson = json; actInsightsDate = date } else { actInsightsJson = nil; actInsightsDate = nil }
                if let (json, date, _) = learnResult { learnInsightsJson = json; learnInsightsDate = date } else { learnInsightsJson = nil; learnInsightsDate = nil }
                if let (json, date, _) = journeyResult { journeyJson = json; journeyDate = date } else { journeyJson = nil; journeyDate = nil }

                isLoadingInsights = false
                lastLoadTimestamp = Date()
                print("[InsightsView] Finished loading insights.")
            }
        }
    }
}

// MARK: - Previews (Keep As Is)
struct InsightsView_Previews: PreviewProvider {
      @StateObject static var databaseService = DatabaseService()
      static var llmService = LLMService.shared
      @StateObject static var subscriptionManager = SubscriptionManager.shared
      @StateObject static var appState = AppState()
      @StateObject static var chatManager = ChatManager(databaseService: databaseService, llmService: llmService, subscriptionManager: subscriptionManager)

      static var previews: some View {
           PreviewDataLoadingContainer(loadData: false) {
               InsightsView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true))
                   .environmentObject(AppState())
                   .environmentObject(chatManager)
                   .environmentObject(databaseService)
                   .environmentObject(subscriptionManager)
                   .environmentObject(ThemeManager.shared)
                   .environmentObject(UIStyles.shared)
           }
           .previewDisplayName("Empty State")

           PreviewDataLoadingContainer(loadData: true) {
                InsightsView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true))
                    .environmentObject(appState)
                    .environmentObject(chatManager)
                    .environmentObject(databaseService)
                    .environmentObject(subscriptionManager)
                    .environmentObject(ThemeManager.shared)
                    .environmentObject(UIStyles.shared)
            }
            .previewDisplayName("Loaded State")
      }

      struct PreviewDataLoadingContainer<Content: View>: View {
          @ViewBuilder let content: Content
          let loadData: Bool
          @State private var isLoading = true

           init(loadData: Bool, @ViewBuilder content: () -> Content) {
               self.loadData = loadData
               self.content = content()
           }

          var body: some View {
              Group {
                  if isLoading && loadData {
                       ProgressView("Loading Preview Data...").frame(maxWidth: .infinity, maxHeight: .infinity).background(UIStyles.shared.colors.appBackground).onAppear { Task { await performDataLoad(); isLoading = false } }
                  } else if isLoading && !loadData {
                       Color.clear.onAppear { isLoading = false }
                  }
                  else { content }
              }
          }
          func performDataLoad() async {
               guard loadData else { return }
               print("Preview: Starting data load...")
               let dbService = InsightsView_Previews.databaseService
               let state = InsightsView_Previews.appState
               let chatMgr = InsightsView_Previews.chatManager
               do {
                   let entries = try dbService.loadAllJournalEntries()
                   await MainActor.run { state._journalEntries = entries }
                   print("Preview: Loaded \(entries.count) entries")
                   let chats = try dbService.loadAllChats()
                   await MainActor.run { chatMgr.chats = chats; if let first = chats.first { chatMgr.currentChat = first } else { chatMgr.currentChat = Chat() } }
                   print("Preview: Loaded \(chats.count) chats")
               } catch { print("‼️ Preview data loading error: \(error)") }
               print("Preview: Data loading finished.")
          }
      }
}