import Foundation

// Actor to ensure thread-safe generation and saving
actor MoodTrendGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let insightTypeIdentifier = "moodTrend"
    private let regenerationThresholdDays: Int = 1 // Regenerate if last trend is older than 1 day AND new entries exist

    init(llmService: LLMService, databaseService: DatabaseService) {
        self.llmService = llmService
        self.databaseService = databaseService
    }

    func generateAndStoreIfNeeded() async {
        print("[MoodTrendGenerator] Checking if generation is needed...")

        // 1. Check if regeneration is necessary
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today)! // Use 2 weeks for trends

        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        do {
            if let latest = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                if daysSinceLast < regenerationThresholdDays {
                    print("[MoodTrendGenerator] Skipping generation: Last trend generated \(daysSinceLast) days ago (Threshold: \(regenerationThresholdDays)).")
                    shouldGenerate = false
                } else {
                    print("[MoodTrendGenerator] Last trend is old enough (\(daysSinceLast) days). Checking for new entries...")
                }
            } else {
                print("[MoodTrendGenerator] No previous trend found. Will generate.")
            }
        } catch {
            print("‼️ [MoodTrendGenerator] Error loading latest insight: \(error). Proceeding with generation.")
        }

        guard shouldGenerate else { return }

        // 2. Fetch necessary data (last 14 days of entries)
        let entries: [JournalEntry]
        do {
            // Fetch slightly more data to ensure enough context if needed
            let fetchStartDate = calendar.date(byAdding: .day, value: -21, to: today)!
            entries = try databaseService.loadAllJournalEntries().filter { $0.date >= fetchStartDate }
                                       .sorted { $0.date < $1.date } // Sort oldest to newest for trend analysis
        } catch {
            print("‼️ [MoodTrendGenerator] Error fetching journal entries: \(error)")
            return
        }

        // Check if there are new entries since the last generation (if applicable)
         if let lastGenDate = lastGenerationDate {
              let hasNewEntries = entries.contains { $0.date > lastGenDate }
              if !hasNewEntries {
                   print("[MoodTrendGenerator] Skipping generation: No new entries since last trend on \(lastGenDate.formatted()).")
                   return
              }
              print("[MoodTrendGenerator] New entries found since last generation. Proceeding.")
         }


        guard entries.count >= 3 else { // Need at least a few entries for trend
            print("[MoodTrendGenerator] Skipping generation: Insufficient entries (\(entries.count)) for trend analysis.")
            return
        }

        print("[MoodTrendGenerator] Found \(entries.count) entries for trend generation.")

        // 3. Format prompt context
        let context = entries.map { entry in
            "Date: \(entry.date.formatted(date: .short, time: .omitted)), Mood: \(entry.mood.name)" // Keep context concise
        }.joined(separator: "\n")

        // 4. Get system prompt
        let systemPrompt = SystemPrompts.moodTrendPrompt(entriesContext: context)

        // 5. Call LLMService for structured output
        do {
            let result: MoodTrendResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the mood trend analysis based on the provided context.",
                responseModel: MoodTrendResult.self
            )

            print("[MoodTrendGenerator] Successfully generated trend: \(result.overallTrend), Dominant: \(result.dominantMood)")

            // 6. Encode result back to JSON string
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [MoodTrendGenerator] Failed to encode result to JSON string.")
                return
            }

            // 7. Save to Database
            try await databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString,
                startDate: twoWeeksAgo, // Store the period covered (approx)
                endDate: today
            )
            print("✅ [MoodTrendGenerator] Successfully saved generated insight to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [MoodTrendGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch {
            print("‼️ [MoodTrendGenerator] An unexpected error occurred: \(error)")
        }
    }
}
