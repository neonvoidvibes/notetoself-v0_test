import SwiftUI
import Combine

// Represents the state of a single day's dot
struct StreakDay: Identifiable {
    let id = UUID()
    let date: Date
    let weekdayIndex: Int // 1 = Sun, ..., 7 = Sat
    let isFilled: Bool
    let isToday: Bool
    let isWithin24Hours: Bool
}

@MainActor
class StreakViewModel: ObservableObject {
    @ObservedObject private var appState: AppState
    private var cancellables = Set<AnyCancellable>()

    @Published var streakDays: [StreakDay] = []
    @Published var currentStreak: Int = 0
    @Published var firstDayOfWeek: Int = Calendar.current.firstWeekday // 1=Sun, 2=Mon
    @Published var activeStreakRangeIndices: Range<Int>? = nil // Indices for accent bar

    init(appState: AppState) {
        self.appState = appState
        self.firstDayOfWeek = Calendar.current.firstWeekday

        // Initial calculation
        recalculateStreakData()

        // Observe AppState changes
        appState.objectWillChange
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main) // Debounce slightly
            .sink { [weak self] _ in
                self?.recalculateStreakData()
            }
            .store(in: &cancellables)

        // Observe changes to calendar settings (like firstWeekday)
        NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .sink { [weak self] _ in
                 print("[StreakViewModel] Locale changed, recalculating first day of week.")
                 self?.firstDayOfWeek = Calendar.current.firstWeekday
                 self?.recalculateStreakData() // Recalculate data when firstWeekday changes
            }
            .store(in: &cancellables)
    }

    private func recalculateStreakData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let simulated = appState.overrideStreakStartDate

        // Determine the effective "today" for simulation if needed
        let effectiveToday: Date
        if simulated {
            let todayWeekday = calendar.component(.weekday, from: today) // 1..7
            let simWeekday = appState.simulatedStreakStartWeekday // 1..7
            let daysAgo = (todayWeekday - simWeekday + 7) % 7
            effectiveToday = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
             print("[StreakViewModel] Simulating streak start: Today=\(todayWeekday), Sim=\(simWeekday), DaysAgo=\(daysAgo), EffectiveToday=\(effectiveToday)")
        } else {
            effectiveToday = today
        }

        // Calculate current streak based on effectiveToday and real entries
        self.currentStreak = calculateStreak(entries: appState._journalEntries, calendar: calendar, effectiveToday: effectiveToday)

        // Calculate the 7 days to display
        let weekDates = calculateWeekDates(calendar: calendar, effectiveToday: effectiveToday, firstDayOfWeek: self.firstDayOfWeek)
        let entryDatesSet = Set(appState._journalEntries.map { calendar.startOfDay(for: $0.date) })
        let now = Date()

        self.streakDays = weekDates.map { date in
            let weekdayIndex = calendar.component(.weekday, from: date)
            let isFilled = simulated ? date <= effectiveToday : entryDatesSet.contains(date)
            let isToday = calendar.isDate(date, inSameDayAs: today) // Use real today for highlight

            // Check if the *entry* for this day (if filled) is within 24h
            var isWithin24Hours = false
            if isFilled && !simulated {
                 if let entryForDay = appState._journalEntries.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                     isWithin24Hours = abs(entryForDay.date.timeIntervalSince(now)) < (24 * 60 * 60)
                 }
            } else if isFilled && simulated && date == effectiveToday {
                // If simulating, only the 'effectiveToday' dot gets the potential glow
                isWithin24Hours = true // Simulate glow on the simulated 'today'
            }

            return StreakDay(
                date: date,
                weekdayIndex: weekdayIndex,
                isFilled: isFilled,
                isToday: isToday,
                isWithin24Hours: isWithin24Hours
            )
        }

        // Calculate active streak range indices
        print("[StreakViewModel Debug] Days data for range calc: \(self.streakDays.map { $0.isFilled })")
        self.activeStreakRangeIndices = calculateActiveStreakRange(streakDays: self.streakDays)
        print("[StreakViewModel Debug] Calculated Range: \(String(describing: self.activeStreakRangeIndices))")


        // print("[StreakViewModel] Recalculated: \(self.streakDays.count) days, Streak: \(self.currentStreak), Range: \(self.activeStreakRangeIndices)")
    }

    // Function to calculate the range of the current continuous streak within the displayed 7 days
    private func calculateActiveStreakRange(streakDays: [StreakDay]) -> Range<Int>? {
        guard let lastFilledIndex = streakDays.lastIndex(where: { $0.isFilled }) else {
            return nil // No filled days
        }

        var startIndex = lastFilledIndex
        while startIndex > 0 && streakDays[startIndex - 1].isFilled {
            startIndex -= 1
        }

        // Ensure the range has at least one element and ends at the last filled index
        guard startIndex <= lastFilledIndex else { return nil }

        // Return range covering the continuous filled segment ending at lastFilledIndex
        // Range is start...<end, so end index is lastFilledIndex + 1
        return startIndex..<(lastFilledIndex + 1)
    }

    private func calculateWeekDates(calendar: Calendar, effectiveToday: Date, firstDayOfWeek: Int) -> [Date] {
        guard let currentWeekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: effectiveToday)) else {
            return []
        }

        // Adjust start date based on firstDayOfWeek setting
        let weekdayOfStart = calendar.component(.weekday, from: currentWeekStartDate) // 1..7
        let daysToAdd = (firstDayOfWeek - weekdayOfStart + 7) % 7
        guard let adjustedStartDate = calendar.date(byAdding: .day, value: daysToAdd, to: currentWeekStartDate) else {
            return []
        }

        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: adjustedStartDate) }
    }

    // Calculates streak based on actual entries, ending relative to 'effectiveToday'
    private func calculateStreak(entries: [JournalEntry], calendar: Calendar, effectiveToday: Date) -> Int {
         guard !entries.isEmpty else { return 0 }

         let sortedDates = entries.map { calendar.startOfDay(for: $0.date) }.sorted(by: >)
         guard let mostRecentEntryDay = sortedDates.first else { return 0 }

         // Check if the most recent entry is on or before the effective 'today'
         guard mostRecentEntryDay <= effectiveToday else {
              // If the most recent entry is *after* the simulated 'today', streak is 0 relative to simulation
              return 0
         }

         // Streak must end on effectiveToday or the day before effectiveToday
         let effectiveYesterday = calendar.date(byAdding: .day, value: -1, to: effectiveToday)!
         guard mostRecentEntryDay == effectiveToday || mostRecentEntryDay == effectiveYesterday else { return 0 }

         var streak = 0
         var checkDate = mostRecentEntryDay
         let entryDatesSet = Set(entries.map { calendar.startOfDay(for: $0.date) })

         while entryDatesSet.contains(checkDate) {
             streak += 1
             guard streak < 1000 else { break } // Safety break
             guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
             checkDate = previousDay
         }
         return streak
    }
}