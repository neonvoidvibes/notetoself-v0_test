# Document 17. ObjectBox Integration Plan

## 1. Introduction

This document details the step-by-step plan for integrating ObjectBox into the merged "Note to Self" application (based on the plan in Document 16). The objective is to replace the previous persistence layers (CoreData from `NoteToSelf0`, UserDefaults/in-memory from `NoteToSelf-v0_test`) with ObjectBox for storing `JournalEntry` and `Chat`/`ChatMessage` data. The integration will focus on simplicity and functionality, enabling efficient data storage and retrieval, particularly for use by analysis agents (InsightsView) and the chat agent (ReflectionsView).

## 2. Objectives

*   Set up the ObjectBox Swift library in the project.
*   Define ObjectBox entities for `JournalEntry` and `ChatMessage` (or `Chat`).
*   Implement a data access layer (Repositories) for CRUD operations using ObjectBox.
*   Integrate ObjectBox into ViewModels/Managers to replace existing data handling.
*   Enable efficient querying for agent-based retrieval and analysis, including preparation for vector search.
*   Remove legacy persistence code (CoreData, UserDefaults).

## 3. Prerequisites

*   The codebase integration outlined in Document 16 is complete or in progress. The project structure is based on `NoteToSelf-v0_test` with backend services from `NoteToSelf0` incorporated.
*   Unified data models for `JournalEntry` and `ChatMessage`/`Chat` exist (e.g., in `Models.swift`), ready to be converted into ObjectBox entities.

## 4. Integration Steps

1.  **[ ] Add ObjectBox Dependency:**
    *   Open the Xcode project.
    *   Navigate to `File > Add Packages...`.
    *   Enter the ObjectBox Swift package URL: `https://github.com/objectbox/objectbox-swift.git`.
    *   Select the package product `ObjectBox` and add it to the main application target.

2.  **[ ] Define ObjectBox Entities:**
    *   Modify the existing `JournalEntry` and `ChatMessage` (or potentially a `Chat` entity containing `ToMany<ChatMessage>`) structs/classes defined in `Models.swift` (or a new `Entities.swift`).
    *   Add the `import ObjectBox` statement.
    *   Annotate each class/struct intended for persistence with `@Entity`.
    *   Ensure each entity has an `id: Id` property (ObjectBox requires this; it can be `0` for new objects, ObjectBox will assign a unique ID).
    *   Define properties using ObjectBox-compatible types (e.g., `String`, `Date`, `Int`, `Double`, `Bool`, `[UInt8]` for Data).
    *   **Vector Search Preparation:**
        *   Add an `embedding: [Float]?` property to both `JournalEntry` and `ChatMessage`. Make it optional initially.
        *   Annotate this property with `@HnswIndex` to enable Hierarchical Navigable Small World (HNSW) vector indexing for efficient similarity searches by AI agents later.
        *   Example `JournalEntry` Entity:
            ```swift
            import ObjectBox

            @Entity
            final class JournalEntry: Identifiable {
                var id: Id = 0 // Let ObjectBox assign the ID
                var text: String
                var moodName: String // Store mood name as String
                var date: Date
                var intensity: Int
                // Vector embedding for AI analysis
                @HnswIndex var embedding: [Float]? // Optional initially

                // ObjectBox requires an initializer
                init(id: Id = 0, text: String = "", moodName: String = Mood.neutral.name, date: Date = Date(), intensity: Int = 2, embedding: [Float]? = nil) {
                    self.id = id
                    self.text = text
                    self.moodName = moodName // Store Mood enum's name
                    self.date = date
                    self.intensity = intensity
                    self.embedding = embedding
                }

                // Computed property to get Mood enum (optional)
                var mood: Mood {
                    return Mood(rawValue: moodName) ?? .neutral
                }
            }
            ```
        *   Example `ChatMessage` Entity:
            ```swift
            import ObjectBox

            @Entity
            final class ChatMessage: Identifiable {
                var id: Id = 0
                var text: String
                var isUser: Bool
                var date: Date
                var isStarred: Bool
                // Vector embedding for AI analysis
                @HnswIndex var embedding: [Float]? // Optional initially
                // Optional: Link to a Chat session
                // var chat: ToOne<Chat>

                init(id: Id = 0, text: String = "", isUser: Bool = false, date: Date = Date(), isStarred: Bool = false, embedding: [Float]? = nil) {
                    self.id = id
                    self.text = text
                    self.isUser = isUser
                    self.date = date
                    self.isStarred = isStarred
                    self.embedding = embedding
                }
            }
            ```
    *   **Build the project** after defining entities. ObjectBox's code generator will run and create necessary helper files. Address any build errors.

3.  **[ ] Initialize ObjectBox Store:**
    *   Create a new Swift file, e.g., `ObjectBoxManager.swift`.
    *   Define a singleton class to manage the ObjectBox `Store`.
    *   Initialize the store in the singleton's initializer. Use `Store.defaultDirectoryPath()` for the database location.
    *   Provide easy access to the `Store` instance and entity `Box`es.
    *   Example `ObjectBoxManager.swift`:
        ```swift
        import ObjectBox
        import Foundation

        class ObjectBoxManager {
            static let shared = ObjectBoxManager()
            let store: Store

            private init() {
                do {
                    let directory = URL.defaultObjectBoxDirectory() // Recommended path
                    self.store = try Store(directoryPath: directory.path)
                    print("ObjectBox Store initialized at: \(directory.path)")
                } catch {
                    fatalError("Failed to initialize ObjectBox Store: \(error)")
                }
            }

            // Convenience accessors for Boxes
            var journalBox: Box<JournalEntry> { return store.box(for: JournalEntry.self) }
            var chatMessageBox: Box<ChatMessage> { return store.box(for: ChatMessage.self) }
            // Add other boxes as needed
        }
        ```

