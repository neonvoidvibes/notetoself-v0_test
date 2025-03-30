import Foundation

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
    // Note: Dependencies are passed in, not accessed globally within generators
    let summaryGenerator = WeeklySummaryGenerator(llmService: llmService, databaseService: databaseService)
    let moodTrendGenerator = MoodTrendGenerator(llmService: llmService, databaseService: databaseService)
    let recommendationGenerator = RecommendationGenerator(llmService: llmService, databaseService: databaseService)

    // Run generators concurrently in detached tasks so they don't block the caller
    // and run independently in the background.
    Task.detached(priority: .background) {
        await summaryGenerator.generateAndStoreIfNeeded()
    }
    Task.detached(priority: .background) {
        await moodTrendGenerator.generateAndStoreIfNeeded()
    }
    Task.detached(priority: .background) {
         await recommendationGenerator.generateAndStoreIfNeeded()
    }

    print("[InsightUtils] Background insight generation tasks launched.")
    // Optionally: Post a notification for UI refresh if needed, although InsightsView reloads on appear.
    // await MainActor.run { NotificationCenter.default.post(name: .insightsUpdated, object: nil) }
}

// Example Notification name (define elsewhere if used)
// extension Notification.Name {
//     static let insightsUpdated = Notification.Name("insightsUpdated")
// }