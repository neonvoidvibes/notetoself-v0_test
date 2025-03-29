# Document 18: Backend Service Integration Plan (libSQL & Structured Output Edition)

**Objective:** Integrate essential backend services and logic from the `NoteToSelf0` repository into the `NoteToSelf-v0_test` repository (the UI-first base). This plan focuses on enabling AI chat functionality in `ReflectionsView` and laying the groundwork for AI-generated insights, using the existing `DatabaseService` and libSQL database in `NoteToSelf-v0_test` as the exclusive persistence layer. **AI-generated insights will utilize structured JSON output enforced via the OpenAI API's `response_format` parameter.**

**Executor Roles:**
*   **AI:** Provides code modifications, identifies files, outlines logic, defines JSON schemas.
*   **Human:** Executes terminal commands, interacts with Xcode GUI, performs testing, handles complex debugging, confirms step completion, ensures chosen OpenAI SDK supports required features.

**After each phase, always test and validate before continuing with implementing the next phase.**

---

## Phase 1: Core Service Integration & Setup

1.  **Backup Project:**
    *   **Action (Human):** Create a full backup of the `NoteToSelf-v0_test` project directory. **Confirm completion.**
    *   **AI:** Wait for confirmation.

2.  **Add/Verify OpenAI Dependency:**
    *   **Action (Human):** Verify which OpenAI Swift SDK is currently included in `NoteToSelf-v0_test`. If none, add one that **explicitly supports the `response_format` parameter for chat completions (ideally with JSON Schema support)**, such as `SwiftOpenAI` or `MacPaw/OpenAI`. Update the `Package.resolved` if necessary. **Confirm the SDK choice and its support for `response_format`.**
    *   **AI:** Wait for confirmation. *Note: The exact syntax for API calls in later phases will depend on the chosen SDK.*

3.  **Copy Core Backend Files (Excluding Persistence):**
    *   **Action (AI):** Identify the following files from `NoteToSelf0` and provide their complete content. **Do *not* include CoreData-related files.**
        *   `NoteToSelf/Configuration.swift` (Rename to `APIConfiguration.swift` for clarity).
        *   `NoteToSelf/GPT4ReflectionsService.swift` (Rename to `LLMService.swift`).
        *   `NoteToSelf/SystemPrompts.swift`
        *   `NoteToSelf/Services/SubscriptionManager.swift`
    *   **Action (Human):**
        *   Within `NoteToSelf-v0_test/NoteToSelf_v0_test/`, create folders if needed: `Services`, `Configuration`, `Prompts`.
        *   Create new Swift files with the **new names** (`APIConfiguration.swift`, `LLMService.swift`, `SystemPrompts.swift`, `SubscriptionManager.swift`) in the appropriate folders.
        *   Paste the provided code into the respective files.
        *   Ensure the chosen OpenAI SDK module is imported in `LLMService.swift`.
        *   Create/verify `Config.plist` (or environment variables) for `OPENAI_API_KEY` as per `APIConfiguration.swift`. Ensure it's in `.gitignore`. **Confirm key setup.**
        *   Add the new files and `Config.plist` to the `NoteToSelf-v0_test` target.

4.  **Initial Build & Dependency Check:**
    *   **Action (Human):** Build the project (Cmd+B). Resolve basic compilation errors (imports, syntax). **Confirm successful build.**
    *   **AI:** Wait for confirmation or error details.

---

## Phase 2: Integrate LLM Service into ChatManager (Using libSQL)

1.  **Refactor `ChatManager.swift` for AI Integration:**
    *   **Action (AI):** Provide a modified version of `ChatManager.swift`. Key changes:
        *   Inject or instantiate `LLMService.shared`.
        *   Modify the message sending function (e.g., `sendUserMessageToAI`). Sequence:
            1.  Save user message to libSQL (`databaseService.saveChatMessage`).
            2.  Update `@Published` messages.
            3.  Set `isTyping = true`.
            4.  **Asynchronously call `LLMService`'s function for *plain text chat*** (e.g., `generateChatResponse(systemPrompt:, userMessage:)`). This function *will not* use structured output for basic chat.
            5.  On response: Save assistant message to libSQL, update `@Published` messages, set `isTyping = false`.
            6.  Include `do-catch` for API call errors.
        *   Ensure initial message loading uses `databaseService.loadAllChats`.
    *   **Action (Human):** Replace `ChatManager.swift` content. Review the integration.

2.  **Update `ReflectionsView.swift`:**
    *   **Action (AI):** Provide modifications to `ReflectionsView.swift` to:
        *   Ensure "Send" calls the correct `ChatManager` function.
        *   Observe `isTyping` state correctly.
        *   **Remove any old simulated response generation.**
    *   **Action (Human):** Apply modifications.

