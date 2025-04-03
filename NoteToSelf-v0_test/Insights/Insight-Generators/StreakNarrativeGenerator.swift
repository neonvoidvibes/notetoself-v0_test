import Foundation

// Actor to ensure thread-safe generation and saving
actor StreakNarrativeGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let appState: AppState // Need access to current streak count
    private let insightTypeIdentifier = "streakNarrative" // Use new type identifier
    private let regenerationThresholdDays: Int = 1 // Regenerate daily if new entries

    init(llmService: LLMService, databaseService: DatabaseService, appState: AppState) {
        self.llmService = llmService
        self.databaseService = databaseService
        self.appState = appState
    }

    func generateAndStoreIfNeeded() async {
        print("➡️ [StreakNarrativeGenerator] Starting generateAndStoreIfNeeded...")

        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        do {
             // Remove await - loadLatestInsight is currently sync
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                if daysSinceLast < regenerationThresholdDays {
                    print("[StreakNarrativeGenerator] Skipping generation: Last narrative generated \(daysSinceLast) days ago.")
                    shouldGenerate = false
                } else {
                    print("[StreakNarrativeGenerator] Last narrative is old enough. Checking for new entries...")
                }
            } else {
                print("[StreakNarrativeGenerator] No previous narrative found. Will generate.")
            }
        } catch {
            print("‼️ [StreakNarrativeGenerator] Error loading latest insight: \(error). Proceeding.")
        }

        print("[StreakNarrativeGenerator] Should Generate based on date threshold? \(shouldGenerate)")
        guard shouldGenerate else { return }

        // Fetch necessary data (e.g., last 5-7 entries for context)
        let entries: [JournalEntry]
        // Add await here for safety when accessing MainActor property from background actor
        entries = await Array(appState.journalEntries.prefix(7))


        // Check if there are new entries since the last generation (if applicable)
        if let lastGenDate = lastGenerationDate {
            let hasNewEntries = entries.contains { $0.date > lastGenDate }
            if !hasNewEntries && !entries.isEmpty { // Don't skip if entries list itself is empty
                 print("[StreakNarrativeGenerator] Skipping generation: No new entries since last narrative.")
                 // try? databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date()) // Optional: Update timestamp
                 return
            }
             print("[StreakNarrativeGenerator] New entries found or first time generation. Proceeding.")
        } else if !entries.isEmpty {
             // This path means lastGenDate was nil (first run) or the check above passed
             print("[StreakNarrativeGenerator] First generation run or new entries found. Proceeding.")
        } else {
             // This means lastGenDate existed, and no new entries were found.
             // The check above already returned, but adding log here for completeness.
              print("[StreakNarrativeGenerator] Condition check completed (Should not reach here if skipping).")
        }


        // Need at least one entry usually to generate meaningful narrative
        guard !entries.isEmpty else {
            print("⚠️ [StreakNarrativeGenerator] Skipping generation: No entries found for narrative context.")
            // Optionally save an "empty" insight state if needed
            return
        }

        print("[StreakNarrativeGenerator] Using \(entries.count) recent entries for context.")
        // Add await here because appState is MainActor and this is a background actor
        let currentStreak = await appState.currentStreak

        // Format prompt context
        let context = entries.map { entry in
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(150))..."
        }.joined(separator: "\n\n")

        // Get system prompt
        let systemPrompt = SystemPrompts.streakNarrativePrompt(entriesContext: context, streakCount: currentStreak)

        print("[StreakNarrativeGenerator] Preparing to call LLM...")
        // Call LLMService
        do {
            let result: StreakNarrativeResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the streak narrative based on the context.",
                responseModel: StreakNarrativeResult.self
            )

            print("✅ [StreakNarrativeGenerator] LLM Success. Snippet: \(result.storySnippet)")

            // Encode result
            let encoder = JSONEncoder()
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [StreakNarrativeGenerator] Failed to encode result to JSON string.")
                return
            }

            // Save to Database
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [StreakNarrativeGenerator] Insight saved to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [StreakNarrativeGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch let error as DatabaseError {
             print("‼️ [StreakNarrativeGenerator] Database save failed: \(error)")
        } catch {
            print("‼️ [StreakNarrativeGenerator] An unexpected error occurred: \(error)")
        }
    }
}