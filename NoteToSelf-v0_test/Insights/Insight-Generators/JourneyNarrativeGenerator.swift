import Foundation

// Actor to ensure thread-safe generation and saving
// Renamed from StreakNarrativeGenerator
actor JourneyNarrativeGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let appState: AppState // Need access to current streak count
    private let insightTypeIdentifier = "journeyNarrative" // Updated type identifier
    private let regenerationThresholdDays: Int = 1 // Regenerate daily if new entries

    init(llmService: LLMService, databaseService: DatabaseService, appState: AppState) {
        self.llmService = llmService
        self.databaseService = databaseService
        self.appState = appState
    }

    // Add forceGeneration parameter
    func generateAndStoreIfNeeded(forceGeneration: Bool = false) async {
        print("➡️ [JourneyNarrativeGenerator] Starting generateAndStoreIfNeeded (Forced: \(forceGeneration))...")

        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        // Only run checks if not forcing generation
        if !forceGeneration {
            do {
                 // Fetch latest insight synchronously
                if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                    lastGenerationDate = latest.generatedDate
                    let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                    if daysSinceLast < regenerationThresholdDays {
                        print("[JourneyNarrativeGenerator] Skipping generation (Normal): Last narrative generated \(daysSinceLast) days ago.")
                        shouldGenerate = false
                    } else {
                        print("[JourneyNarrativeGenerator] Last narrative is old enough (Normal). Checking for new entries...")
                    }
                } else {
                    print("[JourneyNarrativeGenerator] No previous narrative found (Normal). Will generate.")
                }
            } catch {
                print("‼️ [JourneyNarrativeGenerator] Error loading latest insight (Normal): \(error). Proceeding.")
            }

            // Only guard if not forcing
            guard shouldGenerate else {
                print("[JourneyNarrativeGenerator] Condition checks failed (Normal - Time Threshold). Exiting.")
                return
            }

             // Fetch entries needed for the 'new entry' check below
             let entriesForCheck = await Array(appState.journalEntries.prefix(7))

             // Check if there are new entries since the last generation (if applicable)
             if let lastGenDate = lastGenerationDate {
                  let hasNewEntries = entriesForCheck.contains { $0.date > lastGenDate }
                  if !hasNewEntries && !entriesForCheck.isEmpty { // Don't skip if entries list itself is empty
                       print("[JourneyNarrativeGenerator] Skipping generation (Normal): No new entries since last narrative.")
                       // Update timestamp even if skipping generation due to no new entries
                        do {
                            try databaseService.updateInsightTimestamp(type: insightTypeIdentifier, date: Date())
                            print("[JourneyNarrativeGenerator] Updated timestamp for existing insight.")
                        } catch {
                             print("‼️ [JourneyNarrativeGenerator] Error updating timestamp: \(error)")
                        }
                       return
                  }
                  print("[JourneyNarrativeGenerator] New entries found since last generation (Normal). Proceeding.")
             } else if !entriesForCheck.isEmpty {
                  // This path means lastGenDate was nil (first run)
                  print("[JourneyNarrativeGenerator] First generation run (Normal). Proceeding.")
             }
             // If entriesForCheck is empty, we will skip later anyway
        } else {
             print("[JourneyNarrativeGenerator] Bypassing date/new-entry checks due to forceGeneration.")
        }


        // Fetch necessary data (e.g., last 5-7 entries for context) - potentially redundant if fetched above, but safe
        let entries: [JournalEntry]
        // Add await here for safety when accessing MainActor property from background actor
        entries = await Array(appState.journalEntries.prefix(7))

        // Need at least one entry usually to generate meaningful narrative
        guard !entries.isEmpty else {
            print("⚠️ [JourneyNarrativeGenerator] Skipping generation: No entries found for narrative context.")
            // Optionally save an "empty" insight state if needed
            return
        }

        print("[JourneyNarrativeGenerator] Using \(entries.count) recent entries for context.")
        // Add await here because appState is MainActor and this is a background actor
        let currentStreak = await appState.currentStreak

        // Format prompt context
        let context = entries.map { entry in
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(150))..."
        }.joined(separator: "\n\n")

        // Get system prompt
        // Use the existing streakNarrativePrompt - the name is fine, it describes the content
        let systemPrompt = SystemPrompts.streakNarrativePrompt(entriesContext: context, streakCount: currentStreak)

        print("[JourneyNarrativeGenerator] Preparing to call LLM with streak \(currentStreak)...")
        // Call LLMService
        do {
            let result: StreakNarrativeResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the streak narrative based on the context.",
                responseModel: StreakNarrativeResult.self // Keep using StreakNarrativeResult struct
            )

            print("✅ [JourneyNarrativeGenerator] LLM Success. Snippet: >>>\(result.storySnippet)<<< Narrative: >>>\(result.narrativeText)<<<")

            // Encode result
            let encoder = JSONEncoder()
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [JourneyNarrativeGenerator] Failed to encode result to JSON string.")
                return
            }

            // Save to Database
            print("[JourneyNarrativeGenerator] Attempting to save insight to DB...")
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier, // Use updated identifier
                date: Date(),
                jsonData: jsonString
            )
            print("✅ [JourneyNarrativeGenerator] Insight saved to database.")

        } catch let error as LLMService.LLMError {
            // Log specific LLM error
            print("‼️ [JourneyNarrativeGenerator] LLM generation failed: \(error.localizedDescription)")
            if case .decodingError(let reason) = error {
                print("‼️ Decoding Error Detail: \(reason)")
            }
        } catch let error as DatabaseError {
             print("‼️ [JourneyNarrativeGenerator] Database save failed: \(error)")
        } catch {
            print("‼️ [JourneyNarrativeGenerator] An unexpected error occurred during generation/saving: \(error)")
        }
        print("🏁 [JourneyNarrativeGenerator] Finished generateAndStoreIfNeeded.")
    }
}