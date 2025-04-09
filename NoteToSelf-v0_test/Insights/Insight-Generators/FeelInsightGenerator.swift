import Foundation

actor FeelInsightGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let insightTypeIdentifier = "feelInsights"
    private let regenerationThresholdDays: Int = 1

    init(llmService: LLMService, databaseService: DatabaseService) {
        self.llmService = llmService
        self.databaseService = databaseService
    }

    func generateAndStoreIfNeeded(forceGeneration: Bool = false) async {
        print("➡️ [FeelInsightGenerator] Starting generateAndStoreIfNeeded...")

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
                        print("[FeelInsightGenerator] Skipping generation (Normal): Last insight generated \(daysSinceLast) days ago.")
                        shouldGenerate = false
                    } else {
                        print("[FeelInsightGenerator] Last insight old enough (Normal). Checking for new entries...")
                    }
                } else {
                    print("[FeelInsightGenerator] No previous insight found (Normal).")
                }
            } catch {
                print("‼️ [FeelInsightGenerator] Error loading latest insight (Normal): \(error). Proceeding.")
            }
            // Only return if the time threshold check explicitly failed
            guard shouldGenerate else {
                 print("🏁 [FeelInsightGenerator] Finished: Skipped due to recent generation (Normal).")
                 return
            }
        } else {
             print("[FeelInsightGenerator] Bypassing time checks due to forceGeneration.")
        }


        // 2. Fetch necessary data (use rolling window)
        let entries: [JournalEntry]
        do {
            let allEntriesSorted = try databaseService.loadAllJournalEntries()
            entries = getEntriesForRollingWindow(allEntriesSortedDesc: allEntriesSorted)
            print("✅ [FeelInsightGenerator] Data Fetch: Using \(entries.count) entries from rolling window.")
        } catch {
            print("‼️ [FeelInsightGenerator] Data Fetch Failed: Error fetching journal entries: \(error)")
            print("🏁 [FeelInsightGenerator] Finished: Aborted due to data fetch error.")
            return
        }

        // 3. Check Minimum Entry Count (always required)
        guard entries.count >= 2 else {
            print("⚠️ [FeelInsightGenerator] Minimum Entry Check Failed: Skipping generation. Need at least 2 entries in rolling window, found \(entries.count).")
            print("🏁 [FeelInsightGenerator] Finished: Skipped due to insufficient entries.")
            return
        }
        print("✅ [FeelInsightGenerator] Minimum Entry Check Passed: Have \(entries.count) entries.")

        // 4. Check for New Entries only if not forcing and time threshold passed
        if !forceGeneration && shouldGenerate {
            if let lastGenDate = lastGenerationDate {
                let hasNewEntries = entries.contains { $0.date > lastGenDate }
                if !hasNewEntries {
                    print("⚠️ [FeelInsightGenerator] New Entry Check Failed (Normal): Skipping LLM generation as no entries are newer than last insight.")
                    try? await databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                    print("🏁 [FeelInsightGenerator] Finished: Skipped LLM call due to no new entries (Normal).")
                    return
                } else {
                    print("✅ [FeelInsightGenerator] New Entry Check Passed (Normal): Found newer entries.")
                }
            } else {
                 print("✅ [FeelInsightGenerator] New Entry Check: First generation run (Normal).")
            }
        } else if forceGeneration {
             print("[FeelInsightGenerator] Bypassing new entry check due to forceGeneration.")
        }

        // 5. Format prompt context
        let context = entries.map { entry in
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(150))..."
        }.joined(separator: "\n\n")

        // 6. Get system prompt
        let systemPrompt = SystemPrompts.feelInsightPrompt(entriesContext: context)

        // 7. Call LLMService
        print("⏳ [FeelInsightGenerator] Calling LLMService...")
        do {
            let result: FeelInsightResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the Feel insight (Mood Trend, Snapshot, Dominant Mood) based on the context.",
                responseModel: FeelInsightResult.self
            )

             print("✅ [FeelInsightGenerator] LLM Success. Dominant Mood: \(result.dominantMood ?? "N/A")")

            // 8. Encode result
             print("⏳ [FeelInsightGenerator] Encoding result...")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601 // Ensure dates are encoded properly for chart data
             encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // Make JSON easier to read in DB/logs
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [FeelInsightGenerator] Encoding Failed: Failed to encode result to JSON string.")
                print("🏁 [FeelInsightGenerator] Finished: Aborted due to encoding error.")
                return
            }
             print("✅ [FeelInsightGenerator] Encoding successful.")
             // print("📄 [FeelInsightGenerator] Generated JSON:\n\(jsonString)") // Uncomment to log full JSON

            // 9. Save to Database
             print("⏳ [FeelInsightGenerator] Saving insight to database...")
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [FeelInsightGenerator] Insight saved successfully to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [FeelInsightGenerator] LLM generation failed: \(error.localizedDescription)")
            // Optionally log more details based on error type
            if case .decodingError(let reason) = error {
                 print("   LLM Decoding Error Detail: \(reason)")
            }
        } catch let error as DatabaseError {
             print("‼️ [FeelInsightGenerator] Database save failed: \(error)")
        } catch {
            print("‼️ [FeelInsightGenerator] An unexpected error occurred: \(error)")
        }
         print("🏁 [FeelInsightGenerator] Finished generateAndStoreIfNeeded.")
    }
}