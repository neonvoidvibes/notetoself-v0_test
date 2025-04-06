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
    let moodTrendGenerator = MoodTrendGenerator(llmService: llmService, databaseService: databaseService)
    let recommendationGenerator = RecommendationGenerator(llmService: llmService, databaseService: databaseService)
    // UPDATED: Instantiate JourneyNarrativeGenerator
    let journeyNarrativeGenerator = JourneyNarrativeGenerator(llmService: llmService, databaseService: databaseService, appState: appState)
    let aiReflectionGenerator = AIReflectionGenerator(llmService: llmService, databaseService: databaseService, appState: appState)
    let forecastGenerator = ForecastGenerator(llmService: llmService, databaseService: databaseService, appState: appState)


    // Run generators concurrently in detached tasks
    // Pass the forceGeneration flag down to each generator
    print("[InsightUtils] Launching generation tasks (Forced: \(forceGeneration))...")

    let force = forceGeneration // Capture the flag locally for the tasks

    print("[InsightUtils] Launching WeeklySummaryGenerator...")
    Task.detached(priority: .background) {
        await summaryGenerator.generateAndStoreIfNeeded()
        await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] WeeklySummary generation task finished.") }
    }
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

    // --- Updated Generator ---
    print("[InsightUtils] Launching JourneyNarrativeGenerator...")
    Task.detached(priority: .background) {
         // Pass the captured force flag here
         await journeyNarrativeGenerator.generateAndStoreIfNeeded(forceGeneration: force)
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Journey Narrative generation task finished.") }
    }
    print("[InsightUtils] Launching AIReflectionGenerator...")
    Task.detached(priority: .background) {
         await aiReflectionGenerator.generateAndStoreIfNeeded()
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] AI Reflection generation task finished.") }
    }
    print("[InsightUtils] Launching ForecastGenerator...")
     Task.detached(priority: .background) {
          await forecastGenerator.generateAndStoreIfNeeded()
          await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Forecast generation task finished.") }
     }

    print("✅ [InsightUtils] All background insight generation tasks launched.")
}