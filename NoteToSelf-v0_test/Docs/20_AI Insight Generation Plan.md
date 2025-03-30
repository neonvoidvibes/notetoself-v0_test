# Document 20: AI Insight Generation Plan (Phase 5 - Tool Calling & Persistence)

**Objective:** Implement AI-generated insights for the **Weekly Summary**, **Mood Trends**, and **Recommendations** cards using OpenAI's Tool Calling feature for reliable structured JSON output. Store these insights in the `libSQL` database, update the corresponding UI cards to display them (handling various states), and make stored insights accessible for RAG context in the Chat Agent.

**Core Pattern:** Each distinct AI-generated insight type will have its own dedicated:
1.  **`Codable` Model:** A Swift struct defining the specific structured data expected (e.g., `WeeklySummaryResult`, `MoodTrendResult`, `RecommendationResult`).
2.  **Tool Definition:** A schema describing the function/tool the AI should call, matching the `Codable` model's structure.
3.  **System Prompt:** Instructions for the AI, including the task and the requirement to call the specific tool.
4.  **Insight Generator:** A dedicated struct (e.g., `WeeklySummaryGenerator`, `MoodTrendGenerator`, `RecommendationGenerator`) responsible for fetching necessary data, handling insufficient data cases, formatting the prompt, defining/providing the tool schema, calling `LLMService`, storing the result, and returning the decoded `Codable` model.
5.  **UI Card:** The corresponding SwiftUI view (e.g., `WeeklySummaryInsightCard`) updated to display different states: Loading, Success (with data from the `Codable` model), Error, and Insufficient Data.

**Prerequisites:**
*   `LLMService` integrated and functional for basic chat.
*   `DatabaseService` correctly loading `JournalEntry` data.
*   `swift-openai-responses` SDK confirmed/adapted to support Tool Calling reliably.
*   RAG context retrieval (without insights) is functional.

**Steps:**

1.  **Define Schemas (Codable Models & Tool Definitions):**
    *   Define `Codable` Swift structs for `WeeklySummaryResult`, `MoodTrendResult`, and `RecommendationResult` in `Models.swift` or `InsightModels.swift`. *Refine fields based on desired output for each.*
    *   Define the corresponding Tool schemas (name, description, parameters) for OpenAI Tool Calling. Place these logically (e.g., within each Generator struct).

2.  **Integrate Insight Storage into Database:**
    *   Modify `DatabaseService.swift`:
        *   Add `CREATE TABLE IF NOT EXISTS GeneratedInsights (id TEXT PK, insightType TEXT, generatedDate INTEGER, relatedStartDate INTEGER, relatedEndDate INTEGER, jsonData TEXT);` to `setupSchemaAndIndexes`.
        *   Implement `func saveGeneratedInsight(type: String, date: Date, jsonData: String, startDate: Date? = nil, endDate: Date? = nil) throws`.
        *   Implement `func loadLatestInsight(type: String) async throws -> (jsonData: String, generatedDate: Date)?`.

3.  **Enhance `LLMService` for Tool Calling:**
    *   Implement or verify the generic `executeToolCall<T: Decodable>(...)` function in `LLMService.swift`. Ensure it correctly uses the SDK's Tool Calling mechanism (passing `tools`, setting `tool_choice`), parses the `tool_calls` response, extracts the arguments JSON, decodes it into type `T`, and handles errors robustly.

4.  **Create Insight Generators:**
    *   Create `InsightGenerators/WeeklySummaryGenerator.swift`, `InsightGenerators/MoodTrendGenerator.swift`, `InsightGenerators/RecommendationGenerator.swift`.
    *   Each generator will:
        *   Inject `LLMService` and `DatabaseService`.
        *   Define its specific Tool schema.
        *   Implement `async func generateAndStore() async throws -> CodableResultType?`:
            *   Fetch necessary `JournalEntry` data. Return `nil` or throw specific error if insufficient.
            *   Format prompt context.
            *   Call `llmService.executeToolCall` forcing the correct tool.
            *   On successful decoding: Encode result to JSON string, call `databaseService.saveGeneratedInsight`, return decoded struct.
            *   Handle errors.
    *   Create corresponding System Prompts instructing tool use for each insight type.

5.  **Integrate Generation Triggering & UI Updates:**
    *   Modify `InsightsView.swift`:
        *   Instantiate the three generators (`WeeklySummaryGenerator`, etc.).
        *   Add `@State` vars for each insight's result (e.g., `summaryResult: WeeklySummaryResult?`) and loading status (e.g., `isLoadingSummary: Bool`).
        *   Create `triggerInsightGeneration()`:
            *   Sets all relevant `isLoading... = true`.
            *   Calls `loadLatestInsight` for each type to populate UI quickly.
            *   Concurrently calls `generateAndStore()` for each generator.
            *   Updates corresponding `@State` result vars upon completion.
            *   Sets `isLoading... = false` on completion/error.
        *   Call `triggerInsightGeneration()` in `.onAppear`.
    *   Modify `WeeklySummaryInsightCard`, `MoodTrendsInsightCard`, `RecommendationsInsightCard`:
        *   Update inputs to accept the optional `Codable` result struct and `isLoading` boolean.
        *   **Crucially, implement UI logic to clearly display Loading, Success (with data), Error, and Insufficient/No Data states.**

6.  **Enhance Chat Agent RAG:**
    *   Modify `ChatManager.sendUserMessageToAI`:
        *   Inside the RAG `Task`, *after* finding similar entries/messages, add `await databaseService.loadLatestInsight(...)` calls for relevant insight types (summary, trends, recommendations).
        *   If insights are loaded successfully, decode the `jsonData`, format a concise summary, and append it to the `contextString` passed to the LLM.

**Testing Focus:**
*   Verify `InsightsView` loading/error/empty/success states for each AI card.
*   Confirm successful insight generation, JSON decoding, and DB saving via logs.
*   Ensure UI cards display the structured data correctly.
*   Check `GeneratedInsights` table for saved data.
*   Test if the Chat Agent (`ReflectionsView`) receives and uses context from stored insights.
*   Test behavior when insufficient journal data exists for generation.
