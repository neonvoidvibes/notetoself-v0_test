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

        // *** NEW: Check if within the active generation window (Sun 3am - Mon 11:59pm) ***
        let now = Date()
        let weekday = calendar.component(.weekday, from: now) // Sunday=1, Saturday=7
        let hour = calendar.component(.hour, from: now)

        // Active Period: Sunday 3:00 AM to Monday 23:59:59 (effectively Tuesday 00:00) = 45 hours
        let isSundayActivePeriod = (weekday == 1 && hour >= 3) // Sunday 3am onwards
        let isMondayActivePeriod = (weekday == 2)             // All of Monday

        guard isSundayActivePeriod || isMondayActivePeriod else {
            print("[WeekInReviewGenerator] Skipping generation: Outside active window (Sun 3am - Mon 11:59pm). Current: weekday \(weekday), hour \(hour)")
            return
        }
        print("[WeekInReviewGenerator] Within active generation window.")
        // *** END NEW CHECK ***

        // 2. Determine date range for the *previous* full week (Sun-Sat)
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)), // Start of *this* week
              let startOfReviewWeek = calendar.date(byAdding: .day, value: -7, to: currentWeekStart), // Sunday of last week (7 days before start of *current* week)
              let endOfReviewWeek = calendar.date(byAdding: .day, value: 6, to: startOfReviewWeek) else { // Saturday of last week
            print("‼️ [WeekInReviewGenerator] Could not calculate previous week date range.")
            return
        }
        // Use variables directly as the guard statement ensures they are non-nil
        print("[WeekInReviewGenerator] Target review week: \(startOfReviewWeek.formatted(date: .abbreviated, time: .omitted)) - \(endOfReviewWeek.formatted(date: .abbreviated, time: .omitted))")

         // Optional: Check if a review for this *specific* week already exists
         // This requires storing start/end dates with the insight and querying based on them.
         // For now, we rely on the regenerationThresholdDays check.


        // 3. Fetch necessary data (entries for the target week)
        let entries: [JournalEntry]
        do {
            // Fetch all entries and filter for the specific week
            let allEntries = try databaseService.loadAllJournalEntries()
            // Ensure end date comparison is correct for the full Saturday
            let endOfSaturday = calendar.date(byAdding: .day, value: 1, to: endOfReviewWeek)! // Start of Sunday following the target Saturday
            entries = allEntries.filter { $0.date >= startOfReviewWeek && $0.date < endOfSaturday }
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

        // [11.1] Load other recent insights for context
        var feelContextJSON: String? = nil
        var thinkContextJSON: String? = nil
        var actContextJSON: String? = nil
        var learnContextJSON: String? = nil
        do {
             feelContextJSON = try databaseService.loadLatestInsight(type: "feelInsights")?.jsonData
             thinkContextJSON = try databaseService.loadLatestInsight(type: "thinkInsights")?.jsonData
             actContextJSON = try databaseService.loadLatestInsight(type: "actInsights")?.jsonData
             learnContextJSON = try databaseService.loadLatestInsight(type: "learnInsights")?.jsonData
             print("[WeekInReviewGenerator] Loaded context insights - Feel: \(feelContextJSON != nil), Think: \(thinkContextJSON != nil), Act: \(actContextJSON != nil), Learn: \(learnContextJSON != nil)")
        } catch {
             print("⚠️ [WeekInReviewGenerator] Error loading context insights: \(error)")
             // Proceed without context insights if loading fails
        }

        // 5. Get system prompt (Ensure this exists in SystemPrompts.swift)
        // Pass loaded insight JSON strings to the prompt function
        let systemPrompt = SystemPrompts.weekInReviewPrompt(
            entriesContext: context,
            feelContext: feelContextJSON,
            thinkContext: thinkContextJSON,
            actContext: actContextJSON,
            learnContext: learnContextJSON
        )

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