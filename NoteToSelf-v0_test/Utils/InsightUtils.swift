import Foundation
import SwiftUI // Needed for AppState, MainActor dispatch

// Define Notification Name
extension Notification.Name {
    static let insightsDidUpdate = Notification.Name("insightsDidUpdate")
}

// Global function to trigger insight generation
// Should be called from a background task after a JournalEntry is saved.
// Needs AppState to pass to generators that require it (Streak, Reflection, Forecast)
func triggerAllInsightGenerations(llmService: LLMService, databaseService: DatabaseService, appState: AppState) async {
    print("[InsightUtils] Triggering background insight generation...")

    // Check subscription status - only generate if premium
    // Read from AppState directly
    guard await appState.subscriptionTier == .premium else {
        print("[InsightUtils] Skipping insight generation (Free tier).")
        return
    }

    // Create generators, passing dependencies including AppState where needed
    let summaryGenerator = WeeklySummaryGenerator(llmService: llmService, databaseService: databaseService)
    let moodTrendGenerator = MoodTrendGenerator(llmService: llmService, databaseService: databaseService)
    let recommendationGenerator = RecommendationGenerator(llmService: llmService, databaseService: databaseService)
    let streakNarrativeGenerator = StreakNarrativeGenerator(llmService: llmService, databaseService: databaseService, appState: appState)
    let aiReflectionGenerator = AIReflectionGenerator(llmService: llmService, databaseService: databaseService, appState: appState)
    let forecastGenerator = ForecastGenerator(llmService: llmService, databaseService: databaseService, appState: appState)


    // Run generators concurrently in detached tasks
    // Use a TaskGroup for slightly better management if desired, but detached tasks are fine here.
    print("[InsightUtils] Launching generation tasks...")
    Task.detached(priority: .background) {
        await summaryGenerator.generateAndStoreIfNeeded()
        // Post notification on main thread after completion (best effort)
        await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil) }
    }
    Task.detached(priority: .background) {
        await moodTrendGenerator.generateAndStoreIfNeeded()
        await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil) }
    }
    Task.detached(priority: .background) {
         await recommendationGenerator.generateAndStoreIfNeeded()
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("[InsightUtils] Recs generation finished.") }
    }
    Task.detached(priority: .background) {
         await streakNarrativeGenerator.generateAndStoreIfNeeded()
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("[InsightUtils] Streak Narrative generation finished.") }
    }
    Task.detached(priority: .background) {
         await aiReflectionGenerator.generateAndStoreIfNeeded()
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("[InsightUtils] AI Reflection generation finished.") }
    }
     Task.detached(priority: .background) {
          await forecastGenerator.generateAndStoreIfNeeded()
          await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil); print("[InsightUtils] Forecast generation finished.") }
     }

    print("[InsightUtils] All background insight generation tasks launched.")
    // Posting notification is handled within each task upon completion now.
}