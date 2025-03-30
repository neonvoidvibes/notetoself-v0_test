import Foundation

// Actor to ensure thread-safe generation and saving
actor RecommendationGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let insightTypeIdentifier = "recommendation"
    private let regenerationThresholdDays: Int = 3 // Regenerate less frequently than others

    init(llmService: LLMService, databaseService: DatabaseService) {
        self.llmService = llmService
        self.databaseService = databaseService
    }

    func generateAndStoreIfNeeded() async {
        print("[RecommendationGenerator] Checking if generation is needed...")

        // 1. Check if regeneration is necessary
        let calendar = Calendar.current
        var shouldGenerate = true
        var lastGenerationDate: Date? = nil

        do {
            if let latest = try await databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                lastGenerationDate = latest.generatedDate
                let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                if daysSinceLast < regenerationThresholdDays {
                    print("[RecommendationGenerator] Skipping generation: Last recommendations generated \(daysSinceLast) days ago (Threshold: \(regenerationThresholdDays)).")
                    shouldGenerate = false
                } else {
                    print("[RecommendationGenerator] Last recommendations are old enough (\(daysSinceLast) days). Checking for new entries...")
                }
            } else {
                print("[RecommendationGenerator] No previous recommendations found. Will generate.")
            }
        } catch {
            print("‼️ [RecommendationGenerator] Error loading latest insight: \(error). Proceeding with generation.")
        }

        guard shouldGenerate else { return }

        // 2. Fetch necessary data (e.g., last 10-15 entries for context)
        let entries: [JournalEntry]
        do {
            entries = Array(try databaseService.loadAllJournalEntries().prefix(15)) // Get up to 15 most recent
        } catch {
            print("‼️ [RecommendationGenerator] Error fetching journal entries: \(error)")
            return
        }

         // Check if there are new entries since the last generation (if applicable)
         if let lastGenDate = lastGenerationDate {
              let hasNewEntries = entries.contains { $0.date > lastGenDate }
              if !hasNewEntries {
                   print("[RecommendationGenerator] Skipping generation: No new entries since last recommendations on \(lastGenDate.formatted()).")
                   return
              }
              print("[RecommendationGenerator] New entries found since last generation. Proceeding.")
         }

        guard entries.count >= 3 else { // Need some entries for context
            print("[RecommendationGenerator] Skipping generation: Insufficient entries (\(entries.count)) for recommendations.")
            return
        }

        print("[RecommendationGenerator] Found \(entries.count) entries for recommendation generation.")

        // 3. Format prompt context
        let context = entries.map { entry in
            "Date: \(entry.date.formatted(date: .short, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(150))..." // Limit context length
        }.joined(separator: "\n\n")

        // 4. Get system prompt
        let systemPrompt = SystemPrompts.recommendationPrompt(entriesContext: context)

        // 5. Call LLMService for structured output
        do {
            let result: RecommendationResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate recommendations based on the provided journal context.",
                responseModel: RecommendationResult.self
            )

            guard !result.recommendations.isEmpty else {
                print("[RecommendationGenerator] LLM returned empty recommendations array. Skipping save.")
                // Optionally save an "empty" state if needed
                return
            }

            print("[RecommendationGenerator] Successfully generated \(result.recommendations.count) recommendations.")

            // 6. Encode result back to JSON string
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [RecommendationGenerator] Failed to encode result to JSON string.")
                return
            }

            // 7. Save to Database
            try await databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(),
                jsonData: jsonString
                // No start/end date needed for recommendations generally
            )
            print("✅ [RecommendationGenerator] Successfully saved generated insight to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [RecommendationGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch {
            print("‼️ [RecommendationGenerator] An unexpected error occurred: \(error)")
        }
    }
}
