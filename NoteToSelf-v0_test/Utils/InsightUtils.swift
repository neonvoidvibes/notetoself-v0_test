import Foundation
import SwiftUI // Needed for AppState, MainActor dispatch

// Define Notification Name
extension Notification.Name {
    static let insightsDidUpdate = Notification.Name("insightsDidUpdate")
}

// Global function to trigger insight generation
// Should be called from a background task after a JournalEntry is saved.
// Needs AppState to pass to generators that require it (Streak, Reflection, Forecast)
func triggerAllInsightGenerations(
    llmService: LLMService,
    databaseService: DatabaseService,
    appState: AppState,
    forceGeneration: Bool = false // Add force parameter
) async {
    // Use forceGeneration flag in log message
    print("➡️ [InsightUtils] triggerAllInsightGenerations called. Forced: \(forceGeneration)")

    // Check subscription status - only bypass if forced
    if !forceGeneration {
        // Await here as appState is MainActor isolated
        // CORRECTED: Check against .pro
        guard await appState.subscriptionTier == .pro else {
            print("[InsightUtils] Skipping insight generation (Free tier and not forced).")
            return
        }
    } else {
        print("[InsightUtils] Bypassing subscription check due to forceGeneration flag.")
    }


    // --- Instantiate Generators ---
    // NEW Top Cards
    let dailyReflectionGenerator = DailyReflectionGenerator(llmService: llmService, databaseService: databaseService, appState: appState)
    let weekInReviewGenerator = WeekInReviewGenerator(llmService: llmService, databaseService: databaseService)
    // Grouped Cards
    let feelGenerator = FeelInsightGenerator(llmService: llmService, databaseService: databaseService)
    let thinkGenerator = ThinkInsightGenerator(llmService: llmService, databaseService: databaseService)
    let actGenerator = ActInsightGenerator(llmService: llmService, databaseService: databaseService)
    let learnGenerator = LearnInsightGenerator(llmService: llmService, databaseService: databaseService)
    // Remaining Old Cards
    // REMOVED: summaryGenerator
    let journeyNarrativeGenerator = JourneyNarrativeGenerator(llmService: llmService, databaseService: databaseService, appState: appState)


    // Run generators concurrently in detached tasks
    print("[InsightUtils] Launching generation tasks (Forced: \(forceGeneration))...")

    let force = forceGeneration // Capture the flag locally for the tasks

    // --- Launch Tasks ---

    // NEW: Daily Reflection (High Frequency)
    print("[InsightUtils] Launching DailyReflectionGenerator...")
    Task.detached(priority: .userInitiated) { // Higher priority as it's daily
        await dailyReflectionGenerator.generateAndStoreIfNeeded()
        await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Daily Reflection generation task finished.") }
    }

    // NEW: Week in Review (Low Frequency - logic inside generator handles threshold)
    print("[InsightUtils] Launching WeekInReviewGenerator...")
    Task.detached(priority: .background) {
        await weekInReviewGenerator.generateAndStoreIfNeeded()
        await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Week in Review generation task finished.") }
    }

    // Feel, Think, Act, Learn (Moderate Frequency - logic inside generators handles thresholds)
    print("[InsightUtils] Launching FeelInsightGenerator...")
     Task.detached(priority: .background) {
         await feelGenerator.generateAndStoreIfNeeded()
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Feel Insights generation task finished.") }
     }
     print("[InsightUtils] Launching ThinkInsightGenerator...")
     Task.detached(priority: .background) {
         await thinkGenerator.generateAndStoreIfNeeded()
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Think Insights generation task finished.") }
     }
     print("[InsightUtils] Launching ActInsightGenerator...")
     Task.detached(priority: .background) {
         await actGenerator.generateAndStoreIfNeeded()
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Act Insights generation task finished.") }
     }
     print("[InsightUtils] Launching LearnInsightGenerator...")
     Task.detached(priority: .background) {
         await learnGenerator.generateAndStoreIfNeeded()
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Learn Insights generation task finished.") }
     }

     // Keep Journey Narrative
    print("[InsightUtils] Launching JourneyNarrativeGenerator...")
    Task.detached(priority: .background) {
         await journeyNarrativeGenerator.generateAndStoreIfNeeded(forceGeneration: force)
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Journey Narrative generation task finished.") }
    }

    // REMOVED: Old WeeklySummaryGenerator launch


    print("✅ [InsightUtils] All background insight generation tasks launched.")
}

// Helper function to get journal entries based on the "past 7 calendar days OR last 7 entries, whichever comes first" rule.
// Assumes input entries are sorted descending by date.
func getEntriesForRollingWindow(allEntriesSortedDesc: [JournalEntry]) -> [JournalEntry] {
    let calendar = Calendar.current
    let now = Date()
    guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) else {
        print("⚠️ [getEntriesForRollingWindow] Could not calculate seven days ago.")
        return Array(allEntriesSortedDesc.prefix(7)) // Fallback to last 7 entries
    }

    // Filter by date (entries on or after the start of the day 7 days ago)
    let entriesLast7Days = allEntriesSortedDesc.filter { $0.date >= sevenDaysAgo }

    // Get last 7 entries by count
    let last7Entries = Array(allEntriesSortedDesc.prefix(7))

    // Find the cutoff dates for comparison
    let dateCutoff = entriesLast7Days.last?.date // Oldest date within the 7-day window
    let countCutoff = last7Entries.last?.date   // Date of the 7th most recent entry

    if dateCutoff == nil && countCutoff == nil {
        // No entries at all
        return []
    } else if dateCutoff == nil {
        // Only count limit applies (less than 7 entries total)
        // This case shouldn't happen if allEntriesSortedDesc is not empty and countCutoff is nil, but included for safety.
        return last7Entries
    } else if countCutoff == nil {
        // Only date limit applies (less than 7 entries in the last 7 days)
        return entriesLast7Days
    } else {
        // Both limits apply, determine which set represents the shorter, more recent period.
        // Return the list whose oldest entry is NEWER.
        if dateCutoff! >= countCutoff! {
            // The 7-day window's oldest entry is newer than or the same as the 7th entry.
            // This means the 7-day window contains <= 7 entries. Use the 7-day window.
            // print("[getEntriesForRollingWindow] Using 7-day window (\(entriesLast7Days.count) entries). Date cutoff: \(dateCutoff!), Count cutoff: \(countCutoff!)")
            return entriesLast7Days
        } else {
            // The 7th entry is newer than the oldest entry in the 7-day window.
            // This means the last 7 entries cover a shorter period. Use the last 7 entries.
            // print("[getEntriesForRollingWindow] Using last 7 entries. Date cutoff: \(dateCutoff!), Count cutoff: \(countCutoff!)")
            return last7Entries
        }
    }
}