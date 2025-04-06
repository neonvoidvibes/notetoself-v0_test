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


    // Create generators, passing dependencies including AppState where needed
    let summaryGenerator = WeeklySummaryGenerator(llmService: llmService, databaseService: databaseService)
    // let moodTrendGenerator = MoodTrendGenerator(llmService: llmService, databaseService: databaseService) // Keep original Mood Trend commented out if replaced by Feel
    let recommendationGenerator = RecommendationGenerator(llmService: llmService, databaseService: databaseService) // Keep original Recs commented out if replaced by Act
    let journeyNarrativeGenerator = JourneyNarrativeGenerator(llmService: llmService, databaseService: databaseService, appState: appState)
    let aiReflectionGenerator = AIReflectionGenerator(llmService: llmService, databaseService: databaseService, appState: appState)
    let forecastGenerator = ForecastGenerator(llmService: llmService, databaseService: databaseService, appState: appState) // Keep original Forecast commented out if replaced by Act

    // Instantiate NEW generators
    let feelGenerator = FeelInsightGenerator(llmService: llmService, databaseService: databaseService)
    let thinkGenerator = ThinkInsightGenerator(llmService: llmService, databaseService: databaseService)
    let actGenerator = ActInsightGenerator(llmService: llmService, databaseService: databaseService)
    let learnGenerator = LearnInsightGenerator(llmService: llmService, databaseService: databaseService)


    // Run generators concurrently in detached tasks
    // Pass the forceGeneration flag down to each generator
    print("[InsightUtils] Launching generation tasks (Forced: \(forceGeneration))...")

    let force = forceGeneration // Capture the flag locally for the tasks

    // Existing Tasks
    print("[InsightUtils] Launching WeeklySummaryGenerator...")
    Task.detached(priority: .background) {
        await summaryGenerator.generateAndStoreIfNeeded()
        await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] WeeklySummary generation task finished.") }
    }
    print("[InsightUtils] Launching JourneyNarrativeGenerator...")
    Task.detached(priority: .background) {
         await journeyNarrativeGenerator.generateAndStoreIfNeeded(forceGeneration: force)
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Journey Narrative generation task finished.") }
    }
    print("[InsightUtils] Launching AIReflectionGenerator...")
    Task.detached(priority: .background) {
         await aiReflectionGenerator.generateAndStoreIfNeeded()
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] AI Reflection generation task finished.") }
    }
    /* // Keep old generators commented out if they are fully replaced
    print("[InsightUtils] Launching MoodTrendGenerator...")
    Task.detached(priority: .background) {
        await moodTrendGenerator.generateAndStoreIfNeeded()
        await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Mood Trend generation task finished.") }
    }
    print("[InsightUtils] Launching RecommendationGenerator...")
    Task.detached(priority: .background) {
         await recommendationGenerator.generateAndStoreIfNeeded()
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Recommendations generation task finished.") }
    }
     print("[InsightUtils] Launching ForecastGenerator...")
     Task.detached(priority: .background) {
          await forecastGenerator.generateAndStoreIfNeeded()
          await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Forecast generation task finished.") }
     }
    */

     // --- NEW TASKS ---
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


    print("✅ [InsightUtils] All background insight generation tasks launched.")
}