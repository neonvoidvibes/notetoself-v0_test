import Foundation
import SwiftUI // Needed for MainActor dispatch

// Define Notification Name
extension Notification.Name {
    static let insightsDidUpdate = Notification.Name("insightsDidUpdate")
}

// Global function to trigger insight generation
// Should be called from a background task after a JournalEntry is saved.
func triggerAllInsightGenerations(llmService: LLMService, databaseService: DatabaseService, subscriptionTier: SubscriptionTier) async {
    print("[InsightUtils] Triggering background insight generation...")

    // Check subscription status - only generate if premium
    guard subscriptionTier == .premium else {
        print("[InsightUtils] Skipping insight generation (Free tier).")
        return
    }

    // Create generators
    let summaryGenerator = WeeklySummaryGenerator(llmService: llmService, databaseService: databaseService)
    let moodTrendGenerator = MoodTrendGenerator(llmService: llmService, databaseService: databaseService)
    let recommendationGenerator = RecommendationGenerator(llmService: llmService, databaseService: databaseService)

    // Run generators concurrently in detached tasks
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
         await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil) }
    }

    print("[InsightUtils] Background insight generation tasks launched.")
    // Post an initial notification immediately to trigger loading state in UI if desired
    // await MainActor.run { NotificationCenter.default.post(name: .insightsDidUpdate, object: nil) }
}