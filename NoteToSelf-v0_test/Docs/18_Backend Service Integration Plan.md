# Document 18: Backend Service Integration Plan (libSQL Edition)

**Objective:** Integrate essential backend services and logic from the `NoteToSelf0` repository into the `NoteToSelf-v0_test` repository (the UI-first base). This plan focuses on enabling AI chat functionality in `ReflectionsView` and laying the groundwork for AI-generated insights, **using the existing `DatabaseService` and libSQL database in `NoteToSelf-v0_test` as the exclusive persistence layer.** CoreData components from `NoteToSelf0` will **not** be used or migrated.

**Executor Roles:**
*   **AI:** Provides code modifications, identifies files, outlines logic.
*   **Human:** Executes terminal commands, interacts with Xcode GUI, performs testing, handles complex debugging, confirms step completion.

---

## Phase 1: Core Service Integration & Setup

1.  **Backup Project:**
    *   **Action (Human):** Create a full backup of the `NoteToSelf-v0_test` project directory. **Confirm completion.**
    *   **AI:** Wait for confirmation.

2.  **Add OpenAI Dependency:**
    *   **Action (Human):** Verify that the `NoteToSelf-v0_test` project **does not** already have an OpenAI SDK dependency. If not present, add the `swift-openai-responses` package (URL: `https://github.com/m1guelpf/swift-openai-responses.git`, minimum version `0.1.1` or latest stable) via Xcode's Swift Package Manager. **Confirm package is added or already existed.**
    *   **AI:** Wait for confirmation.

3.  **Copy Core Backend Files (Excluding Persistence):**
    *   **Action (AI):** Identify the following files from `NoteToSelf0` and provide their complete content. **Crucially, do *not* include `Persistence.swift`, `PersistenceController+Preview.swift`, or the `.xcdatamodeld` file.**
        *   `NoteToSelf/Configuration.swift`
        *   `NoteToSelf/GPT4ReflectionsService.swift`
        *   `NoteToSelf/SystemPrompts.swift`
        *   `NoteToSelf/Services/SubscriptionManager.swift`
    *   **Action (Human):**
        *   Within the `NoteToSelf-v0_test/NoteToSelf_v0_test/` directory structure, create folders if they don't exist: `Services`, `Configuration`, `Prompts`.
        *   Create new Swift files with the corresponding names (`Configuration.swift`, `GPT4ReflectionsService.swift`, `SystemPrompts.swift`, `SubscriptionManager.swift`) inside the appropriate folders.
        *   Paste the exact code provided by the AI into these files.
        *   Ensure the `OpenAI` module (from the `swift-openai-responses` package) is correctly imported in `GPT4ReflectionsService.swift`.
        *   Create a `Config.plist` file in the `NoteToSelf-v0_test` project root (or configure environment variables as per Doc 12). Add this file to your `.gitignore`. Populate it with your `OPENAI_API_KEY`. **Confirm file creation and key addition.**
        *   Add the newly created Swift files and the `Config.plist` to the `NoteToSelf-v0_test` target in Xcode.

4.  **Initial Build & Dependency Check:**
    *   **Action (Human):** Build the project (Cmd+B). Expect potential errors if the OpenAI package wasn't added correctly or if there are minor syntax differences. Resolve these basic compilation errors. **Confirm successful build.**
    *   **AI:** Wait for confirmation or error details. Provide basic troubleshooting if needed (e.g., confirming import statements, package resolution).

---

## Phase 2: Integrate OpenAI Service into ChatManager (Using libSQL)

1.  **Refactor `ChatManager.swift` for AI Integration:**
    *   **Action (AI):** Provide a modified version of `ChatManager.swift` for `NoteToSelf-v0_test`. This new version **must preserve the existing libSQL interaction via `DatabaseService`** while integrating the AI logic. Key changes will include:
        *   Adding an instance variable for `GPT4ReflectionsService.shared`.
        *   Modifying the function that handles sending user messages (likely evolving `addMessage` or creating a new `sendUserMessageToAI`). This function *must* perform the following sequence:
            1.  Save the user's `ChatMessage` to libSQL using `databaseService.saveChatMessage` (as it likely already does).
            2.  Update the local `@Published` messages array.
            3.  Set `@Published var isTyping: Bool = true`.
            4.  **Asynchronously call `GPT4ReflectionsService.sendMessage`**, passing the user message content and the appropriate system prompt from `SystemPrompts.swift`.
            5.  Upon receiving the AI response:
                *   Create an assistant `ChatMessage` object.
                *   Save the assistant's `ChatMessage` to libSQL using `databaseService.saveChatMessage`.
                *   Update the local `@Published` messages array.
                *   Set `@Published var isTyping: Bool = false`.
            6.  Include robust `do-catch` blocks for the API call, logging errors and setting `isTyping = false` in the `catch` block.
        *   Ensure `ChatManager` loads existing messages from libSQL on initialization using `databaseService.loadAllChats` (as it already should based on the last commit).
    *   **Action (Human):** Carefully replace the content of `NoteToSelf-v0_test/ChatManager.swift` with the provided code. Review the changes to understand how AI calls are integrated alongside the existing libSQL operations.

