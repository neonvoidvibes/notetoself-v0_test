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

    func generateAndStoreIfNeeded() async {
        print("➡️ [ActInsightGenerator] Starting generateAndStoreIfNeeded...")

        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        // 1. Check regeneration threshold
        do {
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                if daysSinceLast < regenerationThresholdDays {
                    print("[ActInsightGenerator] Skipping generation: Last insight generated \(daysSinceLast) days ago.")
                    shouldGenerate = false
                } else {
                     print("[ActInsightGenerator] Last insight is old enough. Checking for new entries...")
                }
            } else {
                print("[ActInsightGenerator] No previous insight found. Will generate.")
            }
        } catch {
            print("‼️ [ActInsightGenerator] Error loading latest insight: \(error). Proceeding.")
        }

        guard shouldGenerate else { return }

        // 2. Fetch necessary data (e.g., last 7 days of entries, maybe latest Feel/Think insights)
        let entries: [JournalEntry]
        let fetchStartDate = calendar.date(byAdding: .day, value: -7, to: Date())!
        var feelInsightJSON: String? = nil
        var thinkInsightJSON: String? = nil

        do {
            entries = try databaseService.loadAllJournalEntries().filter { $0.date >= fetchStartDate }
            feelInsightJSON = try databaseService.loadLatestInsight(type: "feelInsights")?.jsonData
            thinkInsightJSON = try databaseService.loadLatestInsight(type: "thinkInsights")?.jsonData
        } catch {
            print("‼️ [ActInsightGenerator] Error fetching data: \(error)")
            return
        }

        // Check if there are new entries since the last generation (if applicable)
         if let lastGenDate = lastGenerationDate {
              let hasNewEntries = entries.contains { $0.date > lastGenDate }
              if !hasNewEntries && !entries.isEmpty {
                   print("[ActInsightGenerator] Skipping generation: No new entries since last insight.")
                    try? databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                   return
              }
         }

        guard entries.count >= 2 else { // Need some recent entries for action context
            print("⚠️ [ActInsightGenerator] Skipping generation: Insufficient entries (\(entries.count)) for context.")
            return
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