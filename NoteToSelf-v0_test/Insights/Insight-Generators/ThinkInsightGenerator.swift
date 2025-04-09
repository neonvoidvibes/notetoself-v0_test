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

    func generateAndStoreIfNeeded(forceGeneration: Bool = false) async {
        print("➡️ [ThinkInsightGenerator] Starting generateAndStoreIfNeeded...")

        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        // 1. Check conditions only if not forcing generation
        if !forceGeneration {
            do {
                if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                    lastGenerationDate = latest.generatedDate
                    let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                    if daysSinceLast < regenerationThresholdDays {
                        print("[ThinkInsightGenerator] Skipping generation (Normal): Last insight generated \(daysSinceLast) days ago.")
                        shouldGenerate = false
                    } else {
                         print("[ThinkInsightGenerator] Last insight old enough (Normal). Checking for new entries...")
                    }
                } else {
                    print("[ThinkInsightGenerator] No previous insight found (Normal).")
                }
            } catch {
                print("‼️ [ThinkInsightGenerator] Error loading latest insight (Normal): \(error). Proceeding.")
            }
            // Only return if the time threshold check explicitly failed
            guard shouldGenerate else { return }
        } else {
             print("[ThinkInsightGenerator] Bypassing time checks due to forceGeneration.")
        }


        // 2. Fetch necessary data (use rolling window)
        let entries: [JournalEntry]
        do {
            let allEntriesSorted = try databaseService.loadAllJournalEntries()
            entries = getEntriesForRollingWindow(allEntriesSortedDesc: allEntriesSorted)
            print("✅ [ThinkInsightGenerator] Data Fetch: Using \(entries.count) entries from rolling window.")
        } catch {
            print("‼️ [ThinkInsightGenerator] Error fetching journal entries: \(error)")
            return
        }

        // 3. Check Minimum Entry Count (always required)
        guard entries.count >= 3 else {
            print("⚠️ [ThinkInsightGenerator] Skipping generation: Insufficient entries (\(entries.count)) in rolling window for context.")
            return
        }

        // 4. Check for New Entries only if not forcing and time threshold passed
        if !forceGeneration && shouldGenerate {
            if let lastGenDate = lastGenerationDate {
                let hasNewEntries = entries.contains { $0.date > lastGenDate }
                if !hasNewEntries {
                    print("⚠️ [ThinkInsightGenerator] New Entry Check Failed (Normal): Skipping LLM generation as no entries are newer than last insight.")
                    try? await databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                    return
                } else {
                     print("✅ [ThinkInsightGenerator] New Entry Check Passed (Normal): Found newer entries.")
                }
            } else {
                 print("✅ [ThinkInsightGenerator] New Entry Check: First generation run (Normal).")
            }
        } else if forceGeneration {
             print("[ThinkInsightGenerator] Bypassing new entry check due to forceGeneration.")
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