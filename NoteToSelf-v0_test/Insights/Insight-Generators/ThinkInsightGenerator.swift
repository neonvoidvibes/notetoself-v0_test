import Foundation

actor ThinkInsightGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let insightTypeIdentifier = "thinkInsights"
    private let regenerationThresholdDays: Int = 3 // Regenerate less frequently

    init(llmService: LLMService, databaseService: DatabaseService) {
        self.llmService = llmService
        self.databaseService = databaseService
    }

    func generateAndStoreIfNeeded() async {
        print("➡️ [ThinkInsightGenerator] Starting generateAndStoreIfNeeded...")

        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        // 1. Check regeneration threshold
        do {
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                if daysSinceLast < regenerationThresholdDays {
                    print("[ThinkInsightGenerator] Skipping generation: Last insight generated \(daysSinceLast) days ago.")
                    shouldGenerate = false
                } else {
                     print("[ThinkInsightGenerator] Last insight is old enough. Checking for new entries...")
                }
            } else {
                print("[ThinkInsightGenerator] No previous insight found. Will generate.")
            }
        } catch {
            print("‼️ [ThinkInsightGenerator] Error loading latest insight: \(error). Proceeding.")
        }

        guard shouldGenerate else { return }

        // 2. Fetch necessary data (e.g., last 14-21 days of entries)
        let entries: [JournalEntry]
        // Fetch ALL entries sorted descending, then apply the rolling window logic
        let relevantEntries: [JournalEntry]
        do {
            let allEntriesSorted = try databaseService.loadAllJournalEntries() // Assumes DB returns sorted desc
            relevantEntries = getEntriesForRollingWindow(allEntriesSortedDesc: allEntriesSorted)
            print("✅ [ThinkInsightGenerator] Data Fetch: Using \(relevantEntries.count) entries from rolling window.")
            // Keep original 'entries' variable name for minimal downstream changes
            entries = relevantEntries
        } catch {
            print("‼️ [ThinkInsightGenerator] Error fetching journal entries: \(error)")
            return
        }

        // Check if there are new entries since the last generation (if applicable)
         if let lastGenDate = lastGenerationDate {
              let hasNewEntries = entries.contains { $0.date > lastGenDate }
              if !hasNewEntries && !entries.isEmpty {
                   print("[ThinkInsightGenerator] Skipping generation: No new entries since last insight.")
                    try? databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                   return
              }
        }

        guard entries.count >= 3 else { // Adjusted minimum to 3 for Think
            print("⚠️ [ThinkInsightGenerator] Skipping generation: Insufficient entries (\(entries.count)) in rolling window for context.")
            return
        }

        print("[ThinkInsightGenerator] Using \(entries.count) entries for context.")

        // 3. Format prompt context
        let context = entries.map { entry in
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(200))..."
        }.joined(separator: "\n\n")

        // 4. Get system prompt
        let systemPrompt = SystemPrompts.thinkInsightPrompt(entriesContext: context)

        // 5. Call LLMService
        do {
            let result: ThinkInsightResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the Think insight (Theme Overview and Value Reflection) based on the context.",
                responseModel: ThinkInsightResult.self
            )

            print("✅ [ThinkInsightGenerator] LLM Success.")

            // 6. Encode result
            let encoder = JSONEncoder()
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [ThinkInsightGenerator] Failed to encode result to JSON string.")
                return
            }

            // 7. Save to Database
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [ThinkInsightGenerator] Insight saved to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [ThinkInsightGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch {
            print("‼️ [ThinkInsightGenerator] An unexpected error occurred: \(error)")
        }
         print("🏁 [ThinkInsightGenerator] Finished generateAndStoreIfNeeded.")
    }
}