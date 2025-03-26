import SwiftUI

struct CalendarDetailContent: View {
    let selectedMonth: Date
    let entries: [JournalEntry]
    @State private var viewMonth: Date
    private let styles = UIStyles.shared
    
    init(selectedMonth: Date, entries: [JournalEntry]) {
        self.selectedMonth = selectedMonth
        self.entries = entries
        self._viewMonth = State(initialValue: selectedMonth)
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingL) {
            // Month navigation
            HStack {
                Button(action: {
                    withAnimation {
                        viewMonth = Calendar.current.date(byAdding: .month, value: -1, to: viewMonth)!
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(styles.colors.accent)
                }
                
                Spacer()
                
                Text(monthYearString(from: viewMonth))
                    .font(styles.typography.title3)
                    .foregroundColor(styles.colors.text)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        viewMonth = Calendar.current.date(byAdding: .month, value: 1, to: viewMonth)!
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(styles.colors.accent)
                }
            }
            
            // Detailed calendar view
            DetailedCalendarView(month: viewMonth, entries: entries)
                .padding(.vertical, styles.layout.paddingL)
            
            // Monthly stats
            MonthlyStatsView(month: viewMonth, entries: entries)
                .padding(.vertical, styles.layout.paddingL)
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct DetailedCalendarView: View {
    let month: Date
    let entries: [JournalEntry]
    private let styles = UIStyles.shared
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
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
                        DetailedCalendarDayView(day: day, entries: entries)
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
        }
    }
    
    private func daysInMonth() -> [CalendarDay] {
        let calendar = Calendar.current
        
        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: month)
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

struct DetailedCalendarDayView: View {
    let day: CalendarDay
    let entries: [JournalEntry]
    @State private var showingEntry: Bool = false
    @State private var selectedEntry: JournalEntry? = nil
    private let styles = UIStyles.shared
    
    private var dayEntries: [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: day.date)
        }
    }
    
    private var hasEntry: Bool {
        return !dayEntries.isEmpty
    }
    
    private var entryMood: Mood? {
        return dayEntries.first?.mood
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    var body: some View {
        Button(action: {
            if hasEntry {
                selectedEntry = dayEntries.first
                showingEntry = true
            }
        }) {
            VStack(spacing: 4) {
                // Day number
                Text("\(day.day)")
                    .font(styles.typography.bodyFont)
                    .foregroundColor(hasEntry ? styles.colors.text : styles.colors.textSecondary)
                
                // Mood indicator
                if hasEntry {
                    Circle()
                        .fill(entryMood?.color ?? styles.colors.accent)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(width: 50, height: 50)
            .background(
                ZStack {
                    if hasEntry {
                        Circle()
                            .fill(entryMood?.color.opacity(0.2) ?? styles.colors.accent.opacity(0.2))
                    }
                    
                    if isToday {
                        Circle()
                            .stroke(styles.colors.accent, lineWidth: 1)
                    }
                }
            )
        }
        .sheet(isPresented: $showingEntry) {
            if let entry = selectedEntry {
                FullscreenEntryView(entry: entry)
            }
        }
    }
}

