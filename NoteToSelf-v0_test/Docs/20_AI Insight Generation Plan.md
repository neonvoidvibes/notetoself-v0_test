# Document 20: AI Insight Generation Plan (Phase 5 - Tool Calling)

**Objective:** Implement AI-generated insights using OpenAI's Tool Calling feature for reliable structured JSON output. This leverages the existing `LLMService`, `DatabaseService`, and `SystemPrompts`. We will use a **Weekly Summary** as the initial example insight, but the pattern established here should be followed for *any* future AI-generated insight.

**Core Pattern:** Each distinct insight type (e.g., Weekly Summary, Mood Correlation, Topic Analysis) will have its own dedicated:
1.  **`Codable` Model:** A Swift struct defining the specific structured data expected from the AI (e.g., `WeeklySummaryResult`).
2.  **Tool Definition:** A schema describing the function/tool the AI should call, matching the `Codable` model's structure.
3.  **System Prompt:** Instructions for the AI, including the task and the requirement to call the specific tool.
4.  **Insight Generator:** A dedicated struct (e.g., `WeeklySummaryGenerator`) responsible for fetching necessary data, formatting the prompt, defining/providing the tool schema, calling `LLMService`, and returning the decoded `Codable` model.
5.  **UI Card:** A SwiftUI view component to display the loading state, error state, or the successfully generated insight data from the `Codable` model.

**Prerequisites:**
*   `LLMService` integrated and functional for basic chat.
*   `DatabaseService` correctly loading `JournalEntry` data.
*   `swift-openai-responses` SDK confirmed to support Tool Calling (or willingness to adapt/switch SDK if needed).

**Steps (Using Weekly Summary as Example):**

1.  **Define Insight Model (Example: `WeeklySummaryResult`):**
    *   Define the `Codable` Swift struct `WeeklySummaryResult` in `Models.swift` or a new `InsightModels.swift`.
    *   Include fields like `mainSummary: String`, `keyThemes: [String]`, `moodTrend: String`, `notableQuote: String?`. *(This serves as the example; other insights will have different structs)*.

2.  **Define Tool Schema & Update Prompt (Example: Weekly Summary):**
    *   Define the tool structure for `generate_weekly_summary` required by the chosen SDK, including parameters matching `WeeklySummaryResult`. This definition might reside in `LLMService` or the specific generator.
    *   Update `SystemPrompts.swift` with a `weeklySummaryPrompt` function. This prompt should instruct the model to analyze provided entry snippets and *call the `generate_weekly_summary` tool* with the results. *(Other insights will have their own specific prompts and tool names)*.

3.  **Enhance `LLMService` for Tool Calling:**
    *   Add a new async function like `executeToolCall<T: Decodable>(systemPrompt: String, userMessage: String, toolDefinition: ToolDefinitionStructure, toolNameToCall: String) async throws -> T` (exact signature depends on SDK).
    *   This function must:
        *   Use the SDK's mechanism to make a chat completion request, providing the `tools` definition and forcing the call to `toolNameToCall` via the `tool_choice` parameter.
        *   Parse the `tool_calls` array from the API response.
        *   Extract the JSON arguments string for the specified tool call.
        *   Decode the arguments string into the expected `Decodable` type `T`.
        *   Include robust error handling for API errors, missing tool calls, malformed arguments, and decoding failures. *(This function will be generic and reusable by all insight generators)*.

4.  **Create Insight Generator (Example: `WeeklySummaryGenerator`):**
    *   Create `InsightGenerators/WeeklySummaryGenerator.swift`. *(Future insights like Mood Correlation would have `InsightGenerators/MoodCorrelationGenerator.swift`, etc.)*
    *   Inject `LLMService` dependency.
    *   Define the specific tool structure for `generate_weekly_summary` (if not defined globally in `LLMService`).
    *   Implement `async func generate(for entries: [JournalEntry]) async throws -> WeeklySummaryResult`:
        *   Format relevant `entries` into a context string.
        *   Call `llmService.executeToolCall` with the appropriate prompt, context, tool definition, and forcing the `generate_weekly_summary` tool choice.
        *   Return the successfully decoded `WeeklySummaryResult`.

5.  **Update `InsightsView` and UI Card (Example: `WeeklySummaryInsightCard`):**
    *   In `InsightsView.swift`:
        *   Add `@State` vars for the specific insight: `summaryResult: WeeklySummaryResult?`, `isLoadingSummary: Bool = false`. *(Add similar state vars for each new insight)*.
        *   Instantiate the specific generator: `WeeklySummaryGenerator`. *(Instantiate other generators as needed)*.
        *   Create `async func triggerWeeklySummaryGeneration()` to handle loading state, call the specific generator, update state variables, and manage errors. *(Create similar trigger functions for other insights)*.
        *   Call this function via `.onAppear` or a button.
    *   In `WeeklySummaryInsightCard.swift` *(or a new card file for a new insight)*:
        *   Modify input to accept the specific result type (`summaryResult: WeeklySummaryResult?`) and `isLoading: Bool`.
        *   Implement UI logic to show `ProgressView` when loading, an error/empty state if the result is nil (and not loading), or display the fields from the specific result struct when available.

6.  **Testing (Example: Weekly Summary):**
    *   Verify loading indicators function correctly for the Weekly Summary card.
    *   Confirm successful tool calls (`generate_weekly_summary`) and JSON decoding via console logs.
    *   Ensure the `WeeklySummaryInsightCard` displays the structured data appropriately.
    *   Test error handling scenarios.
    *   Test subscription gating integration (when Phase 4 is implemented).

**Future Scalability:** This pattern (Specific Model -> Specific Prompt -> Specific Tool Definition -> Specific Generator -> Specific UI Card) provides a clear, modular, and repeatable template for adding diverse AI-powered insights in the future without creating monolithic components.
