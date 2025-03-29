import Foundation
import Libsql // Import the SDK
import SwiftUI // Needed for ObservableObject

// Define potential errors
enum DatabaseError: Error {
    case initializationFailed(String)
    case schemaSetupFailed(String)
    case indexCreationFailed(String)
    case embeddingGenerationFailed(String)
    case saveDataFailed(String)
    case queryFailed(String)
    case decodingFailed(String)
}

class DatabaseService: ObservableObject {
    // MARK: - Properties
    private let db: Database
    private(set) var connection: Connection // Allow read access, but keep mutation internal
    private let dbFileName = "NoteToSelfData_v1.sqlite"
    private let embeddingDimension = 384 // **CONFIRM THIS MATCHES YOUR MODEL**

    // MARK: - Initialization
    init() {
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = docsURL.appendingPathComponent(dbFileName).path
        print("Database path: \(dbPath)")

        do {
            // Step 1: Initialize Database Object
            self.db = try Database(dbPath)
            print("Database object created.")

            // Step 2: Establish Connection
            self.connection = try db.connect()
            print("Database connection established.")

            // Step 3: Setup Schema and Indexes
            try setupSchemaAndIndexes()
            print("Schema and index setup sequence completed successfully.")

        } catch {
            print("‼️ ERROR during DatabaseService initialization: \(error)")
            fatalError("Failed to initialize DatabaseService: \(error.localizedDescription)")
        }
    } // End of init()

    // MARK: - Schema and Index Setup
    private func setupSchemaAndIndexes() throws {
        print("Setting up database schema and indexes...")
        do {
            // --- Table Creation ---
            // JournalEntries Table
            _ = try connection.execute( // Silence unused result
                """
                CREATE TABLE IF NOT EXISTS JournalEntries (
                    id TEXT PRIMARY KEY,
                    text TEXT NOT NULL,
                    mood TEXT NOT NULL,
                    date INTEGER NOT NULL,
                    intensity INTEGER NOT NULL,
                    embedding F32_BLOB(\(embeddingDimension))
                );
                """ // Content must start on new line
            )

            // ChatMessages Table
            _ = try connection.execute( // Silence unused result
                """
                CREATE TABLE IF NOT EXISTS ChatMessages (
                    id TEXT PRIMARY KEY,
                    chatId TEXT NOT NULL,
                    text TEXT NOT NULL,
                    isUser INTEGER NOT NULL,
                    date INTEGER NOT NULL,
                    isStarred INTEGER NOT NULL,
                    embedding F32_BLOB(\(embeddingDimension))
                );
                """ // Content must start on new line
            )
            print("Database tables checked/created.")

            // --- Index Creation ---
            // Journal Entry Index
            _ = try connection.execute( // Silence unused result
                """
                CREATE INDEX IF NOT EXISTS journal_embedding_idx
                ON JournalEntries( libsql_vector_idx(embedding) );
                """ // Content must start on new line
            )

            // Chat Message Index
            _ = try connection.execute( // Silence unused result
                """
                CREATE INDEX IF NOT EXISTS chat_embedding_idx
                ON ChatMessages( libsql_vector_idx(embedding) );
                """ // Content must start on new line
            )
            print("Vector indexes checked/created.")

        } catch {
            print("Error during schema/index setup: \(error)")
            throw DatabaseError.schemaSetupFailed(error.localizedDescription)
        }
    }

    // MARK: - Data Operations