2.  **Update `ReflectionsView.swift` to Use Enhanced `ChatManager`:**
    *   **Action (AI):** Provide the necessary modifications to `ReflectionsView.swift` to:
        *   Ensure the "Send" button correctly calls the updated `ChatManager` function (e.g., `sendUserMessageToAI`) to trigger both persistence *and* the AI response cycle.
        *   Ensure the UI correctly observes the `isTyping` state from `ChatManager` to show/hide the typing indicator.
        *   **Remove the old simulated `generateResponse` function** entirely.
    *   **Action (Human):** Apply the modifications to `ReflectionsView.swift`.

3.  **Testing Phase 2:**
    *   **Action (Human):** Run the app on a simulator or device. Navigate to `ReflectionsView`.
    *   **Verification Points:**
        *   Send a message. Does the user message appear instantly in the UI?
        *   Does the typing indicator appear shortly after sending?
        *   Does an AI response appear after a reasonable delay (network + generation time)?
        *   Close and restart the app. Are both the user message *and* the AI response loaded correctly from the libSQL database via `ChatManager`?
        *   Check the Xcode console for logs indicating successful API calls or specific errors from `GPT4ReflectionsService` or `ChatManager`.
    *   **Report:** Confirm success or provide detailed error messages/descriptions of failures.
    *   **AI:** Wait for testing feedback.

---

## Phase 3: Implement RAG for Reflections Context (Using libSQL Vector Search)

1.  **Enhance `ChatManager` Message Sending Logic for RAG:**
    *   **Action (AI):** Provide further modifications to the `ChatManager` function responsible for sending messages to the AI (identified in Phase 2). **Inside the `Task` block**, *before* calling `GPT4ReflectionsService.sendMessage`:
        *   Add logic to call `generateEmbedding` (the existing helper in `DatabaseService.swift`) on the user's message text.
        *   If an embedding is successfully generated:
            *   Use `async let` to concurrently call:
                *   `databaseService.findSimilarJournalEntries(to: queryEmbedding, limit: 3)`
                *   `databaseService.findSimilarChatMessages(to: queryEmbedding, limit: 5)`
            *   `try await` the results of both database calls.
            *   Format the retrieved `JournalEntry` and `ChatMessage` results into a concise context string (e.g., "Context from past entries:\n- Entry 1...\nContext from past chats:\n- User: ...\n- AI: ..."). Limit the length to avoid excessive token usage.
            *   Prepend this context string to the user message text that will be passed to `GPT4ReflectionsService.sendMessage`.
        *   If embedding fails or DB search fails (use `catch`), log the error and proceed with the API call *without* the RAG context.
    *   **Action (Human):** Apply the RAG context retrieval modifications carefully within the specified function in `ChatManager.swift`. Add `print` statements if needed to observe the retrieved context.

