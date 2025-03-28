import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled
    @State private var selectedMonth: Date = Date()
    @Binding var tabBarOffset: CGFloat
    @Binding var lastScrollPosition: CGFloat
    @Binding var tabBarVisible: Bool
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    // Check if weekly summary is fresh (generated in the past 24 hours)
    private var isWeeklySummaryFresh: Bool {
        // For demo purposes, we'll consider it fresh if there's an entry from today
        return appState.journalEntries.contains { Calendar.current.isDateInToday($0.date) }
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
                    
                    // 1. Streak Card
                    StreakInsightCard(streak: appState.currentStreak)
                        .padding(.horizontal, styles.layout.paddingXL)
                    
                    // Weekly Summary Card
                    WeeklySummaryInsightCard(entries: appState.journalEntries)
                        .padding(.horizontal, styles.layout.paddingXL)
                    
                    // Deeper Insights Section
                    styles.sectionHeader("Deeper Insights")
                    
                    // AI Reflection Card
                    ChatInsightCard()
                        .padding(.horizontal, styles.layout.paddingXL)
                        .accessibilityLabel("AI Reflection")
                    
                    // Mood Analysis Card
                    MoodTrendsInsightCard(entries: appState.journalEntries)
                        .padding(.horizontal, styles.layout.paddingXL)
                        .accessibilityLabel("Mood Analysis")
                    
                    // Recommendations Card
                    RecommendationsInsightCard(entries: appState.journalEntries)
                        .padding(.horizontal, styles.layout.paddingXL)
                        .padding(.bottom, styles.layout.paddingXL + 80) // Extra padding for tab bar
                    
                    // Hidden cards - commented out but kept for reference
                    /*
                    // Calendar Card - integrated with Current Streak
                    CalendarInsightCard(selectedMonth: $selectedMonth, entries: appState.journalEntries)
                        .padding(.horizontal, styles.layout.paddingXL)
                    
                    // Weekly Insight Card - moved to hide folder
                    WeeklyInsightCard(entries: appState.journalEntries)
                        .padding(.horizontal, styles.layout.paddingXL)
                    
                    // Writing Consistency Card - moved to hide folder
                    WritingConsistencyInsightCard(entries: appState.journalEntries)
                        .padding(.horizontal, styles.layout.paddingXL)
                    
                    // Mood Distribution Card - moved to hide folder
                    MoodDistributionInsightCard(entries: appState.journalEntries)
                        .padding(.horizontal, styles.layout.paddingXL)
                    */
                }
            }
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
        }
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
}
}

// MARK: - Streak Card

struct StreakCard: View {
    let streak: Int
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        styles.card(
            VStack(spacing: styles.layout.spacingM) {
                HStack {
                    Text("Current Streak")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                    
                    Image(systemName: "flame.fill")
                        .foregroundColor(styles.colors.accent)
                        .font(.system(size: styles.layout.iconSizeL))
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(streak)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(styles.colors.text)
                    
                    Text(streak == 1 ? "day" : "days")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                }
                
                Text("Keep up the good work! Consistency is key to building a journaling habit.")
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, styles.layout.spacingS)
            }
            .padding(styles.layout.paddingL)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Monthly Calendar Section

struct MonthlyCalendarSection: View {
    @Binding var selectedMonth: Date
    let entries: [JournalEntry]
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols
    