    // --- Save Operations ---
    func saveJournalEntry(_ entry: JournalEntry, embedding: [Float]?) throws {
        let sql: String
        let params: [Value] // Use the Value type from Libsql

        if let validEmbedding = embedding {
            // Ensure embedding has correct dimension before converting
             guard validEmbedding.count == embeddingDimension else {
                 print("Error: Embedding dimension mismatch for JournalEntry \(entry.id). Expected \(embeddingDimension), got \(validEmbedding.count).")
                 // Save without embedding or throw error
                  sql = """
                      INSERT OR REPLACE INTO JournalEntries (id, text, mood, date, intensity, embedding)
                      VALUES (?, ?, ?, ?, ?, NULL);
                      """
                  params = [
                      .text(entry.id.uuidString),
                      .text(entry.text),
                      .text(entry.mood.rawValue),
                      .integer(Int64(entry.date.timeIntervalSince1970)),
                      .integer(Int64(entry.intensity)) // Store Int as Int64
                  ]
                 print("Warning: Saving JournalEntry \(entry.id) without embedding due to dimension mismatch.")
                 _ = try connection.execute(sql, params) // Execute save without embedding
                 return // Exit after saving without embedding
                 // Alternatively, throw an error:
                 // throw DatabaseError.embeddingGenerationFailed("Dimension mismatch for JournalEntry \(entry.id)")
             }

            let embJSON = embeddingToJson(validEmbedding) // Use helper function
            sql = """
                INSERT OR REPLACE INTO JournalEntries (id, text, mood, date, intensity, embedding)
                VALUES (?, ?, ?, ?, ?, vector32(?));
                """
            params = [
                .text(entry.id.uuidString),
                .text(entry.text),
                .text(entry.mood.rawValue),
                .integer(Int64(entry.date.timeIntervalSince1970)),
                .integer(Int64(entry.intensity)), // Store Int as Int64
                .text(embJSON) // vector32 expects TEXT input
            ]
        } else {
            // Handle case where embedding is nil from the start
            print("Warning: Saving JournalEntry \(entry.id) without embedding (embedding was nil).")
            sql = """
                INSERT OR REPLACE INTO JournalEntries (id, text, mood, date, intensity, embedding)
                VALUES (?, ?, ?, ?, ?, NULL);
                """
            params = [
                .text(entry.id.uuidString),
                .text(entry.text),
                .text(entry.mood.rawValue),
                .integer(Int64(entry.date.timeIntervalSince1970)),
                .integer(Int64(entry.intensity)) // Store Int as Int64
            ]
        }

        do {
            _ = try connection.execute(sql, params) // Silence unused result
        } catch {
            print("Error saving JournalEntry \(entry.id): \(error)")
            throw DatabaseError.saveDataFailed(error.localizedDescription)
        }
    }

    func saveChatMessage(_ message: ChatMessage, chatId: UUID, embedding: [Float]?) throws {
        let sql: String
        let params: [Value]

         if let validEmbedding = embedding {
             guard validEmbedding.count == embeddingDimension else {
                 print("Error: Embedding dimension mismatch for ChatMessage \(message.id). Expected \(embeddingDimension), got \(validEmbedding.count).")
                 // Save without embedding or throw error
                 sql = """
                     INSERT OR REPLACE INTO ChatMessages (id, chatId, text, isUser, date, isStarred, embedding)
                     VALUES (?, ?, ?, ?, ?, ?, NULL);
                     """
                 params = [
                     .text(message.id.uuidString),
                     .text(chatId.uuidString),
                     .text(message.text),
                     .integer(message.isUser ? 1 : 0),
                     .integer(Int64(message.date.timeIntervalSince1970)),
                     .integer(message.isStarred ? 1 : 0)
                 ]
                 print("Warning: Saving ChatMessage \(message.id) without embedding due to dimension mismatch.")
                 _ = try connection.execute(sql, params)
                 return
                 // Alternatively: throw DatabaseError.embeddingGenerationFailed("Dimension mismatch for ChatMessage \(message.id)")
             }

            let embJSON = embeddingToJson(validEmbedding)
            sql = """
                INSERT OR REPLACE INTO ChatMessages (id, chatId, text, isUser, date, isStarred, embedding)
                VALUES (?, ?, ?, ?, ?, ?, vector32(?));
                """
            params = [
                .text(message.id.uuidString),
                .text(chatId.uuidString),
                .text(message.text),
                .integer(message.isUser ? 1 : 0), // Store Bool as Int64
                .integer(Int64(message.date.timeIntervalSince1970)),
                .integer(message.isStarred ? 1 : 0), // Store Bool as Int64
                .text(embJSON)
            ]
         } else {
             print("Warning: Saving ChatMessage \(message.id) without embedding (embedding was nil).")
              sql = """
                  INSERT OR REPLACE INTO ChatMessages (id, chatId, text, isUser, date, isStarred, embedding)
                  VALUES (?, ?, ?, ?, ?, ?, NULL);
                  """
              params = [
                  .text(message.id.uuidString),
                  .text(chatId.uuidString),
                  .text(message.text),
                  .integer(message.isUser ? 1 : 0),
                  .integer(Int64(message.date.timeIntervalSince1970)),
                  .integer(message.isStarred ? 1 : 0)
              ]
         }

        do {
           _ = try connection.execute(sql, params) // Silence unused result
        } catch {
            print("Error saving ChatMessage \(message.id): \(error)")
            throw DatabaseError.saveDataFailed(error.localizedDescription)
        }
    }

