# Plan: Integrate On-Device Vector Search using libSQL

## 1. Aim / Goal

The primary goal is to implement **offline, on-device semantic search** capabilities within the NoteToSelf iOS app using `libSQL` and its Swift bindings (`libsql-swift`). This involves:

1.  **Persisting Data:** Storing `JournalEntry` and `ChatMessage` data (currently in `AppState` memory and `UserDefaults` respectively) into a local `libSQL` database file on the user's device.
2.  **Generating Embeddings:** Creating numerical vector representations (embeddings) for the text content of journal entries and chat messages using an on-device model (currently Apple's `NLEmbedding`).
3.  **Storing Embeddings:** Saving these embeddings alongside the corresponding data in the `libSQL` database.
4.  **Indexing Embeddings:** Creating efficient Approximate Nearest Neighbor (ANN) vector indexes (`libsql_vector_idx`) on the embedding columns using `libSQL`'s built-in DiskANN implementation.
5.  **Enabling Semantic Search:** Implementing functions to query the database and retrieve the most semantically similar entries/messages based on a given text query's embedding.
6.  **Integrating Search Features:** Using the search functionality to enhance the app, specifically:
    *   Allowing users to search their journal/chat history based on meaning, not just keywords.
    *   Providing relevant context (similar past entries/messages) to the AI reflection feature (`ReflectionsView`) for Retrieval-Augmented Generation (RAG).
7.  **Ensuring UI Consistency:** Making sure the UI accurately reflects the state of the data stored in the `libSQL` database (the new source of truth).

**Technology Choice:** `libSQL` with `libsql-swift` (version 0.3.0+) was chosen for its native vector support, efficient on-device DiskANN indexing, offline capabilities, SQLite foundation, and Swift-native SDK.

## 2. Accomplishments So Far (Phases 1-3 Partially Complete)

*   **Dependency Added:** `libsql-swift` (v0.3.0) package added to the project.
*   **Database Service Created:** `DatabaseService.swift` created, handling database file initialization and connection setup.
*   **Schema Defined:** `CREATE TABLE` statements for `JournalEntries` and `ChatMessages` added, including `FLOAT32(512)` columns for embeddings. (Confirmed 512 dimension for `NLEmbedding`).
*   **Vector Indexes Created:** `CREATE INDEX` statements using `libsql_vector_idx(embedding)` added to create DiskANN indexes. Corrected schema/index definition to infer dimension (512) properly.
*   **Embedding Helpers Added:** Global functions `generateEmbedding(for:)` (using `NLEmbedding`) and `embeddingToJson(_:)` added and functional.
*   **Journal Entry Saving Integrated:**
    *   `JournalView` modified to inject `DatabaseService`.
    *   `onSave` closures for new/editing entries now call `generateEmbedding` and `databaseService.saveJournalEntry`. Embeddings are being generated and entries saved to the `libSQL` database.
*   **Journal Entry Deletion Integrated:**
    *   `deleteJournalEntry(id:)` function added to `DatabaseService`.
    *   `JournalView.deleteEntry` now calls the database deletion function. Entries are successfully deleted from both `AppState` (UI) and the `libSQL` database.
*   **Build Stability:** The core `DatabaseService` and related modifications now compile successfully after resolving several API compatibility issues with `libsql-swift` 0.3.0.

## 3. Upcoming Steps

The following steps need to be completed to fully realize the goal:

**Phase 3 (Continued): Data Migration & Embedding Generation**

1.  **Integrate Chat Message Saving:**
    *   **Task:** Modify `ChatManager.addMessage` to:
        *   Inject/access `DatabaseService`.
        *   Call `generateEmbedding` for the new `ChatMessage.text`.
        *   Call `databaseService.saveChatMessage`, passing the message, `chatId`, and embedding vector. Include error handling.
    *   **Decision:** Choose how to handle `ChatManager`'s existing `UserDefaults` persistence (`saveChats`, `loadChats`). Option A (Recommended for now): Save to *both* DB and UserDefaults. Option B: Refactor `ChatManager` fully to use DB only (requires adding DB load/delete methods).

2.  **Implement Initial Data Migration:**
    *   **Task:** Add logic (e.g., in `NoteToSelf_v0_testApp.onAppear` or `DatabaseService.init`) that runs *once* upon first launch after this update.
    *   This logic should iterate through existing `AppState.journalEntries` and `ChatManager.chats` (loaded from UserDefaults).
    *   For each item, call `generateEmbedding` and save it to the corresponding `libSQL` table using `databaseService.saveJournalEntry` or `databaseService.saveChatMessage`.
    *   Use a `UserDefaults` flag (e.g., `didRunLibSQLMigration_v1`) to prevent re-running.
    *   **Important:** Run this migration logic on a background thread (`Task { ... }`).

**Phase 4: Implement Semantic Search & UI Integration**

1.  **Implement Search UI (Journal):**
    *   **Task:** Add a search bar (`TextField`) to `JournalView`.
    *   On search submission:
        *   Generate embedding for the query text.
        *   Call `databaseService.findSimilarJournalEntries` in a background task.
        *   Update a `@State` variable with the results.
        *   Modify the `LazyVStack` in `JournalView` to display search results when available. Add a way to clear search.

2.  **Implement Search UI (Chat History):**
    *   **Task:** Add a similar search bar to `ChatHistoryView`.
    *   On search submission:
        *   Generate embedding for the query text.
        *   Call `databaseService.findSimilarChatMessages` in a background task.
        *   Update state to display results (potentially grouped by chat or shown as individual messages).

3.  **Implement RAG Context Retrieval (Reflections):**
    *   **Task:** Modify `ReflectionsView.sendMessage`.
    *   Before calling the AI (`generateResponse`):
        *   Generate embedding for the user's `messageText`.
        *   Call `databaseService.findSimilarJournalEntries` and/or `findSimilarChatMessages` (limit K=3 or 5).
        *   Format the retrieved text snippets into a context string.
        *   Prepend the context string to `messageToSend` before passing it to `generateResponse`.
        *   Adjust `generateResponse` if needed to handle the combined context+query input.

**Phase 5: Make Database the Source of Truth**

*This is crucial for UI consistency.*

1.  **Implement Data Loading from DB:**
    *   **Task:** Add functions to `DatabaseService` to load *all* `JournalEntries` and *all* `ChatMessages` (or perhaps chats with their messages).
    *   **Task:** Modify `AppState` to load `journalEntries` from `databaseService.loadAllJournalEntries()` during initialization (or `.onAppear`), instead of using `loadSampleData()`.
    *   **Task:** Refactor `ChatManager` (`loadChats`, `init`) to load chats and messages entirely from `databaseService` instead of `UserDefaults`. Remove `UserDefaults`-related saving/loading code (`saveChats`, `loadChats`, `userDefaultsKey`). Update `deleteChat` to call a `databaseService.deleteChat(id:)` method (which needs to be created, deleting the chat and all its messages).

2.  **Update UI Data Sources:**
    *   **Task:** Ensure `JournalView`, `ChatHistoryView`, and potentially `InsightsView` correctly observe and react to changes in the data loaded from the database (likely still via `@EnvironmentObject AppState` and `@ObservedObject ChatManager`, but ensuring *those* objects now get their data from `DatabaseService`).

**Phase 6: Refinement and Optimization**

1.  **Performance Testing:** Test search speed and UI responsiveness with significant data (~1000+ entries/messages). Profile if needed.
2.  **Index Tuning:** If performance/storage issues arise, revisit `DatabaseService.setupSchemaAndIndexes` to experiment with index parameters (`compress_neighbors`, `max_neighbors`). Requires DB deletion/recreation.
3.  **Error Handling:** Add user-facing error handling (e.g., Alerts) for database save/load/search failures where appropriate.
4.  **Backgrounding:** Ensure all potentially long-running DB operations (migration, complex searches, embedding generation if slow) are performed off the main thread using `Task` or `DispatchQueue.global()`, with UI updates dispatched back to the main thread.

This plan provides a clear roadmap for the colleague to continue the implementation.