2.  **Testing Phase 3:**
    *   **Action (Human):**
        *   Ensure the libSQL database contains a variety of journal entries and chat messages (add some manually if needed for testing).
        *   Run the app and navigate to `ReflectionsView`.
        *   Send messages that are semantically similar to content in your existing journal entries or chat history.
    *   **Verification Points:**
        *   Check console logs (add `print` statements in `ChatManager`'s RAG logic) to confirm:
            *   Embeddings are being generated for user messages.
            *   `databaseService.findSimilar...` functions are being called.
            *   Relevant context strings are being constructed and prepended to the prompt sent to the OpenAI API.
        *   Observe the AI's responses. Do they appear more informed or relevant based on the retrieved context compared to Phase 2? (This is subjective but look for signs).
    *   **Report:** Confirm context retrieval is happening (based on logs) and share observations on response quality. Report any errors encountered during embedding or DB search.
    *   **AI:** Wait for testing feedback.

---

## Phase 4: Integrate Subscription Gating

1.  **Integrate `SubscriptionManager` Logic:**
    *   **Action (AI):** Provide specific code snippets demonstrating how to:
        *   Ensure `SubscriptionManager.shared` is accessible where needed (e.g., potentially making `AppState` hold an instance or accessing the singleton directly).
        *   Modify `ChatManager`'s message sending function: Before initiating the API call (`Task`), check `SubscriptionManager.shared.isUserSubscribed`. If `false`, check a `dailyFreeMessageCount` (implement this counter within `ChatManager`, ensuring it resets daily, perhaps checking against `UserDefaults` for the last reset date). If the limit is reached, return early or throw an error that `ReflectionsView` can catch. If the message proceeds (either subscribed or within limit), increment the counter for free users.
        *   Modify `ReflectionsView`: Add state to handle the "limit reached" scenario (e.g., `@State private var showSubscriptionAlert = false`). Catch the error/signal from `ChatManager` and set this state to true to trigger the `showingSubscriptionPrompt` alert.
        *   Modify `InsightsView`: For any insight card designated as "premium", wrap its display logic with `if SubscriptionManager.shared.isUserSubscribed { ... } else { // Show locked state UI }`. Identify 1-2 cards (e.g., Recommendations) to apply this to initially.
    *   **Action (Human):** Apply the modifications to `AppState.swift` (if needed), `ChatManager.swift`, `ReflectionsView.swift`, and `InsightsView.swift`. Implement the daily counter logic within `ChatManager`.

2.  **Update `SettingsView.swift` for Subscription Control:**
    *   **Action (AI):** Provide a revised `SettingsView.swift` (building on the `v0_test` version) that:
        *   Displays the current subscription status by reading `SubscriptionManager.shared.isUserSubscribed`.
        *   Includes buttons that call `SubscriptionManager.shared.subscribeMonthly()` and `SubscriptionManager.shared.restorePurchase()`.
        *   Includes the debug button calling `SubscriptionManager.shared.unsubscribeDebug()`.
    *   **Action (Human):** Replace the content of `NoteToSelf-v0_test/SettingsView.swift` with the provided code.

3.  **Testing Phase 4:**
    *   **Action (Human):** Run the app.
    *   **Verification Points:**
        *   **Free User:** Send messages in `ReflectionsView`. Confirm the daily limit (e.g., 3 messages) is enforced and the correct alert appears upon exceeding it. Check `InsightsView` - confirm designated premium cards show a locked state.
        *   **Subscribe:** Go to `SettingsView`, tap the debug "Subscribe" button.
        *   **Premium User:** Return to `ReflectionsView`. Confirm the message limit is now bypassed. Go to `InsightsView`. Confirm premium cards are now unlocked.
        *   **Unsubscribe:** Go to `SettingsView`, tap the debug "Unsubscribe" button. Re-verify free user limitations in Reflections and Insights.
    *   **Report:** Confirm all gating scenarios work as expected.
    *   **AI:** Wait for testing feedback.

---

## Phase 5: Implement AI Insight Generation (Foundation using libSQL)

1.  **Define Initial Insight Task:**
    *   **Action (AI & Human):** Agree on **one specific insight** to implement first (e.g., AI-generated Weekly Summary based on the last 7 days of entries).

2.  **Create Insight Generation Logic:**
    *   **Action (AI):** Provide a new **asynchronous function**, potentially within `GPT4ReflectionsService` or a new `InsightGenerationService.swift`. This function must:
        *   Accept necessary data retrieved from libSQL (e.g., `[JournalEntry]` for the week).
        *   Use a specific, tailored prompt from `SystemPrompts.swift` (e.g., a new `weeklySummaryPrompt`).
        *   Call the OpenAI API (`GPT4ReflectionsService.sendMessage` or similar).
        *   Return the generated insight text (`String`) or handle errors.
    *   **Action (Human):** Create the new service file if needed, and add the provided insight generation function. Define the new system prompt in `SystemPrompts.swift`.

3.  **Integrate Insight Generation into `InsightsView`:**
    *   **Action (AI):** Provide code modifications for `InsightsView.swift`:
        *   Add `@State` variables for the generated insight text (e.g., `@State private var weeklySummaryText: String? = nil`) and loading state (`@State private var isLoadingSummary = false`).
        *   Create an asynchronous function within `InsightsView` (e.g., `generateWeeklySummary()`). This function will:
            1.  Set `isLoadingSummary = true`.
            2.  Call `DatabaseService` to fetch the required `JournalEntry` data (e.g., last 7 days). **Ensure this uses libSQL, not CoreData.**
            3.  Call the new insight generation function (from step 2) with the fetched data.
            4.  On success, update the `@State var weeklySummaryText` with the result.
            5.  Set `isLoadingSummary = false` (in a `finally` block or both `do` and `catch`).
            6.  Include a check for `SubscriptionManager.shared.isUserSubscribed` *before* fetching data/calling the AI. If not subscribed, do not proceed and ensure the UI shows a locked state.
        *   Modify the relevant insight card (e.g., `WeeklySummaryInsightCard`) to:
            *   Display a `ProgressView()` if `isLoadingSummary` is true.
            *   Display the `weeklySummaryText` if it's not nil.
            *   Display a placeholder or "Tap to generate" button if `weeklySummaryText` is nil and not loading.
            *   Display a "Premium Feature" locked state if not subscribed.
        *   Call `generateWeeklySummary()` when the view appears (`.onAppear`) or via a dedicated button tap, depending on the desired UX.
    *   **Action (Human):** Apply the modifications to `InsightsView.swift` and potentially the relevant insight card's Swift file.

4.  **Testing Phase 5:**
    *   **Action (Human):** Run the app. Ensure you have journal entries for the relevant period (e.g., last 7 days).
    *   **Verification Points:**
        *   **Free User:** Navigate to `InsightsView`. Confirm the specific insight card shows its locked/premium state.
        *   **Subscribe:** Use the debug button in Settings.
        *   **Premium User:** Navigate to `InsightsView`.
        *   Confirm the insight generation is triggered (on appear or button tap).
        *   Confirm a loading indicator is shown while the AI generates the insight.
        *   Confirm the generated text appears correctly within the card upon completion.
        *   Test error cases (e.g., disconnect network before triggering generation). Does the UI handle the error gracefully (e.g., stops loading, shows an error message)?
    *   **Report:** Confirm insight generation, display, and subscription gating work correctly. Report any errors or unexpected UI states.
    *   **AI:** Wait for testing feedback.

---

## Phase 6: Final Cleanup & Refinement

1.  **Remove Obsolete Code:**
    *   **Action (AI):** Identify any remaining unused code, specifically:
        *   Any CoreData related files (`Persistence.swift`, `.xcdatamodeld`, `JournalEntryEntity.swift` etc.) if they were accidentally included or referenced.
        *   Old data structs from `v0_test` if fully replaced by ObjectBox-compatible models (though current plan uses existing structs with `DatabaseService`).
        *   Any leftover `UserDefaults` code related to chat/journal persistence.
        *   The original `ReflectionsViewModel.swift` from `NoteToSelf0` if its logic is now fully integrated into `ChatManager`.
    *   **Action (Human):** Carefully delete the identified obsolete files and code sections. **Confirm removal.**

2.  **Refine Error Handling:**
    *   **Action (AI):** Review error handling in `ChatManager` (API calls, RAG calls) and the new insight generation logic. Suggest specific improvements for user-facing feedback (e.g., instead of just console logs, update UI state to show "Error generating response. Please try again.").
    *   **Action (Human):** Implement the suggested UI error handling improvements.

3.  **Final Comprehensive Testing:**
    *   **Action (Human):** Perform end-to-end testing of all application features:
        *   Onboarding (if applicable).
        *   Journal CRUD operations (confirming libSQL persistence).
        *   Reflections chat (including RAG context influencing responses and subscription limits).
        *   Insights view (including basic calculations, AI insight generation, and subscription gating).
        *   Settings view (subscription status display and control).
        *   Test edge cases: no network, empty database, rapid inputs.
        *   Test on different device sizes/simulators.
    *   **Report:** Confirm all features function correctly with the integrated backend services and libSQL persistence. Note any final bugs or UI inconsistencies.
    *   **AI:** Wait for final confirmation.

---

This revised plan provides explicit steps for integrating the backend services while ensuring all data operations correctly target the existing libSQL database via `DatabaseService`. It emphasizes replacing CoreData logic entirely and clearly defines the responsibilities for AI and Human execution.