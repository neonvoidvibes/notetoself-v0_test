import SwiftUI
import Combine

// Re-define HeatmapDayInfo here or ensure it's globally accessible (e.g., in Models.swift)
// For now, defining locally for encapsulation.
struct HeatmapDayInfo: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let entry: JournalEntry? // Store the latest entry for the day
    var mood: Mood? { entry?.mood } // Get mood from entry

    // Equatable conformance based on date and entry presence/mood
    static func == (lhs: HeatmapDayInfo, rhs: HeatmapDayInfo) -> Bool {
        return lhs.date == rhs.date && lhs.entry?.id == rhs.entry?.id && lhs.mood == rhs.mood
    }
}

@MainActor
class ActivityHeatmapViewModel: ObservableObject {
    @ObservedObject private var appState: AppState
    private var cancellables = Set<AnyCancellable>()

    @Published var heatmapData: [HeatmapDayInfo] = []
    @Published var isExpanded: Bool = false

    let totalDaysToShow = 35 // 5 rows * 7 days
    let collapsedDaysToShow = 7 // 1 row * 7 days

    // Expose the relevant slice of data based on expansion state
    var visibleHeatmapData: [HeatmapDayInfo] {
        if isExpanded {
            return heatmapData
        } else {
            // Return the last `collapsedDaysToShow` days
            return Array(heatmapData.suffix(collapsedDaysToShow))
        }
    }

    init(appState: AppState) {
        self.appState = appState
        print("[ActivityHeatmapViewModel] Initializing...")
        prepareHeatmapData() // Initial data prep

        // Observe changes in AppState entries
        appState.$_journalEntries // Observe the underlying storage
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main) // Debounce updates
            .sink { [weak self] _ in
                print("[ActivityHeatmapViewModel] Journal entries changed, preparing heatmap data...")
                self?.prepareHeatmapData()
            }
            .store(in: &cancellables)
    }

    private func prepareHeatmapData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Calculate the start date needed to show `totalDaysToShow` ending today
        guard let startDate = calendar.date(byAdding: .day, value: -(totalDaysToShow - 1), to: today) else {
            print("‼️ [ActivityHeatmapViewModel] Could not calculate start date.")
            self.heatmapData = []
            return
        }

        // Create a dictionary of the *latest* entry for each day for quick lookup
        let entriesByDay = Dictionary(
            appState._journalEntries // Use underlying storage
                .map { (calendar.startOfDay(for: $0.date), $0) } // Tuple of (dayStartDate, entry)
                .sorted(by: { $0.1.date > $1.1.date }), // Sort entries by date descending (latest first)
            uniquingKeysWith: { (first, _) in first } // Keep the first entry encountered for each day (which is the latest)
        )

        var days: [HeatmapDayInfo] = []
        var currentDate = startDate
        while currentDate <= today {
            let entryForDay = entriesByDay[currentDate] // Look up the latest entry for this specific day
            days.append(HeatmapDayInfo(date: currentDate, entry: entryForDay))
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }

        // Ensure we always have exactly `totalDaysToShow` days, padding with empty future dates if needed (unlikely here)
        let paddingNeeded = totalDaysToShow - days.count
        if paddingNeeded > 0 {
            print("⚠️ [ActivityHeatmapViewModel] Padding heatmap data with \(paddingNeeded) future days.")
            for i in 1...paddingNeeded {
                 if let futureDate = calendar.date(byAdding: .day, value: i, to: today) {
                     days.append(HeatmapDayInfo(date: futureDate, entry: nil))
                 }
            }
        }

        // Final check and assignment
        let finalData = Array(days.suffix(totalDaysToShow))
         // Only update if the data has actually changed to prevent unnecessary UI redraws
         if finalData != self.heatmapData {
             self.heatmapData = finalData
             print("[ActivityHeatmapViewModel] Heatmap data prepared/updated. Total days: \(finalData.count)")
         } else {
              print("[ActivityHeatmapViewModel] Heatmap data is unchanged.")
         }

    }

    func toggleExpansion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isExpanded.toggle()
        }
        print("[ActivityHeatmapViewModel] Expansion toggled. isExpanded = \(isExpanded)")
    }
}