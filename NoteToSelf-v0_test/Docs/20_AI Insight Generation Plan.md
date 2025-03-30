# Document 20: AI Insight Generation Plan (Phase 5 - Tool Calling)

**Objective:** Implement AI-generated insights (starting with a Weekly Summary) using OpenAI's Tool Calling feature for reliable structured JSON output. This leverages the existing `LLMService`, `DatabaseService`, and `SystemPrompts`.

**Prerequisites:**
*   `LLMService` integrated and functional for basic chat.
*   `DatabaseService` correctly loading `JournalEntry` data.
*   `swift-openai-responses` SDK confirmed to support Tool Calling (or willingness to adapt/switch SDK if needed).

**Steps:**

1.  **Define `WeeklySummaryResult` Model:**
    *   Define the `Codable` Swift struct `WeeklySummaryResult` in `Models.swift` or a new `InsightModels.swift`.
    *   Include fields like `mainSummary: String`, `keyThemes: [String]`, `moodTrend: String`, `notableQuote: String?`.

2.  **Define Tool Schema & Update Prompt:**
    *   Define the tool structure for `generate_weekly_summary` required by the chosen SDK, including parameters matching `WeeklySummaryResult`. This definition might reside in `LLMService` or the specific generator.
    *   Update `SystemPrompts.swift` with a `weeklySummaryPrompt` function. This prompt should instruct the model to analyze provided entry snippets and *call the `generate_weekly_summary` tool* with the results.

3.  **Enhance `LLMService` for Tool Calling:**
    *   Add a new async function like `executeToolCall<T: Decodable>(systemPrompt: String, userMessage: String, toolDefinition: ToolDefinitionStructure, toolNameToCall: String) async throws -> T` (exact signature depends on SDK).
    *   This function must:
        *   Use the SDK's mechanism to make a chat completion request, providing the `tools` definition and forcing the call to `toolNameToCall` via the `tool_choice` parameter.
        *   Parse the `tool_calls` array from the API response.
        *   Extract the JSON arguments string for the specified tool call.
        *   Decode the arguments string into the expected `Decodable` type `T`.
        *   Include robust error handling for API errors, missing tool calls, malformed arguments, and decoding failures.

4.  **Create `WeeklySummaryGenerator`:**
    *   Create `InsightGenerators/WeeklySummaryGenerator.swift`.
    *   Inject `LLMService` dependency.
    *   Define the specific tool structure for `generate_weekly_summary` (if not defined globally in `LLMService`).
    *   Implement `async func generate(for entries: [JournalEntry]) async throws -> WeeklySummaryResult`:
        *   Format relevant `entries` into a context string.
        *   Call `llmService.executeToolCall` with the appropriate prompt, context, tool definition, and forcing the `generate_weekly_summary` tool choice.
        *   Return the successfully decoded `WeeklySummaryResult`.

5.  **Update `InsightsView` and `WeeklySummaryInsightCard`:**
    *   In `InsightsView.swift`:
        *   Add `@State` vars: `summaryResult: WeeklySummaryResult?`, `isLoadingSummary: Bool = false`.
        *   Instantiate `WeeklySummaryGenerator`.
        *   Create `async func triggerWeeklySummaryGeneration()` to handle loading state, call the generator, update state variables, and manage errors.
        *   Call this function via `.onAppear` or a button.
    *   In `WeeklySummaryInsightCard.swift`:
        *   Modify input to accept `summaryResult: WeeklySummaryResult?` and `isLoading: Bool`.
        *   Implement UI logic to show `ProgressView` when loading, an error/empty state if `summaryResult` is nil (and not loading), or display the fields (`result.mainSummary`, `result.keyThemes`, etc.) from the `summaryResult` when available.

6.  **Testing:**
    *   Verify loading indicators function correctly.
    *   Confirm successful tool calls and JSON decoding via console logs.
    *   Ensure the `WeeklySummaryInsightCard` displays the structured data appropriately.
    *   Test error handling scenarios (e.g., network issues, insufficient data for summary).
    *   Test subscription gating integration (if Phase 4 were implemented) to ensure the insight is only generated/displayed for premium users.

**Future Scalability:** This pattern (Model -> Prompt -> Tool Definition -> Generator -> UI Card) provides a clear template for adding more AI-powered insights in the future.