3.  **Testing Phase 2:**
    *   **Action (Human):** Run app, go to `ReflectionsView`. Send messages.
    *   **Verify:** Correct UI updates, typing indicator, AI responses appear, persistence works after restart, check console logs.
    *   **Report:** Confirm success or provide detailed error descriptions.
    *   **AI:** Wait for feedback.

---

## Phase 3: Implement RAG for Reflections Context (Using libSQL Vector Search)

1.  **Enhance `ChatManager` Message Sending Logic for RAG:**
    *   **Action (AI):** Provide modifications to `ChatManager`'s AI message sending function. *Before* calling the `LLMService`:
        *   Generate embedding for user message (`generateEmbedding`).
        *   If embedding succeeds, concurrently call `databaseService.findSimilarJournalEntries` and `databaseService.findSimilarChatMessages`.
        *   Await results and format into a concise context string.
        *   Prepend context string to the user message passed to `LLMService.generateChatResponse`.
        *   Handle embedding/DB search errors gracefully (proceed without context, log error).
    *   **Action (Human):** Apply modifications to `ChatManager.swift`. Add `print` statements for debugging RAG context if needed.

2.  **Testing Phase 3:**
    *   **Action (Human):** Ensure libSQL DB has varied entries/messages. Send contextually relevant messages in `ReflectionsView`.
    *   **Verify:** Check console logs for embedding generation, DB search calls, and constructed context string. Subjectively assess if AI responses are more context-aware.
    *   **Report:** Confirm context retrieval works (logs) and share observations on response quality. Report errors.
    *   **AI:** Wait for feedback.

---

## Phase 4: Integrate Subscription Gating

*(This phase remains largely the same as the previous version, focusing on integrating `SubscriptionManager`)*

1.  **Integrate `SubscriptionManager` Logic:**
    *   **Action (AI):** Provide code snippets to:
        *   Ensure `SubscriptionManager.shared` is accessible (e.g., via `AppState` or singleton).
        *   Modify `ChatManager`: Check `SubscriptionManager.shared.isUserSubscribed` and daily message count before API calls. Implement daily counter reset logic. Signal "limit reached" via return value or error.
        *   Modify `ReflectionsView`: Catch "limit reached" signal and trigger the `showingSubscriptionPrompt` alert.
        *   Modify `InsightsView`: Wrap premium insight cards/sections in `if SubscriptionManager.shared.isUserSubscribed { ... } else { // Locked UI }`. Designate initial premium cards (e.g., Recommendations).
    *   **Action (Human):** Apply modifications to `AppState.swift` (if needed), `ChatManager.swift`, `ReflectionsView.swift`, and `InsightsView.swift`. Implement the daily counter in `ChatManager`.

2.  **Update `SettingsView.swift`:**
    *   **Action (AI):** Provide revised `SettingsView.swift` showing subscription status from `SubscriptionManager` and buttons calling its (stubbed) `subscribe/restore/unsubscribe` methods.
    *   **Action (Human):** Replace `SettingsView.swift` content.

3.  **Testing Phase 4:**
    *   **Action (Human):** Run app. Test free user limits in Reflections/Insights. Use debug subscribe/unsubscribe buttons in Settings and verify features unlock/lock correctly.
    *   **Report:** Confirm all gating scenarios work.
    *   **AI:** Wait for feedback.

---

## Phase 5: Implement AI Insight Generation (Using Structured JSON Output)

1.  **Define Initial Insight & Data Structure:**
    *   **Action (AI & Human):** Agree on **one specific insight** (e.g., Weekly Summary).
    *   **Action (AI):** Define the **`Codable` Swift struct** representing the desired structured output (e.g., `WeeklySummaryResult` with fields like `mainSummary: String`, `keyThemes: [String]`).
    *   **Action (AI):** Define the corresponding **JSON schema** as a `[String: Any]` dictionary that matches the Swift struct.
    *   **Action (Human):** Create a new file (e.g., `InsightModels.swift`) or add the `Codable` struct definition to `Models.swift`.

2.  **Create Insight Generator:**
    *   **Action (AI):** Provide code for a new file `InsightGenerators/WeeklySummaryGenerator.swift`. This `struct WeeklySummaryGenerator` will:
        *   Accept `LLMService` and `DatabaseService` dependencies via `init`.
        *   Contain the JSON schema dictionary defined in step 1.
        *   Implement an async function `generate(for entries: [JournalEntry]) async throws -> WeeklySummaryResult`. This function will:
            *   Format input `entries` as needed for the prompt.
            *   Construct the specific system prompt (from `SystemPrompts.swift`) **including instructions to respond ONLY in the specified JSON format** and potentially providing the schema or an example within the prompt.
            *   Call a **new function** in `LLMService` (e.g., `generateStructuredOutput(systemPrompt:, userMessage:, jsonSchema:)`) passing the prompt *and* the JSON schema dictionary.
            *   The `LLMService` function (see step 3) will return the decoded Swift struct (`WeeklySummaryResult`).
            *   Return the decoded result. Handle potential errors from the LLM service.
    *   **Action (Human):** Create the `InsightGenerators` folder and the `WeeklySummaryGenerator.swift` file. Paste the provided code. Define the new insight-specific prompt in `SystemPrompts.swift`.

