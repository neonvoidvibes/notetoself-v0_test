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
        guard await appState.subscriptionTier == .premium else {
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
    let summaryGenerator = WeeklySummaryGenerator(llmService: llmService, databaseService: databaseService) // Keep original weekly?
    let journeyNarrativeGenerator = JourneyNarrativeGenerator(llmService: llmService, databaseService: databaseService, appState: appState)
    // REMOVED: aiReflectionGenerator, moodTrendGenerator, recommendationGenerator, forecastGenerator


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

    // Keep original Weekly Summary for now?
    print("[InsightUtils] Launching WeeklySummaryGenerator...")
    Task.detached(priority: .background) {
        await summaryGenerator.generateAndStoreIfNeeded()
        await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] WeeklySummary generation task finished.") }
    }


    print("✅ [InsightUtils] All background insight generation tasks launched.")
}