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
    let streakNarrativeGenerator = StreakNarrativeGenerator(llmService: llmService, databaseService: databaseService, appState: appState)
    let aiReflectionGenerator = AIReflectionGenerator(llmService: llmService, databaseService: databaseService, appState: appState)
    let forecastGenerator = ForecastGenerator(llmService: llmService, databaseService: databaseService, appState: appState)


    // Run generators concurrently in detached tasks
    // Pass the forceGeneration flag down to each generator
    print("[InsightUtils] Launching generation tasks (Forced: \(forceGeneration))...")

    // Create a TaskGroup to manage concurrent generation
    // Although detached tasks work, TaskGroup might offer better cancellation handling if needed later.
    // For now, stick to detached tasks for simplicity but ensure flag is passed.

    let force = forceGeneration // Capture the flag locally for the tasks

    print("[InsightUtils] Launching WeeklySummaryGenerator...")
    Task.detached(priority: .background) {
        // TODO: Add forceGeneration param to other generators later if needed
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

    // --- New Generators ---
    print("[InsightUtils] Launching StreakNarrativeGenerator...")
    Task.detached(priority: .background) {
         // Pass the captured force flag here
         await streakNarrativeGenerator.generateAndStoreIfNeeded(forceGeneration: force)
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("🏁 [InsightUtils] Streak Narrative generation task finished.") }
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