3.  **Update `LLMService.swift` for Structured Output:**
    *   **Action (AI):** Provide modifications to `LLMService.swift` to add a **new function** like:
        ```swift
        // Function signature might vary based on chosen SDK
        func generateStructuredOutput<T: Decodable>(
            systemPrompt: String,
            userMessage: String,
            responseModel: T.Type, // The Codable Swift struct type
            jsonSchema: [String: Any]? // The schema dictionary
        ) async throws -> T
        ```
        *   This function will call the underlying OpenAI SDK's chat completion method, passing the prompts and crucially setting the **`response_format` parameter to use JSON mode, ideally providing the `jsonSchema`** (syntax depends on the SDK).
        *   It will receive the JSON string response from the API.
        *   It will use `JSONDecoder` to decode the response string into the provided `responseModel` type (`T`).
        *   It will return the decoded Swift struct (`T`). Handle API errors and JSON decoding errors appropriately.
    *   **Action (Human):** Apply the modifications to `LLMService.swift`, ensuring the API call syntax matches the chosen SDK's requirements for structured JSON output.

4.  **Integrate Insight Generation into `InsightsView`:**
    *   **Action (AI):** Provide code modifications for `InsightsView.swift`:
        *   Add `@State` variables for the structured result (e.g., `@State private var summaryResult: WeeklySummaryResult? = nil`) and loading state (`@State private var isLoadingSummary = false`).
        *   Instantiate the `WeeklySummaryGenerator`.
        *   Create an async function `generateWeeklySummary()`. This function will:
            1.  Check subscription status. If not subscribed, show locked UI and return.
            2.  Set `isLoadingSummary = true`.
            3.  Fetch required `JournalEntry` data from `DatabaseService`.
            4.  Call `weeklySummaryGenerator.generate(for: entries)`.
            5.  On success, update `@State var summaryResult`.
            6.  Set `isLoadingSummary = false` (in `finally` or `do/catch`). Handle errors by potentially setting an error state.
        *   Modify `WeeklySummaryInsightCard` to:
            *   Accept the `WeeklySummaryResult?` as input.
            *   Display `ProgressView()` if loading.
            *   Display locked state if not subscribed or result is nil (and not loading).
            *   Display different parts of the `summaryResult` (e.g., `result.mainSummary`, `result.keyThemes`) in appropriate UI elements.
        *   Trigger `generateWeeklySummary()` via `.onAppear` or a button.
    *   **Action (Human):** Apply modifications to `InsightsView.swift` and `WeeklySummaryInsightCard.swift`.

5.  **Testing Phase 5:**
    *   **Action (Human):** Run app with relevant journal data.
    *   **Verify:**
        *   **Free User:** Insight card shows locked state.
        *   **Premium User:** Trigger insight generation. Loading indicator shows. Generated insight appears, correctly mapped to UI elements based on the structured JSON (e.g., themes appear as a list). Test error handling (network off).
    *   **Report:** Confirm structured output generation, parsing, UI display, and gating work. Report errors.
    *   **AI:** Wait for feedback.

---

## Phase 6: Final Cleanup & Refinement

1.  **Remove Redundant Code:**
    *   **Action (AI):** Identify any remaining unused code (old data structs, old ViewModels, CoreData remnants).
    *   **Action (Human):** Delete identified obsolete code. **Confirm removal.**

2.  **Refine Error Handling:**
    *   **Action (AI):** Review error handling in `ChatManager`, `LLMService`, and `InsightGenerators`. Suggest specific user-facing UI updates for errors (e.g., showing an alert or inline message in the UI).
    *   **Action (Human):** Implement suggested UI error handling.

3.  **Final Comprehensive Testing:**
    *   **Action (Human):** Perform end-to-end testing of all features: Journaling (libSQL), Reflections (libSQL + RAG + AI + Gating), Insights (libSQL + AI Gen + Gating), Settings (Subscription). Test edge cases and different device sizes.
    *   **Report:** Confirm all features function correctly. Note final bugs/inconsistencies.
    *   **AI:** Wait for final confirmation.

---

This updated plan explicitly incorporates structured JSON output for AI insights, leveraging the `response_format` API parameter for robustness, while ensuring all data persistence relies solely on the existing libSQL `DatabaseService`.