    // --- Search Operations ---
    func findSimilarJournalEntries(to queryVector: [Float], limit: Int = 5) throws -> [JournalEntry] {
        guard !queryVector.isEmpty else { return [] }
        // Ensure query vector has correct dimension
        guard queryVector.count == embeddingDimension else {
             print("Error: Query vector dimension mismatch. Expected \(embeddingDimension), got \(queryVector.count).")
             throw DatabaseError.queryFailed("Query vector dimension mismatch")
        }
        let queryJSON = embeddingToJson(queryVector)

        let sql = """
            SELECT E.id, E.text, E.mood, E.date, E.intensity
            FROM JournalEntries AS E
            JOIN vector_top_k('journal_embedding_idx', vector32(?), ?) AS V
              ON E.id = V.id
            WHERE E.embedding IS NOT NULL
            ORDER BY V.distance ASC;
            """
        let params: [Value] = [.text(queryJSON), .integer(Int64(limit))]

        do {
            let rows = try connection.query(sql, params)
            var results: [JournalEntry] = []

            for row in rows {
                // Access columns by position (0-based index)
                // SELECT E.id (0), E.text (1), E.mood (2), E.date (3), E.intensity (4)
                guard let idStr = try? row.getString(0), // Use try? for optional unwrap
                      let id = UUID(uuidString: idStr),
                      let text = try? row.getString(1),
                      let moodStr = try? row.getString(2),
                      let mood = Mood(rawValue: moodStr),
                      let dateTimestamp = try? row.getInt(3), // Use getInt()
                      let intensityInt = try? row.getInt(4)  // Use getInt()
                else {
                     print("Warning: Failed to decode JournalEntry row using positional index. Row data: \(row)")
                    continue
                }
                let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
                let intensity = Int(intensityInt) // Convert Int64 back to Int
                results.append(JournalEntry(id: id, text: text, mood: mood, date: date, intensity: intensity))
            }
            return results
        } catch {
            print("Error finding similar journal entries: \(error)")
            throw DatabaseError.queryFailed(error.localizedDescription)
        }
    }

    func findSimilarChatMessages(to queryVector: [Float], limit: Int = 5) throws -> [(message: ChatMessage, chatId: UUID)] {
         guard !queryVector.isEmpty else { return [] }
         guard queryVector.count == embeddingDimension else {
              print("Error: Query vector dimension mismatch. Expected \(embeddingDimension), got \(queryVector.count).")
              throw DatabaseError.queryFailed("Query vector dimension mismatch")
         }
         let queryJSON = embeddingToJson(queryVector)

         let sql = """
             SELECT M.id, M.chatId, M.text, M.isUser, M.date, M.isStarred
             FROM ChatMessages AS M
             JOIN vector_top_k('chat_embedding_idx', vector32(?), ?) AS V
               ON M.id = V.id
             WHERE M.embedding IS NOT NULL
             ORDER BY V.distance ASC;
             """
         let params: [Value] = [.text(queryJSON), .integer(Int64(limit))]

        do {
            let rows = try connection.query(sql, params)
            var results: [(message: ChatMessage, chatId: UUID)] = []

            for row in rows {
                 // Access columns by position (0-based index)
                 // SELECT M.id (0), M.chatId (1), M.text (2), M.isUser (3), M.date (4), M.isStarred (5)
                 guard let idStr = try? row.getString(0),
                       let id = UUID(uuidString: idStr),
                       let chatIdStr = try? row.getString(1),
                       let chatId = UUID(uuidString: chatIdStr),
                       let text = try? row.getString(2),
                       let isUserInt = try? row.getInt(3),       // Use getInt()
                       let dateTimestamp = try? row.getInt(4),   // Use getInt()
                       let isStarredInt = try? row.getInt(5)     // Use getInt()
                 else {
                     print("Warning: Failed to decode ChatMessage row using positional index. Row data: \(row)")
                    continue
                 }
                 let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
                 let isUser = isUserInt == 1 // Convert Int64 back to Bool
                 let isStarred = isStarredInt == 1 // Convert Int64 back to Bool
                 let message = ChatMessage(id: id, text: text, isUser: isUser, date: date, isStarred: isStarred)
                 results.append((message: message, chatId: chatId))
            }
            return results
        } catch {
            print("Error finding similar chat messages: \(error)")
            throw DatabaseError.queryFailed(error.localizedDescription)
        }
    }

    // MARK: - Utility
    // Helper to convert [Float] to JSON string representation for libSQL.
    // Kept public within the class if needed externally, or make private if only used internally.
    func embeddingToJson(_ embedding: [Float]) -> String {
        // Using map(String.init) might be slow for large arrays.
        // Consider optimized JSON encoding if performance becomes an issue.
        // Using higher precision format specifier
        return "[" + embedding.map { String(format: "%.8f", $0) }.joined(separator: ",") + "]"
    }

    // TODO: Add methods for deleting, loading specific items, etc. as needed later.

} // <-- End of DatabaseService class