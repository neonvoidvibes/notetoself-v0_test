import Foundation

actor WeekInReviewGenerator {
    private let llmService: LLMService
    private let databaseService: DatabaseService
    private let insightTypeIdentifier = "weekInReview"
    private let regenerationThresholdDays: Int = 7 // Regenerate weekly

    init(llmService: LLMService, databaseService: DatabaseService) {
        self.llmService = llmService
        self.databaseService = databaseService
    }

    func generateAndStoreIfNeeded() async {
        print("➡️ [WeekInReviewGenerator] Starting generateAndStoreIfNeeded...")

        let calendar = Calendar.current
        var shouldGenerate = true
        // Removed lastGenerationDate variable

        // 1. Check regeneration threshold (only generate if older than ~7 days)
        do {
            if let latest = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                // Removed assignment to lastGenerationDate
                let daysSinceLast = calendar.dateComponents([.day], from: latest.generatedDate, to: Date()).day ?? regenerationThresholdDays + 1
                if daysSinceLast < regenerationThresholdDays {
                    print("[WeekInReviewGenerator] Skipping generation: Last review generated \(daysSinceLast) days ago (Threshold: \(regenerationThresholdDays)).")
                    shouldGenerate = false
                } else {
                     print("[WeekInReviewGenerator] Last review is old enough (\(daysSinceLast) days).")
                }
            } else {
                print("[WeekInReviewGenerator] No previous review found. Will generate.")
            }
        } catch {
            print("‼️ [WeekInReviewGenerator] Error loading latest insight: \(error). Proceeding.")
        }

        guard shouldGenerate else { return }

        // 2. Determine date range for the *previous* full week (Sun-Sat)
        let today = Date()
        guard let previousSunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let startOfReviewWeek = calendar.date(byAdding: .day, value: -7, to: previousSunday), // Sunday of last week
              let endOfReviewWeek = calendar.date(byAdding: .day, value: 6, to: startOfReviewWeek) else { // Saturday of last week
            print("‼️ [WeekInReviewGenerator] Could not calculate previous week date range.")
            return
        }

         // Optional: Check if a review for this *specific* week already exists
         // This requires storing start/end dates with the insight and querying based on them.
         // For now, we rely on the regenerationThresholdDays check.

         // Corrected date format here
        print("[WeekInReviewGenerator] Target review week: \(startOfReviewWeek.formatted(date: .abbreviated, time: .omitted)) - \(endOfReviewWeek.formatted(date: .abbreviated, time: .omitted))")


        // 3. Fetch necessary data (entries for the target week)
        let entries: [JournalEntry]
        do {
            // Fetch all entries and filter for the specific week
            let allEntries = try databaseService.loadAllJournalEntries()
            entries = allEntries.filter { $0.date >= startOfReviewWeek && $0.date < calendar.date(byAdding: .day, value: 1, to: endOfReviewWeek)! }
                             .sorted { $0.date < $1.date } // Ensure chronological order for analysis
        } catch {
            print("‼️ [WeekInReviewGenerator] Error fetching journal entries: \(error)")
            return
        }

        guard entries.count >= 3 else { // Need at least a few entries for a meaningful review
            print("⚠️ [WeekInReviewGenerator] Skipping generation: Insufficient entries (\(entries.count)) for the target week.")
            // Optionally save an "empty" state for this week if needed
            return
        }

        print("[WeekInReviewGenerator] Using \(entries.count) entries for the week's review.")

        // 4. Format prompt context
        let context = entries.map { entry in
            "Date: \(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)\n\(entry.text.prefix(150))..."
        }.joined(separator: "\n\n")

        // 5. Get system prompt (Ensure this exists in SystemPrompts.swift)
        let systemPrompt = SystemPrompts.weekInReviewPrompt(entriesContext: context)

        // 6. Call LLMService
        do {
            var result: WeekInReviewResult = try await llmService.generateStructuredOutput(
                systemPrompt: systemPrompt,
                userMessage: "Generate the Week in Review insight based on the provided weekly context.",
                responseModel: WeekInReviewResult.self
            )

            print("✅ [WeekInReviewGenerator] LLM Success.")

            // Add the date range to the result before saving
            result.startDate = startOfReviewWeek
            result.endDate = endOfReviewWeek

            // 7. Encode result
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601 // Ensure dates are encoded properly
            encoder.outputFormatting = .prettyPrinted
            guard let jsonData = try? encoder.encode(result),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("‼️ [WeekInReviewGenerator] Failed to encode result to JSON string.")
                return
            }

            // 8. Save to Database
            // Use the end date of the review week as the primary generation date? Or current date? Let's use current date.
            try databaseService.saveGeneratedInsight(
                type: insightTypeIdentifier,
                date: Date(), // Save with current date
                jsonData: jsonString,
                startDate: startOfReviewWeek, // Store week range
                endDate: endOfReviewWeek
            )
            print("✅ [WeekInReviewGenerator] Insight saved to database.")

        } catch let error as LLMService.LLMError {
            print("‼️ [WeekInReviewGenerator] LLM generation failed: \(error.localizedDescription)")
        } catch {
            print("‼️ [WeekInReviewGenerator] An unexpected error occurred: \(error)")
        }
        print("🏁 [WeekInReviewGenerator] Finished generateAndStoreIfNeeded.")
    }
}