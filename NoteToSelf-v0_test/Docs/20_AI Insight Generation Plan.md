# Document 20: AI Insight Generation Plan (Phase 5 - JSON Prompting & Persistence)

**Objective:** Implement AI-generated insights for the **Weekly Summary**, **Mood Trends**, and **Recommendations** cards using OpenAI's models, storing the results in the `libSQL` database. The UI will display the latest stored insight, and regeneration will be triggered primarily upon new `JournalEntry` creation to conserve LLM token usage. Stored insights will also be accessible for RAG context in the Chat Agent.

**Important Note on Approach (Tool Calling vs. JSON Prompting):**
Ideally, generating structured data like insights would use OpenAI's **Tool Calling** feature. This allows defining a function schema (the "tool") and instructing the model to "call" it, resulting in a reliably formatted JSON output matching the schema.

However, the current `swift-openai-responses` SDK used in `LLMService` does not appear to offer straightforward support for the necessary `tools` and `tool_choice` API parameters.

Therefore, this plan adopts a **workaround**:
1.  **Strong Prompting:** We will craft specific system prompts (in `SystemPrompts.swift`) that explicitly instruct the model to respond *ONLY* with a valid JSON object matching a defined structure.
2.  **Response Parsing:** The `LLMService.generateStructuredOutput` function will request this JSON via the prompt, receive the raw text response, attempt to clean any extraneous text or markdown formatting (like ```json), and then decode the cleaned string into our target Swift `Codable` structs.

This approach relies heavily on the model's ability to follow JSON formatting instructions precisely. It may require more careful prompt engineering and robust response cleaning than true Tool Calling.

**Core Pattern:** Each distinct AI-generated insight type will have its own dedicated:
1.  **`Codable` Model:** A Swift struct defining the specific structured data expected (e.g., `WeeklySummaryResult`, `MoodTrendResult`, `RecommendationResult`).
2.  **System Prompt:** Instructions for the AI, including the task and the requirement to call the specific tool. *Crucially, this prompt must explicitly demand JSON-only output matching the Codable model's structure.*
3.  **Insight Generator:** A dedicated struct (e.g., `WeeklySummaryGenerator`) responsible for fetching necessary data, handling insufficient data cases, formatting the prompt, calling `LLMService.generateStructuredOutput`, storing the result, and returning the decoded `Codable` model.
4.  **UI Card:** The corresponding SwiftUI view (e.g., `WeeklySummaryInsightCard`) updated to display different states: Loading (briefly on initial load/refresh), Success (with data from the *stored* `Codable` model), Error (if loading fails), and Insufficient/No Data.

**Prerequisites:**
*   `LLMService` integrated and functional for basic chat.
*   `DatabaseService` correctly loading/saving `JournalEntry` data.
*   `swift-openai-responses` SDK confirmed/adapted for the JSON prompting approach.
*   RAG context retrieval (without insights) is functional.

**Steps:**

1.  **Define Schemas (Codable Models):**
    *   Define `Codable` Swift structs for `WeeklySummaryResult`, `MoodTrendResult`, and `RecommendationResult` in `Models.swift` or `InsightModels.swift`.

2.  **Integrate Insight Storage into Database:**
    *   Modify `DatabaseService.swift`:
        *   Add `CREATE TABLE IF NOT EXISTS GeneratedInsights (id TEXT PK, insightType TEXT UNIQUE, generatedDate INTEGER, relatedStartDate INTEGER, relatedEndDate INTEGER, jsonData TEXT);` to `setupSchemaAndIndexes`. *(Already completed)*.
        *   Implement `func saveGeneratedInsight(type: String, date: Date, jsonData: String, startDate: Date? = nil, endDate: Date? = nil) throws` using `INSERT OR REPLACE`. *(Already completed)*.
        *   Implement `func loadLatestInsight(type: String) async throws -> (jsonData: String, generatedDate: Date)?`. *(Already completed)*.

3.  **Enhance `LLMService` for Structured JSON via Prompting:**
    *   Modify `LLMService.swift` to ensure the `generateStructuredOutput<T: Decodable>(...)` function works effectively with the JSON prompting workaround.
    *   **Key Logic:**
        *   Construct a combined prompt that includes the system instructions (demanding JSON-only output matching the desired structure) and the user's input data (e.g., formatted journal entries).
        *   Call the underlying SDK's chat completion method (e.g., `openAIClient.create(request)`).
        *   Receive the raw text response.
        *   **Clean the response:** Aggressively remove any leading/trailing whitespace and potential markdown code block markers (e.g., ```json ... ```).
        *   **Validate:** Ensure the cleaned string is not empty.
        *   **Decode:** Attempt to decode the cleaned string using `JSONDecoder` into the target `Codable` type (`T`).
        *   Handle potential API errors, cleaning errors (e.g., empty string after cleaning), and JSON decoding errors robustly, providing informative error messages.
    *   *(This step was largely completed in the previous turn, ensuring the implementation matches this description).*

4.  **Create Insight Generators:**
    *   Create `InsightGenerators/WeeklySummaryGenerator.swift`, `InsightGenerators/MoodTrendGenerator.swift`, `InsightGenerators/RecommendationGenerator.swift`.
    *   Each generator will:
        *   Inject `LLMService` and `DatabaseService`.
        *   Implement `async func generateAndStoreIfNeeded() async`:
            *   *(Optional but Recommended for token saving):* Check if regeneration is necessary (e.g., based on `loadLatestInsight` date vs. amount of new `JournalEntry` data since then). If not needed, return early.
            *   Fetch necessary `JournalEntry` data (e.g., last 7 days for weekly summary). If insufficient, log and return.
            *   Format prompt context (e.g., concatenate relevant entry texts).
            *   Get the appropriate system prompt from `SystemPrompts.swift` (which *must* demand JSON-only output).
            *   Call `llmService.generateStructuredOutput` passing the system prompt, formatted context, and the target `Codable` struct type (e.g., `WeeklySummaryResult.self`).
            *   On successful decoding: Encode the resulting struct back to a JSON string using `JSONEncoder`.
            *   Call `databaseService.saveGeneratedInsight` with the type identifier (e.g., "weeklySummary"), current date, and the encoded JSON string.
            *   Handle errors during data fetching, generation, encoding, or saving.
    *   Create corresponding System Prompts in `SystemPrompts.swift` instructing for JSON-only output matching the specific `Codable` structures. *(Partially completed, needs prompts for Mood Trends & Recommendations)*.

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
        *   Implement `triggerAllInsightGenerations()` (perhaps in `AppState` or a new `InsightService`): Instantiate generators (passing dependencies like `LLMService.shared`, `DatabaseService`) and call `generateAndStoreIfNeeded()` for each.
    *   **Loading & Display:** Modify `InsightsView.swift`:
        *   Add `@State` vars for each insight's *stored* result (e.g., `storedSummaryResult: WeeklySummaryResult?`, `storedSummaryDate: Date?`) and potentially a brief loading indicator state (`isLoadingInsights: Bool`).
        *   Inject `DatabaseService`.
        *   Create `loadStoredInsights()` function:
            *   Sets `isLoadingInsights = true`.
            *   Concurrently calls `databaseService.loadLatestInsight` for each type using `TaskGroup` or `async let`.
            *   Updates corresponding `@State` result vars upon completion. Decodes JSON into the Codable structs here. Handle decoding errors.
            *   Sets `isLoadingInsights = false`.
        *   Call `loadStoredInsights()` in `.onAppear`.
    *   Modify `WeeklySummaryInsightCard`, `MoodTrendsInsightCard`, `RecommendationsInsightCard`:
        *   Update inputs to accept the optional *stored* `Codable` result struct and its generation date.
        *   Display the data from the stored result. Show an empty/placeholder state if no stored insight exists yet. Briefly show a loading indicator only during the initial `.onAppear` load. The card *doesn't* trigger generation itself.

6.  **Enhance Chat Agent RAG:**
    *   Modify `ChatManager.sendUserMessageToAI`:
        *   Inside the RAG `Task`, call `databaseService.loadLatestInsight(...)` for relevant types (e.g., "weeklySummary").
        *   If an insight is loaded, decode its `jsonData` into the corresponding `Codable` struct.
        *   Format a concise summary from the decoded insight struct (e.g., "Recent summary mentioned themes: [themes]. Mood trend was [trend].").
        *   Append this formatted insight summary to the `contextString` passed to the LLM.

**Testing Focus:**
*   Verify insights are generated *after* saving a new journal entry (check logs, DB).
*   Verify `InsightsView` loads and displays the *latest stored* insights on appear.
*   Verify UI cards show appropriate states (data present, no data yet).
*   Confirm Chat Agent uses stored insights in its context.
*   Monitor token usage (conceptually) - ensure generation isn't happening excessively on every view load.
*   **Crucially:** Test the reliability of the JSON prompting. Check for decoding errors in the console and ensure the LLM consistently returns *only* the requested JSON structure. Refine prompts if necessary.
