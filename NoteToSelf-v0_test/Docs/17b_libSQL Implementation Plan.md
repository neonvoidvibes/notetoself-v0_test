# Revised Plan: Core libSQL Integration for Data Persistence & RAG

## 1. Aim / Goal

The primary goal is to replace the current in-memory (`AppState`) and `UserDefaults` (`ChatManager`) storage for `JournalEntry` and `Chat` data with a persistent, offline `libSQL` database (`NoteToSelfData_v1.sqlite`). This involves:

1.  **Persisting Data:** Storing all `JournalEntry` and `ChatMessage` data in respective `libSQL` tables.
2.  **Generating & Storing Embeddings:** Creating and storing vector embeddings for entry/message text within the database.
3.  **Establishing Source of Truth:** Making the `libSQL` database the definitive source for all journal and chat history data used throughout the app.
4.  **Backend RAG:** Enabling the `ReflectionsView` AI to retrieve relevant context (similar past entries/messages) from the `libSQL` database using vector search *internally* (no UI changes needed for this specific feature yet).
5.  **Maintaining UI Functionality:** Ensuring the *existing* UI (`JournalView`, `ChatHistoryView`, `ReflectionsView`, filter panels, etc.) continues to function correctly by reading data loaded *from* the database (via `AppState` and `ChatManager`).

**Key Outcome:** A robust, persistent, offline data layer using `libSQL` that stores both structured data and vector embeddings, enabling future features while keeping the current UI functional. User-facing semantic search features are deferred.

## 2. Accomplishments So Far

*   **`libsql-swift` Integrated:** Package added (v0.3.0), builds successfully.
*   **`DatabaseService` Setup:** Class created, initializes DB connection, creates `JournalEntries` and `ChatMessages` tables with correct `FLOAT32(512)` embedding columns, and creates vector indexes. Builds successfully.
*   **Embedding Helpers:** `generateEmbedding` (using `NLEmbedding` for 512 dims) and `embeddingToJson` are functional.
*   **Journal Entry Save/Delete:** `JournalView` successfully saves new/edited entries (with embeddings) to `libSQL` and deletes entries from `libSQL`.

## 3. Upcoming Steps (Focus on Backend & Data Flow)

**Phase 3 (Complete Data Persistence & Migration):**

1.  **Integrate Chat Message Saving:**
    *   **Task:** Modify `ChatManager.addMessage` to:
        *   Inject/access `DatabaseService` (already done via `init`).
        *   Call `generateEmbedding` for the new `ChatMessage.text`.
        *   Call `databaseService.saveChatMessage` to save the message and embedding to the DB. Include error handling.
    *   **(No UI Changes Required for this step)**

2.  **Implement Initial Data Migration:**
    *   **Task:** Add logic (e.g., in `NoteToSelf_v0_testApp.onAppear`) that runs *once*.
    *   This logic iterates through existing `AppState.journalEntries` (sample/in-memory) and `ChatManager.chats` (loaded from UserDefaults).
    *   For each item, call `generateEmbedding` and save it to `libSQL` using `databaseService.saveJournalEntry` / `saveChatMessage`.
    *   Use a `UserDefaults` flag (e.g., `didRunLibSQLMigration_v1`) to prevent re-running. Run in a background `Task`.
    *   **(No UI Changes Required for this step)**

**Phase 4 (Make Database the Source of Truth):**

1.  **Implement Data Loading from DB:**
    *   **Task:** Add `loadAllJournalEntries()` to `DatabaseService`. It should query `JournalEntries` and return `[JournalEntry]`. Handle decoding errors.
    *   **Task:** Add `loadAllChats()` (or similar) to `DatabaseService`. This needs to query `ChatMessages`, group them by `chatId`, reconstruct `Chat` objects with their `[ChatMessage]`, and potentially load other `Chat` metadata if we add a `Chats` table later (for now, reconstruct from messages). Return `[Chat]`.
    *   **Task:** Modify `AppState`'s initialization or `.onAppear`: Replace `loadSampleData()` with a call to `databaseService.loadAllJournalEntries()` to populate `AppState.journalEntries`. Ensure this runs on the main thread for UI updates.
    *   **Task:** Modify `ChatManager`'s initialization (`init` or a separate load function): Replace `loadChats()` (from UserDefaults) with a call to `databaseService.loadAllChats()` to populate `ChatManager.chats`. Remove `UserDefaults` loading code.

2.  **Refactor ChatManager Persistence:**
    *   **Task:** Remove the `UserDefaults`-based `saveChats()` function in `ChatManager`. Saving now happens per-message via `databaseService.saveChatMessage`.
    *   **Task:** Implement `deleteChatFromDB(id: UUID)` in `DatabaseService` (deleting chat metadata if added, and all associated `ChatMessages`).
    *   **Task:** Modify `ChatManager.deleteChat` to call `databaseService.deleteChatFromDB`.
    *   **Task:** Implement `deleteMessageFromDB(id: UUID)` in `DatabaseService`.
    *   **Task:** Modify `ChatManager.deleteMessage` to call `databaseService.deleteMessageFromDB`.
    *   **Task:** Implement `toggleChatStarInDB(id: UUID, isStarred: Bool)` in `DatabaseService`.
    *   **Task:** Modify `ChatManager.toggleStarChat` to call `databaseService.toggleChatStarInDB`.
    *   **Task:** Implement `toggleMessageStarInDB(id: UUID, isStarred: Bool)` in `DatabaseService`.
    *   **Task:** Modify `ChatManager.toggleStarMessage` to call `databaseService.toggleMessageStarInDB`.
    *   *(Optional but Recommended):* Consider adding a `Chats` table to `libSQL` to store `Chat` metadata (ID, Title, CreatedAt, LastUpdatedAt, IsStarred) separately from messages, making loading/managing chats more efficient than reconstructing from messages alone.

3.  **Verify UI Data Flow:**
    *   **Task:** Thoroughly test `JournalView` and `ChatHistoryView` after the loading changes. Ensure they display data correctly fetched from the database via `AppState` and `ChatManager`. Test filtering, adding, editing, and deleting.

**Phase 5 (Backend RAG):**

1.  **Implement RAG Context Retrieval (Reflections):**
    *   **Task:** Modify `ReflectionsView.sendMessage`.
    *   Before calling the AI (`generateResponse`):
        *   Generate embedding for the user's `messageText`.
        *   Call `databaseService.findSimilarJournalEntries` and/or `findSimilarChatMessages` (limit K). Run this in a background task.
        *   Format the results into a context string.
        *   Prepend context to `messageToSend` before passing it to `generateResponse`.
    *   **(No UI Changes Required for this step)**

**Phase 6 (Refinement - Deferred):**

*   Performance Testing & Index Tuning.
*   Advanced Error Handling (User-facing alerts).
*   Backgrounding verification.
*   User-facing Semantic Search UI (Now deferred).

This revised plan prioritizes getting the database working as the reliable backend storage before adding new UI features.