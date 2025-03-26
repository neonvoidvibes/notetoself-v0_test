import SwiftUI

struct CalendarInsightCard: View {
    @Binding var selectedMonth: Date
    let entries: [JournalEntry]
    @State private var isExpanded: Bool = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols
    
    var body: some View {
        Button(action: {
            isExpanded = true
        }) {
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
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isExpanded) {
            InsightDetailView(
                insight: InsightDetail(
                    type: .calendar,
                    title: "Calendar Details",
                    data: selectedMonth
                ),
                entries: entries
            )
        }
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

