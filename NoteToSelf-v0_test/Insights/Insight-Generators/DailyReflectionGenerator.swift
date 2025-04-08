import Foundation

actor DailyReflectionGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let appState: AppState // Need access to recent entries
    private let insightTypeIdentifier = "dailyReflection"
    private let regenerationThresholdHours: Int = 1 // Regenerate frequently if new entries exist

    init(llmService: LLMService, databaseService: DatabaseService, appState: AppState) {
        self.llmService = llmService
        self.databaseService = databaseService
        self.appState = appState
    }

    func generateAndStoreIfNeeded() async {
        print("➡️ [DailyReflectionGenerator] Starting generateAndStoreIfNeeded...")

        let calendar = Calendar.current
        let now = Date()
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        // 1. Check regeneration threshold (simplified - always check for new entries if threshold passed)
        do {
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let hoursSinceLast = calendar.dateComponents([.hour], from: latest.generatedDate, to: now).hour ?? regenerationThresholdHours + 1
                if hoursSinceLast < regenerationThresholdHours {
                    print("[DailyReflectionGenerator] Skipping generation: Last insight generated \(hoursSinceLast) hours ago (Threshold: \(regenerationThresholdHours)).")
                    shouldGenerate = false
                } else {
                     print("[DailyReflectionGenerator] Last insight is old enough. Checking for new entries...")
                }
            } else {
                print("[DailyReflectionGenerator] No previous insight found. Will check for recent entries.")
            }
        } catch {
            print("‼️ [DailyReflectionGenerator] Error loading latest insight: \(error). Proceeding.")
        }

        // Fetch necessary data (last 24h and last 7d)
        // Use appState for potentially faster access, assuming it's kept up-to-date
        let allEntries = await appState.journalEntries
        let entriesLast24h = allEntries.filter { $0.date >= now.addingTimeInterval(-24 * 60 * 60) }
                                     .sorted { $0.date > $1.date } // Newest first for context prep

        // Check if there are any entries in the last 24 hours *before* checking generation threshold
        guard !entriesLast24h.isEmpty else {
            print("⚠️ [DailyReflectionGenerator] Skipping generation: No entries found in the last 24 hours.")
            // Save an empty insight to signal the card to show the button state
            await saveEmptyInsight()
            return
        }

        // Now check the generation threshold *after* confirming there are recent entries
        guard shouldGenerate else { return }

        // Check if the most recent entry (within 24h) is newer than the last generation
        if let lastGenDate = lastGenerationDate, let mostRecentEntryDate = entriesLast24h.first?.date {
             if mostRecentEntryDate <= lastGenDate {
                  print("[DailyReflectionGenerator] Skipping generation: No new entries since last insight on \(lastGenDate.formatted()).")
                  // Update timestamp of existing insight so we don't keep checking until threshold passes
                   try? databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                  return
             }
             print("[DailyReflectionGenerator] New entry found since last generation. Proceeding.")
        } else {
             print("[DailyReflectionGenerator] First generation run or new entries found. Proceeding.")
        }

        // Prepare context: last 24h for focus, last 7d for broader awareness
        let entriesLast7d = allEntries.filter { $0.date >= now.addingTimeInterval(-7 * 24 * 60 * 60) }
                                    .sorted { $0.date > $1.date } // Newest first

        print("[DailyReflectionGenerator] Using \(entriesLast24h.count) entries from last 24h for focus, \(entriesLast7d.count) from last 7d for context.")

        // Format prompt context
        let latestContext = entriesLast24h.map { entry in
             // Use .abbreviated for date and .shortened for time
            "Date: \(entry.date.formatted(date: .abbreviated, time: .shortened)), Mood: \(entry.mood.name)\n\(entry.text)"
        }.joined(separator: "\n---\n")

        let weeklyContext = entriesLast7d.map { entry in
             // Use .abbreviated for date, omit time for brevity
            "Date: \(entry.date.formatted(date: .abbreviated, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(150))..."
        }.joined(separator: "\n---\n")


        // Get system prompt
        let systemPrompt = SystemPrompts.dailyReflectionPrompt(
            latestEntryContext: latestContext,
            weeklyContext: weeklyContext
        )

        // Call LLMService
        do {
            let result: DailyReflectionResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the daily reflection snapshot and prompts based on the latest entry context, using the weekly context for awareness.",
                responseModel: DailyReflectionResult.self
            )

            print("✅ [DailyReflectionGenerator] LLM Success.")

            // Encode result
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // Optional: for readability in DB
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [DailyReflectionGenerator] Failed to encode result to JSON string.")
                return
            }

            // Save to Database
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [DailyReflectionGenerator] Insight saved to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [DailyReflectionGenerator] LLM generation failed: \(error.localizedDescription)")
            // Consider saving an error state or empty state if LLM fails?
            await saveEmptyInsight() // Save empty on failure
        } catch {
            print("‼️ [DailyReflectionGenerator] An unexpected error occurred: \(error)")
            await saveEmptyInsight() // Save empty on failure
        }
        print("🏁 [DailyReflectionGenerator] Finished generateAndStoreIfNeeded.")
    }

    // Helper to save an empty insight result
    private func saveEmptyInsight() async {
         print("[DailyReflectionGenerator] Saving empty insight...")
         let emptyResult = DailyReflectionResult.empty()
         let encoder = JSONEncoder()
         do {
             let jsonData = try encoder.encode(emptyResult)
             if let jsonString = String(data: jsonData, encoding: .utf8) {
                 try databaseService.saveGeneratedInsight(
                     type: insightTypeIdentifier,
                     date: Date(), // Use current date even for empty
                     jsonData: jsonString
                 )
                 print("✅ [DailyReflectionGenerator] Saved empty insight to database.")
             } else {
                  print("‼️ [DailyReflectionGenerator] Failed to create JSON string for empty insight.")
             }
         } catch {
              print("‼️ [DailyReflectionGenerator] Failed to encode or save empty insight: \(error)")
         }
     }
}