4.  **[ ] Create Data Access Layer (Repositories):**
    *   Create separate files (e.g., `JournalRepository.swift`, `ChatRepository.swift`) or extend `ObjectBoxManager`.
    *   Implement functions for common database operations using the `Box` instances from `ObjectBoxManager`.
    *   Focus on the methods needed by the ViewModels and agents.
    *   Example `JournalRepository`:
        ```swift
        import ObjectBox

        class JournalRepository {
            private let box = ObjectBoxManager.shared.journalBox

            func addOrUpdateEntry(_ entry: JournalEntry) throws {
                try box.put(entry)
            }

            func getEntry(id: Id) throws -> JournalEntry? {
                return try box.get(id)
            }

            func getAllEntries(sortedByDateAscending: Bool = false) throws -> [JournalEntry] {
                let query = try box.query().order(by: JournalEntry.date, flags: sortedByDateAscending ? [] : .descending).build()
                return try query.find()
            }

            func deleteEntry(id: Id) throws {
                try box.remove(id)
            }

            // Example query for agents (simple text search initially)
            func findEntries(containing text: String, limit: Int = 10) throws -> [JournalEntry] {
                let query = try box.query(JournalEntry.text.contains(text, caseSensitive: false))
                                  .order(by: JournalEntry.date, flags: .descending)
                                  .build()
                query.limit = limit
                return try query.find()
            }

            // Placeholder for future vector search
            func findSimilarEntries(embedding: [Float], limit: Int = 5) throws -> [JournalEntry] {
                // ObjectBox vector search query would go here once embeddings are generated
                // Example (conceptual):
                // let query = try box.query {
                //    JournalEntry.embedding.nearestNeighbors(to: embedding, count: limit)
                // }.build()
                // return try query.find()
                print("Vector search not implemented yet.")
                return []
            }
        }
        ```
    *   Implement similar repository methods for `ChatMessage`.

5.  **[ ] Integrate Repositories into ViewModels/Managers:**
    *   In `AppState.swift` (or a dedicated `JournalViewModel`):
        *   Replace the in-memory `journalEntries` array logic.
        *   Inject or instantiate `JournalRepository`.
        *   Load entries from the repository on initialization: `self.entries = try? repository.getAllEntries()`.
        *   Call repository methods (`addOrUpdateEntry`, `deleteEntry`) when the user adds/deletes entries. Update the `@Published` array accordingly.
    *   In `ChatManager.swift` (or a dedicated `ReflectionsViewModel`):
        *   Replace `UserDefaults` saving/loading logic.
        *   Inject or instantiate `ChatRepository`.
        *   Load chat messages (perhaps for the `currentChat`) on initialization or when a chat is selected.
        *   Call repository methods (`addOrUpdateMessage`, `deleteMessage`) when messages are sent/received/deleted. Update the `@Published` messages array.
    *   **Agent Integration:** Modify `InsightsView` and `ReflectionsView` (or their underlying logic/agents) to call the appropriate repository query methods (e.g., `findEntries`, `findSimilarEntries`) when needing data for analysis or context.

6.  **[ ] Remove Legacy Persistence Code:**
    *   Delete `Persistence.swift`, `PersistenceController+Preview.swift`, and `NoteToSelf.xcdatamodeld` if they were copied from `NoteToSelf0`.
    *   Remove all code related to `NSManagedObjectContext`, `FetchRequest`, etc.
    *   Remove the `UserDefaults` saving and loading code within `ChatManager.swift`.
    *   Remove the in-memory `journalEntries` array and sample data loading from `AppState.swift`. Ensure `AppState` now fetches data from the `JournalRepository`.

7.  **[ ] Data Migration (Consideration):**
    *   This plan assumes a fresh integration where prior user data (from CoreData or UserDefaults) does *not* need to be migrated.
    *   If migration *were* required for an app update, a one-time process would need to be implemented on first launch after the update: load data from the old source (CoreData/UserDefaults) and `put` it into ObjectBox using the repositories. Mark migration as complete in `UserDefaults`.

8.  **[ ] Testing:**
    *   **CRUD Operations:** Verify that creating, reading, updating, and deleting journal entries and chat messages works correctly via the UI.
    *   **Data Persistence:** Close and reopen the app to ensure data is saved and loaded correctly.
    *   **Querying:** Test the specific queries used by the Insights/Reflections agents. Ensure they return the expected data.
    *   **Performance:** Observe app launch time and UI responsiveness, especially when loading lists of data. ObjectBox should generally be faster than CoreData/UserDefaults for many operations.
    *   **Error Handling:** Test scenarios where database operations might fail (though ObjectBox is robust, consider edge cases).

## 5. Conclusion

This plan provides a clear path to replace existing persistence mechanisms with ObjectBox. By defining entities, creating repositories, and integrating them into the existing ViewModel/Manager structure, we establish a high-performance, object-oriented database solution suitable for the "Note to Self" application. The inclusion of `@HnswIndex` prepares the data model for future efficient vector searches required by AI analysis and retrieval agents, while the focus on simple CRUD operations ensures a manageable initial integration.