    var body: some View {
        styles.card(
            VStack(spacing: styles.layout.spacingM) {
                // Month navigation
                HStack {
                    Text("Monthly Activity")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                    
                    HStack(spacing: styles.layout.spacingM) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)!
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(styles.colors.accent)
                        }
                        
                        Text(monthYearString(from: selectedMonth))
                            .font(styles.typography.label)
                            .foregroundColor(styles.colors.text)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)!
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(styles.colors.accent)
                        }
                    }
                }
                
                // Weekday headers
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Calendar days
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(daysInMonth(), id: \.self) { day in
                        if day.day != 0 {
                            CalendarDayView(day: day, entries: entries)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            // Empty cell for days not in this month
                            Color.clear
                                .frame(height: 40)
                        }
                    }
                }
            }
            .padding(styles.layout.paddingL)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [CalendarDay] {
        let calendar = Calendar.current
        
        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        let firstDayOfMonth = calendar.date(from: components)!
        
        // Get the weekday of the first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Get the number of days in the month
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
        let numDays = range.count
        
        var days: [CalendarDay] = []
        
        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(CalendarDay(day: 0, date: Date()))
        }
        
        // Add cells for each day of the month
        for day in 1...numDays {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)!
            days.append(CalendarDay(day: day, date: date))
        }
        
        return days
    }
}

struct CalendarDay: Hashable {
    let day: Int
    let date: Date
}

struct CalendarDayView: View {
    let day: CalendarDay
    let entries: [JournalEntry]
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    private var hasEntry: Bool {
        let calendar = Calendar.current
        return entries.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: day.date)
        }
    }
    
    private var entryMood: Mood? {
        let calendar = Calendar.current
        return entries.first { entry in
            calendar.isDate(entry.date, inSameDayAs: day.date)
        }?.mood
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    var body: some View {
        ZStack {
            // Background circle with subtle gradient for depth
            if hasEntry {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    entryMood?.color.opacity(0.4) ?? styles.colors.accent.opacity(0.4),
                                    entryMood?.color.opacity(0.2) ?? styles.colors.accent.opacity(0.2)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
            }
            
            if isToday {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    styles.colors.accent,
                                    styles.colors.accent.opacity(0.7)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 40, height: 40)
            }
            
            Text("\(day.day)")
                .font(styles.typography.bodyFont)
                .foregroundColor(hasEntry ? styles.colors.text : styles.colors.textSecondary)
        }
        .frame(height: 40)
    }
}

// MARK: - Mood Chart Section

struct MoodChartSection: View {
    let entries: [JournalEntry]
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    private var lastTwoWeeksEntries: [JournalEntry] {
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date())!
        
        return entries
            .filter { $0.date >= twoWeeksAgo }
            .sorted { $0.date < $1.date }
    }
    
    private var moodData: [MoodDataPoint] {
        let calendar = Calendar.current
        var result: [MoodDataPoint] = []
        
        // Create a dictionary to group entries by day
        var entriesByDay: [Date: JournalEntry] = [:]
        
        for entry in lastTwoWeeksEntries {
            let day = calendar.startOfDay(for: entry.date)
            entriesByDay[day] = entry
        }
        
        // Fill in the last 14 days
        for dayOffset in (0..<14).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: Date()))!
            let entry = entriesByDay[date]
            
            let moodValue: Double
            if let entry = entry {
                switch entry.mood {
                case .happy: moodValue = 4
                case .excited: moodValue = 5
                case .neutral: moodValue = 3
                case .stressed: moodValue = 2
                case .sad: moodValue = 1
                default: moodValue = 3 // Default to neutral for other moods
                }
            } else {
                moodValue = 0 // No entry for this day
            }
            
            result.append(MoodDataPoint(date: date, value: moodValue))
        }
        
        return result
    }
    
    private func formattedMoodText(_ mood: Mood, intensity: Int = 2) -> String {
        switch intensity {
        case 1: return "Slightly \(mood.name)"
        case 3: return "Very \(mood.name)"
        default: return mood.name
        }
    }
    
    var body: some View {
        styles.card(
            VStack(spacing: styles.layout.spacingM) {
                HStack {
                    Text("Mood Trends")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                }
                
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(moodData, id: \.date) { dataPoint in
                            if dataPoint.value > 0 {
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Mood", dataPoint.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [styles.colors.accent, styles.colors.accent.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                
                                PointMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Mood", dataPoint.value)
                                )
                                .foregroundStyle(styles.colors.accent)
                                .symbolSize(30)
                            }
                        }
                    }
                    .chartYScale(domain: 1...5)
                    .chartYAxis {
                        AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                            AxisValueLabel {
                                switch value.index {
                                case 0: Text("Sad").font(styles.typography.caption)
                                case 1: Text("Anxious").font(styles.typography.caption)
                                case 2: Text("Neutral").font(styles.typography.caption)
                                case 3: Text("Happy").font(styles.typography.caption)
                                case 4: Text("Excited").font(styles.typography.caption)
                                default: Text("")
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 2)) { value in
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(formatDate(date))
                                        .font(styles.typography.caption)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                } else {
                    // Fallback for iOS 15
                    Text("Mood chart requires iOS 16 or later")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                }
                
                Text("Track your mood patterns over time to identify trends and triggers.")
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, styles.layout.spacingS)
            }
            .padding(styles.layout.paddingL)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

