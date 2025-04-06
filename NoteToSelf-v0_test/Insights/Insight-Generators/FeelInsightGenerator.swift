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

    func generateAndStoreIfNeeded() async {
        print("➡️ [FeelInsightGenerator] Starting generateAndStoreIfNeeded...")

        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        // 1. Check regeneration threshold
        do {
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                if daysSinceLast < regenerationThresholdDays {
                    print("[FeelInsightGenerator] Skipping generation: Last insight generated \(daysSinceLast) days ago.")
                    shouldGenerate = false
                } else {
                     print("[FeelInsightGenerator] Last insight is old enough. Checking for new entries...")
                }
            } else {
                print("[FeelInsightGenerator] No previous insight found. Will generate.")
            }
        } catch {
            print("‼️ [FeelInsightGenerator] Error loading latest insight: \(error). Proceeding.")
        }

        guard shouldGenerate else { return }

        // 2. Fetch necessary data (e.g., last 7-14 days of entries)
        let entries: [JournalEntry]
        let fetchStartDate = calendar.date(byAdding: .day, value: -14, to: Date())! // Fetch last 14 days
        do {
            entries = try databaseService.loadAllJournalEntries().filter { $0.date >= fetchStartDate }
        } catch {
            print("‼️ [FeelInsightGenerator] Error fetching journal entries: \(error)")
            return
        }

        // Check if there are new entries since the last generation (if applicable)
         if let lastGenDate = lastGenerationDate {
              let hasNewEntries = entries.contains { $0.date > lastGenDate }
              if !hasNewEntries && !entries.isEmpty {
                   print("[FeelInsightGenerator] Skipping generation: No new entries since last insight.")
                    try? databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                   return
              }
         }

        guard entries.count >= 3 else {
            print("⚠️ [FeelInsightGenerator] Skipping generation: Insufficient entries (\(entries.count)) for context.")
            return
        }

        print("[FeelInsightGenerator] Using \(entries.count) entries for context.")

        // 3. Format prompt context
        let context = entries.map { entry in
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(150))..."
        }.joined(separator: "\n\n")

        // 4. Get system prompt
        let systemPrompt = SystemPrompts.feelInsightPrompt(entriesContext: context)

        // 5. Call LLMService
        do {
            let result: FeelInsightResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the Feel insight (Mood Trend, Snapshot, Dominant Mood) based on the context.", // Updated user message
                responseModel: FeelInsightResult.self
            )

             print("✅ [FeelInsightGenerator] LLM Success. Dominant Mood: \(result.dominantMood ?? "N/A")") // Log dominant mood

            // 6. Encode result
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601 // Ensure dates are encoded properly for chart data
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [FeelInsightGenerator] Failed to encode result to JSON string.")
                return
            }

            // 7. Save to Database
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [FeelInsightGenerator] Insight saved to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [FeelInsightGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch {
            print("‼️ [FeelInsightGenerator] An unexpected error occurred: \(error)")
        }
         print("🏁 [FeelInsightGenerator] Finished generateAndStoreIfNeeded.")
    }
}