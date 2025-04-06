import Foundation

actor LearnInsightGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let insightTypeIdentifier = "learnInsights"
    private let regenerationThresholdDays: Int = 7 // Regenerate weekly

    init(llmService: LLMService, databaseService: DatabaseService) {
        self.llmService = llmService
        self.databaseService = databaseService
    }

    func generateAndStoreIfNeeded() async {
        print("➡️ [LearnInsightGenerator] Starting generateAndStoreIfNeeded...")

        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        // 1. Check regeneration threshold
        do {
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                if daysSinceLast < regenerationThresholdDays {
                    print("[LearnInsightGenerator] Skipping generation: Last insight generated \(daysSinceLast) days ago.")
                    shouldGenerate = false
                } else {
                     print("[LearnInsightGenerator] Last insight is old enough. Checking for new entries...")
                }
            } else {
                print("[LearnInsightGenerator] No previous insight found. Will generate.")
            }
        } catch {
            print("‼️ [LearnInsightGenerator] Error loading latest insight: \(error). Proceeding.")
        }

        guard shouldGenerate else { return }

        // 2. Fetch necessary data (e.g., last 7-14 days of entries)
        let entries: [JournalEntry]
        let fetchStartDate = calendar.date(byAdding: .day, value: -14, to: Date())!
        do {
            entries = try databaseService.loadAllJournalEntries().filter { $0.date >= fetchStartDate }
        } catch {
            print("‼️ [LearnInsightGenerator] Error fetching journal entries: \(error)")
            return
        }

        // Check if there are new entries since the last generation (if applicable)
         if let lastGenDate = lastGenerationDate {
              let hasNewEntries = entries.contains { $0.date > lastGenDate }
              if !hasNewEntries && !entries.isEmpty {
                   print("[LearnInsightGenerator] Skipping generation: No new entries since last insight.")
                    try? databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                   return
              }
         }

        guard entries.count >= 3 else { // Need some entries for learning context
            print("⚠️ [LearnInsightGenerator] Skipping generation: Insufficient entries (\(entries.count)) for context.")
            return
        }

        print("[LearnInsightGenerator] Using \(entries.count) entries for context.")

        // 3. Format prompt context
        let context = entries.map { entry in
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(150))..."
        }.joined(separator: "\n\n")

        // 4. Get system prompt
        let systemPrompt = SystemPrompts.learnInsightPrompt(entriesContext: context)

        // 5. Call LLMService
        do {
            let result: LearnInsightResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the Learn insight (Takeaway, Before/After, Next Step) based on the context.",
                responseModel: LearnInsightResult.self
            )

            print("✅ [LearnInsightGenerator] LLM Success.")

            // 6. Encode result
            let encoder = JSONEncoder()
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [LearnInsightGenerator] Failed to encode result to JSON string.")
                return
            }

            // 7. Save to Database
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [LearnInsightGenerator] Insight saved to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [LearnInsightGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch {
            print("‼️ [LearnInsightGenerator] An unexpected error occurred: \(error)")
        }
        print("🏁 [LearnInsightGenerator] Finished generateAndStoreIfNeeded.")
    }
}