struct MoodDataPoint {
    let date: Date
    let value: Double
}

// MARK: - Advanced Analytics Section (Subscription Gated)

struct AdvancedAnalyticsSection: View {
    let subscriptionTier: SubscriptionTier
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        styles.card(
            ZStack {
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Advanced Analytics")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: styles.layout.spacingL) {
                        AnalyticItem(
                            icon: "brain.head.profile",
                            title: "Mood Prediction",
                            value: "87%"
                        )
                        
                        AnalyticItem(
                            icon: "text.magnifyingglass",
                            title: "Top Topics",
                            value: "Work, Health"
                        )
                        
                        AnalyticItem(
                            icon: "chart.bar.fill",
                            title: "Sentiment",
                            value: "+12%"
                        )
                    }
                    
                    Text("Unlock deeper insights with advanced analytics to better understand your patterns and improve your well-being.")
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, styles.layout.spacingS)
                }
                .padding(styles.layout.paddingL)
                .blur(radius: subscriptionTier == .premium ? 0 : 3)
                
                if subscriptionTier != .premium {
                    VStack(spacing: styles.layout.spacingM) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 32))
                            .foregroundColor(styles.colors.accent)
                        
                        Text("Premium Feature")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Button("Upgrade") {
                            // Show subscription options
                        }
                        .buttonStyle(UIStyles.PrimaryButtonStyle(
                            colors: styles.colors,
                            typography: styles.typography,
                            layout: styles.layout
                        ))
                        .frame(width: 150)
                    }
                    .padding(styles.layout.paddingL)
                    .background(
                        RoundedRectangle(cornerRadius: styles.layout.radiusL)
                            .fill(styles.colors.surface.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                }
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
}

struct AnalyticItem: View {
    let icon: String
    let title: String
    let value: String
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingS) {
            Image(systemName: icon)
                .font(.system(size: styles.layout.iconSizeL))
                .foregroundColor(styles.colors.accent)
            
            Text(value)
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.text)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        // Sample data loading should ideally happen via DB now, but keep for preview consistency if needed
        // appState.loadSampleData() 
        let databaseService = DatabaseService() // Create DB service for preview
        let chatManager = ChatManager(databaseService: databaseService) // Create ChatManager with DB service
        
        // Load initial data into managers for preview
        // This mimics the async loading in the main app flow
        Task {
            do {
                let entries = try databaseService.loadAllJournalEntries()
                await MainActor.run { appState.journalEntries = entries }
                
                let chats = try databaseService.loadAllChats()
                await MainActor.run { 
                    chatManager.chats = chats
                    if let first = chats.first { chatManager.currentChat = first }
                }
            } catch {
                print("Preview data loading error: \(error)")
            }
        }

        return InsightsView(
            tabBarOffset: .constant(0),
            lastScrollPosition: .constant(0),
            tabBarVisible: .constant(true)
        )
        .environmentObject(appState)
        .environmentObject(chatManager) // Pass the initialized ChatManager
        .environmentObject(databaseService) // Pass the DatabaseService
    }
}
