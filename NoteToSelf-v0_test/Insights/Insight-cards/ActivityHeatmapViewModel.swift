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
    private let databaseService: DatabaseService // Add DatabaseService dependency
    private var cancellables = Set<AnyCancellable>()

    @Published var heatmapData: [HeatmapDayInfo] = []
    @Published var isExpanded: Bool = false

    // Narrative State
    @Published var narrativeResult: StreakNarrativeResult? = nil
    @Published var narrativeGeneratedDate: Date? = nil
    @Published var isLoadingNarrative: Bool = false
    @Published var loadNarrativeError: Bool = false
    private let narrativeInsightTypeIdentifier = "journeyNarrative"

    let totalDaysToShow = 35 // 5 rows * 7 days
    let collapsedDaysToShow = 7 // 1 row * 7 days

    // Expose current streak from AppState
    var currentStreak: Int {
        appState.currentStreak
    }

    // Expose the relevant slice of data based on expansion state
    var visibleHeatmapData: [HeatmapDayInfo] {
        if isExpanded {
            return heatmapData
        } else {
            // Return the last `collapsedDaysToShow` days
            return Array(heatmapData.suffix(collapsedDaysToShow))
        }
    }

    // Update initializer to accept DatabaseService
    init(appState: AppState, databaseService: DatabaseService) {
        self.appState = appState
        self.databaseService = databaseService // Store DatabaseService
        print("[ActivityHeatmapViewModel] Initializing...")
        prepareHeatmapData() // Initial data prep
        loadNarrative() // << ADDED: Load initial narrative

        // Observe changes in AppState entries
        appState.$_journalEntries // Observe the underlying storage
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main) // Debounce updates
            .sink { [weak self] _ in
                print("[ActivityHeatmapViewModel] Journal entries changed, preparing heatmap data...")
                self?.prepareHeatmapData()
                self?.loadNarrative() // << ADDED: Reload narrative when entries change
            }
            .store(in: &cancellables)
    }

    private func prepareHeatmapData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let firstWeekday = calendar.firstWeekday // e.g., 1 for Sunday, 2 for Monday

        // Calculate the start date needed to show `totalDaysToShow` ending today
        // AND ensure the grid starts on the correct first day of the week visually.
        let todayWeekday = calendar.component(.weekday, from: today) // Weekday of today (1-7)
        // Calculate how many days ago the *start* of the week containing `startDateCandidate` was, according to the calendar's firstWeekday.
        // Adjust calculation to ensure the grid always ends with 'today' in the correct weekday slot
        let daysFromStartOfWeekToToday = (todayWeekday - firstWeekday + 7) % 7
        let totalDaysToDisplay = totalDaysToShow // Use the full 35 days for calculation base
        let weeksToDisplay = Int(ceil(Double(totalDaysToDisplay) / 7.0))
        let daysInLastVisualWeek = daysFromStartOfWeekToToday + 1 // Number of days shown in the last row up to 'today'
        let totalDaysNeededForGrid = (weeksToDisplay - 1) * 7 + daysInLastVisualWeek
        let daysToSubtractForGridStart = totalDaysNeededForGrid - 1 // Subtract one less day to get the start date

        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtractForGridStart, to: today) else {
             print("‼️ [ActivityHeatmapViewModel] Could not calculate start date for grid alignment.")
             self.heatmapData = []
             return
        }
        print("[ActivityHeatmapViewModel] Calculated grid start date: \(startDate), Today: \(today), FirstWeekday: \(firstWeekday)")


        // Create a dictionary of the *latest* entry for each day for quick lookup
        let entriesByDay = Dictionary(
            appState._journalEntries // Use underlying storage
                .map { (calendar.startOfDay(for: $0.date), $0) } // Tuple of (dayStartDate, entry)
                .sorted(by: { $0.1.date > $1.1.date }), // Sort entries by date descending (latest first)
            uniquingKeysWith: { (first, _) in first } // Keep the first entry encountered for each day (which is the latest)
        )

        var days: [HeatmapDayInfo] = []
        var currentDate = startDate
        // Generate exactly totalDaysToShow days for the heatmap data array
        for _ in 0..<totalDaysToShow {
            let entryForDay = entriesByDay[currentDate] // Look up the latest entry for this specific day
            days.append(HeatmapDayInfo(date: currentDate, entry: entryForDay))
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }


        // Final check and assignment - should always have totalDaysToShow now
        let finalData = days // Use the generated days directly
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

    // --- Narrative Loading ---
    private func loadNarrative() {
        guard !isLoadingNarrative else { return }
        isLoadingNarrative = true
        loadNarrativeError = false
        narrativeResult = nil // Clear previous result while loading
        print("[ActivityHeatmapViewModel] Loading narrative insight...")
        Task {
            var loadedDate: Date? = nil
            var decodeError: Error? = nil
            var finalResult: StreakNarrativeResult? = nil
            do {
                // Use the injected databaseService instance
                if let (json, date, _) = try databaseService.loadLatestInsight(type: narrativeInsightTypeIdentifier) {
                    loadedDate = date
                    if let data = json.data(using: .utf8) {
                        let decoder = JSONDecoder()
                        do { finalResult = try decoder.decode(StreakNarrativeResult.self, from: data) }
                        catch { decodeError = error }
                    } else { decodeError = NSError(domain: "ActivityHeatmapVM", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to Data"]) }
                } else {
                     print("[ActivityHeatmapViewModel] No stored narrative found.")
                }
            } catch {
                decodeError = error
                print("‼️ [ActivityHeatmapViewModel] Error loading narrative insight: \(error)")
            }
            // Update state on main thread
            await MainActor.run {
                self.narrativeResult = finalResult
                self.narrativeGeneratedDate = loadedDate
                self.loadNarrativeError = (decodeError != nil)
                self.isLoadingNarrative = false
                 print("[ActivityHeatmapViewModel] Narrative load complete. Error: \(loadNarrativeError)")
            }
        }
    }

    // --- Computed Properties for Narrative Display ---
    var narrativeSnippetDisplay: String {
         if isLoadingNarrative { return "Loading..." }
         if loadNarrativeError { return "Narrative unavailable" }
         guard let result = narrativeResult else {
             return "Your journey unfolds..." // Default when no result
         }
         let snippet = result.storySnippet.isEmpty ? "Your journey unfolds..." : result.storySnippet
         let maxLength = 100 // Keep snippet concise
         if snippet.count > maxLength {
             return String(snippet.prefix(maxLength)) + "..."
         } else {
             return snippet
         }
     }

    var narrativeDisplayText: String {
         if isLoadingNarrative { return "Loading narrative..." }
         if loadNarrativeError { return "Could not load narrative." }
         guard let result = narrativeResult, !result.narrativeText.isEmpty else {
             return currentStreak > 0 ? "Analyzing your recent journey..." : "Your journey's story will appear here."
         }
         return result.narrativeText
    }

    // REMOVED duplicate declaration - it exists earlier in the file.
    // var narrativeSnippetDisplay: String { ... }
}