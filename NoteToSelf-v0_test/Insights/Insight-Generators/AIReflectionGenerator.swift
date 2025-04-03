import Foundation

// Actor to ensure thread-safe generation and saving
actor AIReflectionGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let appState: AppState // Need access to recent entries
    private let insightTypeIdentifier = "aiReflection" // Use new type identifier
    private let regenerationThresholdHours: Int = 6 // Regenerate more frequently if needed, e.g., every 6 hours if new entries

    init(llmService: LLMService, databaseService: DatabaseService, appState: AppState) {
        self.llmService = llmService
        self.databaseService = databaseService
        self.appState = appState
    }

    func generateAndStoreIfNeeded() async {
        print("[AIReflectionGenerator] Checking if generation is needed...")

        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        do {
            // Remove await - loadLatestInsight is currently sync
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let hoursSinceLast = calendar.dateComponents([.hour], from: latest.generatedDate, to: Date()).hour ?? regenerationThresholdHours + 1
                if hoursSinceLast < regenerationThresholdHours {
                    print("[AIReflectionGenerator] Skipping generation: Last reflection generated \(hoursSinceLast) hours ago.")
                    shouldGenerate = false
                } else {
                     print("[AIReflectionGenerator] Last reflection is old enough. Checking for new entries...")
                }
            } else {
                print("[AIReflectionGenerator] No previous reflection found. Will generate.")
            }
        } catch {
            print("‼️ [AIReflectionGenerator] Error loading latest insight: \(error). Proceeding.")
        }

        guard shouldGenerate else { return }

        // Fetch necessary data (e.g., last 1-3 entries for context)
        let entries: [JournalEntry]
        // Add await for safety when accessing MainActor property from background actor
        entries = await Array(appState.journalEntries.prefix(3))


         // Check if there are new entries since the last generation (if applicable)
         if let lastGenDate = lastGenerationDate {
             let hasNewEntries = entries.contains { $0.date > lastGenDate }
             if !hasNewEntries && !entries.isEmpty {
                  print("[AIReflectionGenerator] Skipping generation: No new entries since last reflection.")
                  // try? databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date()) // Optional: Update timestamp
                  return
             }
              print("[AIReflectionGenerator] New entries found or first time generation. Proceeding.")
         }

        // Need at least one entry usually to generate meaningful reflection
        guard !entries.isEmpty else {
            print("[AIReflectionGenerator] Skipping generation: No entries found for reflection context.")
            // Optionally save an "empty" insight state if needed
            return
        }

        print("[AIReflectionGenerator] Found \(entries.count) recent entries for context.")

        // Format prompt context
        let context = entries.map { entry in
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(200))..."
        }.joined(separator: "\n\n")

        // Get system prompt
        let systemPrompt = SystemPrompts.aiReflectionPrompt(entriesContext: context)

        // Call LLMService
        do {
            let result: AIReflectionResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate an insight message and reflection prompts based on the context.",
                responseModel: AIReflectionResult.self
            )

            print("[AIReflectionGenerator] Successfully generated insight message: \(result.insightMessage)")

            // Encode result
            let encoder = JSONEncoder()
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [AIReflectionGenerator] Failed to encode result to JSON string.")
                return
            }

            // Save to Database
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [AIReflectionGenerator] Successfully saved generated insight to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [AIReflectionGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch {
            print("‼️ [AIReflectionGenerator] An unexpected error occurred: \(error)")
        }
    }
}