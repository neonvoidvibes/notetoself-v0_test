import Foundation

// Actor to ensure thread-safe generation and saving
actor WeeklySummaryGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let insightTypeIdentifier = "weeklySummary"
    private let regenerationThresholdDays: Int = 1 // Regenerate if last summary is older than 1 day AND new entries exist

    init(llmService: LLMService, databaseService: DatabaseService) {
        self.llmService = llmService
        self.databaseService = databaseService
    }

    func generateAndStoreIfNeeded() async {
        print("[WeeklySummaryGenerator] Checking if generation is needed...")

        // 1. Check if regeneration is necessary
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        do {
            // REMOVED await
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                if daysSinceLast < regenerationThresholdDays {
                    print("[WeeklySummaryGenerator] Skipping generation: Last summary generated \(daysSinceLast) days ago (Threshold: \(regenerationThresholdDays)).")
                    shouldGenerate = false
                } else {
                     print("[WeeklySummaryGenerator] Last summary is old enough (\(daysSinceLast) days). Checking for new entries...")
                }
            } else {
                print("[WeeklySummaryGenerator] No previous summary found. Will generate.")
            }
        } catch {
            print("‼️ [WeeklySummaryGenerator] Error loading latest insight: \(error). Proceeding with generation.")
        }

        guard shouldGenerate else { return }

        // 2. Fetch necessary data (last 7 days of entries)
        let entries: [JournalEntry]
        do {
             // REMOVED await
            entries = try databaseService.loadAllJournalEntries().filter { $0.date >= oneWeekAgo }
        } catch {
            print("‼️ [WeeklySummaryGenerator] Error fetching journal entries: \(error)")
            return
        }

        // Check if there are new entries since the last generation (if applicable)
        if let lastGenDate = lastGenerationDate {
             let hasNewEntries = entries.contains { $0.date > lastGenDate }
             if !hasNewEntries {
                  print("[WeeklySummaryGenerator] Skipping generation: No new entries since last summary on \(lastGenDate.formatted()).")
                  // Optional: Update the timestamp of the existing insight to prevent re-checking immediately
                  // try? databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                  return
             }
             print("[WeeklySummaryGenerator] New entries found since last generation. Proceeding.")
        }

        guard !entries.isEmpty else {
            print("[WeeklySummaryGenerator] Skipping generation: No entries in the last 7 days.")
            // Optionally save an "empty" insight state if needed
            return
        }

        print("[WeeklySummaryGenerator] Found \(entries.count) entries for summary generation.")

        // 3. Format prompt context
        let context = entries.map { entry in
             // Corrected date format
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(200))..." // Limit context length per entry
        }.joined(separator: "\n\n")

        // 4. Get system prompt
        let systemPrompt = SystemPrompts.weeklySummaryPrompt(entriesContext: context)

        // 5. Call LLMService for structured output (this is async)
        do {
            let result: WeeklySummaryResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the weekly summary based on the provided context.", // User message might be simple here
                responseModel: WeeklySummaryResult.self
            )

            print("[WeeklySummaryGenerator] Successfully generated summary: \(result.mainSummary.prefix(50))...")

            // 6. Encode result back to JSON string
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // Optional: for readability in DB
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [WeeklySummaryGenerator] Failed to encode result to JSON string.")
                return
            }

            // 7. Save to Database (synchronous call)
            // REMOVED await
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString,
                startDate: oneWeekAgo, // Store the period covered
                endDate: today
            )
            print("✅ [WeeklySummaryGenerator] Successfully saved generated insight to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [WeeklySummaryGenerator] LLM generation failed: \(error.localizedDescription)")
            // Handle specific errors if needed (e.g., decoding error might indicate prompt issues)
        } catch {
            print("‼️ [WeeklySummaryGenerator] An unexpected error occurred: \(error)")
        }
    }
}