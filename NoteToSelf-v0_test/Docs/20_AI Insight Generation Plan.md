# Document 20: AI Insight Generation Plan (Phase 5 - Tool Calling & Persistence)

**Objective:** Implement AI-generated insights for the **Weekly Summary**, **Mood Trends**, and **Recommendations** cards using OpenAI's Tool Calling feature. Store these insights in the `libSQL` database, update UI cards to display the latest stored insight, trigger regeneration primarily upon new `JournalEntry` creation, and make stored insights accessible for RAG context in the Chat Agent. This approach aims to keep insights relatively fresh while conserving LLM token usage.

**Core Pattern:** Each distinct AI-generated insight type will have its own dedicated:
1.  **`Codable` Model:** A Swift struct defining the specific structured data expected (e.g., `WeeklySummaryResult`, `MoodTrendResult`, `RecommendationResult`).
2.  **Tool Definition:** A schema describing the function/tool the AI should call, matching the `Codable` model's structure.
3.  **System Prompt:** Instructions for the AI, including the task and the requirement to call the specific tool.
4.  **Insight Generator:** A dedicated struct (e.g., `WeeklySummaryGenerator`) responsible for fetching necessary data, handling insufficient data cases, formatting the prompt, defining/providing the tool schema, calling `LLMService`, storing the result, and returning the decoded `Codable` model.
5.  **UI Card:** The corresponding SwiftUI view (e.g., `WeeklySummaryInsightCard`) updated to display different states: Loading (briefly on initial load/refresh), Success (with data from the *stored* `Codable` model), Error (if loading fails), and Insufficient/No Data.

**Prerequisites:**
*   `LLMService` integrated and functional for basic chat.
*   `DatabaseService` correctly loading/saving `JournalEntry` data.
*   `swift-openai-responses` SDK confirmed/adapted to support Tool Calling reliably.
*   RAG context retrieval (without insights) is functional.

**Steps:**

1.  **Define Schemas (Codable Models & Tool Definitions):**
    *   Define `Codable` Swift structs for `WeeklySummaryResult`, `MoodTrendResult`, and `RecommendationResult` in `Models.swift` or `InsightModels.swift`.
    *   Define the corresponding Tool schemas for OpenAI Tool Calling (likely within each Generator struct).

2.  **Integrate Insight Storage into Database:**
    *   Modify `DatabaseService.swift`:
        *   Add `CREATE TABLE IF NOT EXISTS GeneratedInsights (id TEXT PK, insightType TEXT UNIQUE, generatedDate INTEGER, relatedStartDate INTEGER, relatedEndDate INTEGER, jsonData TEXT);` to `setupSchemaAndIndexes`. *(Added UNIQUE constraint on insightType to easily replace latest)*.
        *   Implement `func saveGeneratedInsight(type: String, date: Date, jsonData: String, startDate: Date? = nil, endDate: Date? = nil) throws`. *(This should likely perform an INSERT OR REPLACE based on insightType)*.
        *   Implement `func loadLatestInsight(type: String) async throws -> (jsonData: String, generatedDate: Date)?`.

3.  **Enhance `LLMService` for Tool Calling:**
    *   Implement or verify the generic `executeToolCall<T: Decodable>(...)` function in `LLMService.swift`, ensuring it handles Tool Calling via the SDK correctly.

4.  **Create Insight Generators:**
    *   Create `InsightGenerators/WeeklySummaryGenerator.swift`, `InsightGenerators/MoodTrendGenerator.swift`, `InsightGenerators/RecommendationGenerator.swift`.
    *   Each generator will:
        *   Inject `LLMService` and `DatabaseService`.
        *   Define its specific Tool schema.
        *   Implement `async func generateAndStoreIfNeeded() async`:
            *   *(Optional but Recommended for token saving):* Check if regeneration is necessary (e.g., based on `loadLatestInsight` date vs. amount of new `JournalEntry` data since then). If not needed, return early.
            *   Fetch necessary `JournalEntry` data. If insufficient, log and return.
            *   Format prompt context.
            *   Call `llmService.executeToolCall` forcing the correct tool.
            *   On successful decoding: Encode result to JSON string, call `databaseService.saveGeneratedInsight`.
            *   Handle errors during generation or saving.
    *   Create corresponding System Prompts instructing tool use.

5.  **Integrate Generation Triggering & UI Updates:**
    *   **Triggering:** Modify `JournalView.swift`'s `onSave` closures (for both new and edited entries). *After* successfully saving the `JournalEntry` to the database, trigger the generation process for all relevant insights in the background.
        ```swift
        // Inside the Task where entry is saved to DB...
        try databaseService.saveJournalEntry(...)
        print("✅ Successfully saved/updated journal entry...")
        await MainActor.run { /* Update AppState UI */ }

        // Trigger insight generation asynchronously AFTER saving entry
        Task.detached(priority: .background) {
             await triggerAllInsightGenerations() // Call a new global or AppState function
        }
        ```
        *   Implement `triggerAllInsightGenerations()` (perhaps in `AppState` or as a global func accessible to `JournalView` and `InsightsView`): Instantiate generators and call `generateAndStoreIfNeeded()` for each.
    *   **Loading & Display:** Modify `InsightsView.swift`:
        *   Instantiate the three generators.
        *   Add `@State` vars for each insight's *stored* result (e.g., `storedSummaryResult: WeeklySummaryResult?`, `storedSummaryDate: Date?`) and potentially a brief loading indicator state (`isLoadingInsights: Bool`).
        *   Create `loadStoredInsights()` function:
            *   Sets `isLoadingInsights = true`.
            *   Concurrently calls `loadLatestInsight` for each type using `TaskGroup` or `async let`.
            *   Updates corresponding `@State` result vars upon completion. Decodes JSON into the Codable structs here.
            *   Sets `isLoadingInsights = false`.
        *   Call `loadStoredInsights()` in `.onAppear`.
    *   Modify `WeeklySummaryInsightCard`, `MoodTrendsInsightCard`, `RecommendationsInsightCard`:
        *   Update inputs to accept the optional *stored* `Codable` result struct and its generation date.
        *   Display the data from the stored result. Show an empty/placeholder state if no stored insight exists yet. Briefly show a loading indicator only during the initial `.onAppear` load. The card *doesn't* trigger generation itself.

6.  **Enhance Chat Agent RAG:**
    *   Modify `ChatManager.sendUserMessageToAI`:
        *   Inside the RAG `Task`, call `databaseService.loadLatestInsight(...)` for relevant types.
        *   If insights are loaded, decode `jsonData`, format a summary, and append to `contextString`.

**Testing Focus:**
*   Verify insights are generated *after* saving a new journal entry (check logs, DB).
*   Verify `InsightsView` loads and displays the *latest stored* insights on appear.
*   Verify UI cards show appropriate states (data present, no data yet).
*   Confirm Chat Agent uses stored insights in its context.
*   Monitor token usage (conceptually) - ensure generation isn't happening excessively on every view load.
