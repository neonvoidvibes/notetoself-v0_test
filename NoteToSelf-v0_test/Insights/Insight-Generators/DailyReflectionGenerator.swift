import Foundation

actor DailyReflectionGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let appState: AppState // Need access to recent entries
    private let insightTypeIdentifier = "dailyReflection"
    private let regenerationThresholdHours: Int = 1 // Regenerate frequently if new entries exist

    init(llmService: LLMService, databaseService: DatabaseService, appState: AppState) {
        self.llmService = llmService
        self.databaseService = databaseService
        self.appState = appState
    }

    func generateAndStoreIfNeeded() async {
        print("➡️ [DailyReflectionGenerator] Starting generateAndStoreIfNeeded...")

        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        // 1. Check regeneration threshold
        do {
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let hoursSinceLast = calendar.dateComponents([.hour], from: latest.generatedDate, to: Date()).hour ?? regenerationThresholdHours + 1
                if hoursSinceLast < regenerationThresholdHours {
                    print("[DailyReflectionGenerator] Skipping generation: Last insight generated \(hoursSinceLast) hours ago.")
                    shouldGenerate = false
                } else {
                     print("[DailyReflectionGenerator] Last insight is old enough. Checking for new entries...")
                }
            } else {
                print("[DailyReflectionGenerator] No previous insight found. Will generate.")
            }
        } catch {
            print("‼️ [DailyReflectionGenerator] Error loading latest insight: \(error). Proceeding.")
        }

        guard shouldGenerate else { return }

        // 2. Fetch necessary data (latest 1-2 entries)
        let entries = await Array(appState.journalEntries.prefix(2)) // Safely access AppState

        // Check if there are *any* entries at all
        guard !entries.isEmpty else {
            print("⚠️ [DailyReflectionGenerator] Skipping generation: No entries found.")
            return
        }

        // Check if the most recent entry is newer than the last generated insight
        if let lastGenDate = lastGenerationDate, let mostRecentEntryDate = entries.first?.date {
             if mostRecentEntryDate <= lastGenDate {
                  print("[DailyReflectionGenerator] Skipping generation: No new entries since last insight on \(lastGenDate.formatted()).")
                   try? databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                  return
             }
             print("[DailyReflectionGenerator] New entry found since last generation. Proceeding.")
        } else if !entries.isEmpty {
             print("[DailyReflectionGenerator] First generation run or new entries found. Proceeding.")
        }

        print("[DailyReflectionGenerator] Using \(entries.count) recent entries for context.")

        // 3. Format prompt context (focus on the *very latest* entry primarily)
        let latestEntry = entries[0]
        let context = """
        Latest Entry:
        Date: \(latestEntry.date.formatted(date: .numeric, time: .shortened)), Mood: \(latestEntry.mood.name)
        \(latestEntry.text)
        """
        // Optionally add context from the second latest entry if available
        // let context = entries.map { ... }.joined() // If using more than one entry

        // 4. Get system prompt
        let systemPrompt = SystemPrompts.dailyReflectionPrompt(entryContext: context)

        // 5. Call LLMService
        do {
            let result: DailyReflectionResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the daily reflection snapshot and prompts based on the latest entry context.",
                responseModel: DailyReflectionResult.self
            )

            print("✅ [DailyReflectionGenerator] LLM Success.")

            // 6. Encode result
            let encoder = JSONEncoder()
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [DailyReflectionGenerator] Failed to encode result to JSON string.")
                return
            }

            // 7. Save to Database
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [DailyReflectionGenerator] Insight saved to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [DailyReflectionGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch {
            print("‼️ [DailyReflectionGenerator] An unexpected error occurred: \(error)")
        }
        print("🏁 [DailyReflectionGenerator] Finished generateAndStoreIfNeeded.")
    }
}