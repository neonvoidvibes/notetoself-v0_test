import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMonth: Date = Date()
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: styles.layout.spacingXL) {
                // Header
                HStack {
                    Text("Insights")
                        .font(styles.typography.title1)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                }
                .padding(.horizontal, styles.layout.paddingXL)
                .padding(.top, styles.layout.paddingL)
                
                // Current Streak
                StreakCard(streak: appState.currentStreak)
                    .padding(.horizontal, styles.layout.paddingL)
                
                // Monthly Calendar
                MonthlyCalendarSection(selectedMonth: $selectedMonth, entries: appState.journalEntries)
                    .padding(.horizontal, styles.layout.paddingL)
                
                // Mood Chart
                MoodChartSection(entries: appState.journalEntries)
                    .padding(.horizontal, styles.layout.paddingL)
                
                // Advanced Analytics (Subscription Gated)
                AdvancedAnalyticsSection(subscriptionTier: appState.subscriptionTier)
                    .padding(.horizontal, styles.layout.paddingL)
                    .padding(.bottom, styles.layout.paddingXL)
            }
        }
        .background(styles.colors.background.ignoresSafeArea())
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
                        .font(styles.typography.body)
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
                            withAnimation {
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
                            withAnimation {
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
            Circle()
                .fill(hasEntry ? (entryMood?.color.opacity(0.3) ?? styles.colors.accent.opacity(0.3)) : Color.clear)
                .frame(width: 40, height: 40)
            
            if isToday {
                Circle()
                    .stroke(styles.colors.accent, lineWidth: 2)
                    .frame(width: 40, height: 40)
            }
            
            Text("\(day.day)")
                .font(styles.typography.body)
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
                case .anxious: moodValue = 2
                case .sad: moodValue = 1
                }
            } else {
                moodValue = 0 // No entry for this day
            }
            
            result.append(MoodDataPoint(date: date, value: moodValue))
        }
        
        return result
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
                                .foregroundStyle(styles.colors.accent)
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
                        .font(styles.typography.body)
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
                        .buttonStyle(PrimaryButtonStyle(
                            colors: styles.colors,
                            typography: styles.typography,
                            layout: styles.layout
                        ))
                        .frame(width: 150)
                    }
                    .padding(styles.layout.paddingL)
                    .background(styles.colors.surface.opacity(0.9))
                    .cornerRadius(styles.layout.radiusL)
                }
            }
        )
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
            
            Text(title)
                .font(styles.typography.caption)
                .foregroundColor(styles.colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(styles.typography.body)
                .foregroundColor(styles.colors.text)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.loadSampleData()
        
        return InsightsView()
            .environmentObject(appState)
    }
}
