import Foundation

actor ActInsightGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let insightTypeIdentifier = "actInsights"
    private let regenerationThresholdDays: Int = 1 // Regenerate frequently if needed

    init(llmService: LLMService, databaseService: DatabaseService) {
        self.llmService = llmService
        self.databaseService = databaseService
    }

    func generateAndStoreIfNeeded(forceGeneration: Bool = false) async {
        print("➡️ [ActInsightGenerator] Starting generateAndStoreIfNeeded...")

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
                         print("[ActInsightGenerator] Skipping generation (Normal): Last insight generated \(daysSinceLast) days ago.")
                         shouldGenerate = false
                     } else {
                          print("[ActInsightGenerator] Last insight old enough (Normal). Checking for new entries...")
                     }
                 } else {
                     print("[ActInsightGenerator] No previous insight found (Normal).")
                 }
             } catch {
                 print("‼️ [ActInsightGenerator] Error loading latest insight (Normal): \(error). Proceeding.")
             }
             // Only return if the time threshold check explicitly failed
             guard shouldGenerate else { return }
        } else {
             print("[ActInsightGenerator] Bypassing time checks due to forceGeneration.")
        }

        // 2. Fetch necessary data (use rolling window)
        var feelInsightJSON: String? = nil
        var thinkInsightJSON: String? = nil
        let entries: [JournalEntry]

        do {
            let allEntriesSorted = try databaseService.loadAllJournalEntries()
            entries = getEntriesForRollingWindow(allEntriesSortedDesc: allEntriesSorted)
            print("✅ [ActInsightGenerator] Data Fetch: Using \(entries.count) entries from rolling window.")

            // Fetch dependent insights (needed regardless of force, for context)
            feelInsightJSON = try databaseService.loadLatestInsight(type: "feelInsights")?.jsonData
            thinkInsightJSON = try databaseService.loadLatestInsight(type: "thinkInsights")?.jsonData
        } catch {
            print("‼️ [ActInsightGenerator] Error fetching data: \(error)")
            return
        }

         // 3. Check Minimum Entry Count (always required)
        guard entries.count >= 2 else {
            print("⚠️ [ActInsightGenerator] Skipping generation: Insufficient entries (\(entries.count)) in rolling window for context.")
            return
        }

         // 4. Check for New Entries only if not forcing and time threshold passed
         if !forceGeneration && shouldGenerate {
              if let lastGenDate = lastGenerationDate {
                  let hasNewEntries = entries.contains { $0.date > lastGenDate }
                  if !hasNewEntries {
                      print("⚠️ [ActInsightGenerator] New Entry Check Failed (Normal): Skipping LLM generation as no entries are newer than last insight.")
                      try? await databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                      return
                  } else {
                       print("✅ [ActInsightGenerator] New Entry Check Passed (Normal): Found newer entries.")
                  }
              } else {
                   print("✅ [ActInsightGenerator] New Entry Check: First generation run (Normal).")
              }
         } else if forceGeneration {
              print("[ActInsightGenerator] Bypassing new entry check due to forceGeneration.")
         }

        print("[ActInsightGenerator] Using \(entries.count) entries for context. Feel Insight Present: \(feelInsightJSON != nil), Think Insight Present: \(thinkInsightJSON != nil)")

        // 3. Format prompt context
        let entryContext = entries.map { entry in
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(150))..."
        }.joined(separator: "\n\n")

        // 4. Get system prompt
        let systemPrompt = SystemPrompts.actInsightPrompt(
            entriesContext: entryContext,
            feelContext: feelInsightJSON, // Pass JSON strings directly
            thinkContext: thinkInsightJSON
        )

        // 5. Call LLMService
        do {
            let result: ActInsightResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the Act insight (Action Forecast and Personalized Recommendations) based on the context.",
                responseModel: ActInsightResult.self
            )

            print("✅ [ActInsightGenerator] LLM Success.")

            // 6. Encode result
            let encoder = JSONEncoder()
             // Ensure UUIDs in recommendations are encoded correctly
            encoder.outputFormatting = .prettyPrinted
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [ActInsightGenerator] Failed to encode result to JSON string.")
                return
            }

            // 7. Save to Database
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [ActInsightGenerator] Insight saved to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [ActInsightGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch {
            print("‼️ [ActInsightGenerator] An unexpected error occurred: \(error)")
        }
        print("🏁 [ActInsightGenerator] Finished generateAndStoreIfNeeded.")
    }
}