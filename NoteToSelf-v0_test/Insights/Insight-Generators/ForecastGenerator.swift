import Foundation

// Actor to ensure thread-safe generation and saving
actor ForecastGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let appState: AppState // Need access to recent entries
    private let insightTypeIdentifier = "forecast"
    private let regenerationThresholdDays: Int = 1 // Regenerate daily if new data

    init(llmService: LLMService, databaseService: DatabaseService, appState: AppState) {
        self.llmService = llmService
        self.databaseService = databaseService
        self.appState = appState
    }

    func generateAndStoreIfNeeded() async {
        print("[ForecastGenerator] Checking if generation is needed...")

        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        // 1. Check regeneration threshold
        do {
             // Remove await - loadLatestInsight is currently sync
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                if daysSinceLast < regenerationThresholdDays {
                    print("[ForecastGenerator] Skipping generation: Last forecast generated \(daysSinceLast) days ago.")
                    shouldGenerate = false
                } else {
                    print("[ForecastGenerator] Last forecast is old enough. Checking for new data...")
                }
            } else {
                print("[ForecastGenerator] No previous forecast found. Will generate.")
            }
        } catch {
            print("‼️ [ForecastGenerator] Error loading latest insight: \(error). Proceeding.")
        }

        guard shouldGenerate else { return }

        // 2. Fetch necessary data
        let entries: [JournalEntry]
        var moodTrendString: String? = nil
        var recommendationsString: String? = nil

        do {
            // Accessing appState property might need await if done deeper inside async context, but here it's likely fine.
            entries = await Array(appState.journalEntries.prefix(10)) // Add await for safety accessing AppState

            // Fetch latest mood trend and recommendations JSON
            // Remove await - loadLatestInsight is currently sync
            if let (json, _) = try? databaseService.loadLatestInsight(type: "moodTrend") {
                moodTrendString = json
            }
            if let (json, _) = try? databaseService.loadLatestInsight(type: "recommendation") {
                recommendationsString = json
            }
        }

        // Check if there are new entries since the last generation (most crucial data source)
        if let lastGenDate = lastGenerationDate {
             let hasNewEntries = entries.contains { $0.date > lastGenDate }
             if !hasNewEntries && !entries.isEmpty {
                  print("[ForecastGenerator] Skipping generation: No new entries since last forecast.")
                  // try? databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date()) // Optional: Update timestamp
                  return
             }
              print("[ForecastGenerator] New entries found or first time generation. Proceeding.")
        }


        // Need some entries for a forecast
        guard entries.count >= 3 else {
            print("[ForecastGenerator] Skipping generation: Insufficient entries (\(entries.count)) for forecast.")
            return
        }

        print("[ForecastGenerator] Found \(entries.count) entries, mood trend: \(moodTrendString != nil), recs: \(recommendationsString != nil) for context.")

        // 3. Format prompt context
        let entryContext = entries.map { entry in
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(150))..."
        }.joined(separator: "\n\n")

        // Simple text representation of other insights for the prompt
        let moodContext = moodTrendString ?? "Not available"
        let recsContext = recommendationsString ?? "Not available"

        // 4. Get system prompt
        let systemPrompt = SystemPrompts.forecastPrompt(
            entriesContext: entryContext,
            moodTrendContext: moodContext,
            recommendationsContext: recsContext
        )

        // 5. Call LLMService
        do {
            let result: ForecastResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the forecast based on the provided context.",
                responseModel: ForecastResult.self
            )

            print("[ForecastGenerator] Successfully generated forecast. Mood Prediction: \(result.moodPredictionText ?? "N/A")")

            // 6. Encode result
            let encoder = JSONEncoder()
            // Ensure UUIDs in ActionPlanItem are encoded correctly
            encoder.outputFormatting = .prettyPrinted
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [ForecastGenerator] Failed to encode result to JSON string.")
                return
            }

            // 7. Save to Database
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [ForecastGenerator] Successfully saved generated insight to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [ForecastGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch {
            print("‼️ [ForecastGenerator] An unexpected error occurred: \(error)")
        }
    }
}