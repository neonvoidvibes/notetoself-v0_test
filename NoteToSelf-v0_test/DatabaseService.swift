import Foundation
import Libsql // Import the SDK
import SwiftUI // Needed for ObservableObject
import NaturalLanguage // Needed for embedding helpers

// --- Custom Error Enum ---
enum DatabaseError: Error {
    case initializationFailed(String)
    case schemaSetupFailed(String)
    case indexCreationFailed(String)
    case embeddingGenerationFailed(String)
    case saveDataFailed(String)
    case queryFailed(String)
    case decodingFailed(String)
    case dimensionMismatch(expected: Int, actual: Int)
    case deleteFailed(String) // Added error type for delete
}

// --- Service Class Definition ---

class DatabaseService: ObservableObject {
    // MARK: - Properties
    private let db: Database // Libsql Database object
    private(set) var connection: Connection // Active connection to the database
    private let dbFileName = "NoteToSelfData_v1.sqlite" // Database file name (versioned)
    private let embeddingDimension = 512 // ** Confirmed Embedding Dimension **

    // MARK: - Initialization
    init() {
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = docsURL.appendingPathComponent(self.dbFileName).path
        print("Database path: \(dbPath)")

        let tempDb: Database
        let tempConnection: Connection

        do {
            tempDb = try Database(dbPath)
            print("Database object created.")
            tempConnection = try tempDb.connect()
            print("Database connection established.")

            self.db = tempDb
            self.connection = tempConnection

            try setupSchemaAndIndexes()
            print("Schema and index setup sequence completed successfully.")

        } catch {
            print("‼️ ERROR during DatabaseService initialization: \(error)")
            fatalError("Failed to initialize DatabaseService: \(error.localizedDescription)")
        }
    } // End of init()

    // MARK: - Schema and Index Setup (Private Helper)
    private func setupSchemaAndIndexes() throws {
        print("Setting up database schema and indexes...")
        do {
            // JournalEntries Table
            _ = try self.connection.execute(
                """
                CREATE TABLE IF NOT EXISTS JournalEntries (
                    id TEXT PRIMARY KEY, text TEXT NOT NULL, mood TEXT NOT NULL,
                    date INTEGER NOT NULL, intensity INTEGER NOT NULL,
                    embedding FLOAT32(\(self.embeddingDimension)) /* Corrected Type */
                );
                """
            )
            // ChatMessages Table
            _ = try self.connection.execute(
                """
                CREATE TABLE IF NOT EXISTS ChatMessages (
                    id TEXT PRIMARY KEY, chatId TEXT NOT NULL, text TEXT NOT NULL,
                    isUser INTEGER NOT NULL, date INTEGER NOT NULL, isStarred INTEGER NOT NULL,
                    embedding FLOAT32(\(self.embeddingDimension)) /* Corrected Type */
                );
                """
            )
            print("Database tables checked/created.")

            // Journal Entry Index
            _ = try self.connection.execute(
                """
                CREATE INDEX IF NOT EXISTS journal_embedding_idx
                ON JournalEntries( libsql_vector_idx(embedding) );
                """ // Dimension inferred from FLOAT32(512) column type
            )
            // Chat Message Index
            _ = try self.connection.execute(
                """
                CREATE INDEX IF NOT EXISTS chat_embedding_idx
                ON ChatMessages( libsql_vector_idx(embedding) );
                """ // Dimension inferred from FLOAT32(512) column type
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
        let params: [Value]

        if let validEmbedding = embedding, validEmbedding.count == self.embeddingDimension {
            guard let embJSON = embeddingToJson(validEmbedding) else {
                 print("Warning: Failed to convert JE embedding to JSON. Saving without embedding.")
                 sql = "INSERT OR REPLACE INTO JournalEntries (id, text, mood, date, intensity, embedding) VALUES (?, ?, ?, ?, ?, NULL);"
                 params = [.text(entry.id.uuidString), .text(entry.text), .text(entry.mood.rawValue),
                           .integer(Int64(entry.date.timeIntervalSince1970)), .integer(Int64(entry.intensity))]
                 guard params.count == 5 else { throw DatabaseError.saveDataFailed("Param count mismatch (JE/NoEmbed/JSONFail)") }
                 do { _ = try self.connection.execute(sql, params) }
                 catch { throw DatabaseError.saveDataFailed("JournalEntry \(entry.id): \(error.localizedDescription)") }
                 return // Exit after saving without embedding
            }
            // Basic safety for JSON string within SQL literal - replace single quotes
            let safeEmbJSON = embJSON.replacingOccurrences(of: "'", with: "''")
            sql = """
                INSERT OR REPLACE INTO JournalEntries (id, text, mood, date, intensity, embedding)
                VALUES (?, ?, ?, ?, ?, vector32('\(safeEmbJSON)'));
                """
            params = [.text(entry.id.uuidString), .text(entry.text), .text(entry.mood.rawValue),
                      .integer(Int64(entry.date.timeIntervalSince1970)), .integer(Int64(entry.intensity))]
            guard params.count == 5 else { throw DatabaseError.saveDataFailed("Param count mismatch (JE/Embed)") }
        } else {
            if embedding != nil { print("Warning: Dim mismatch JE \(entry.id). Saving without embedding.") }
            else { print("Warning: Saving JE \(entry.id) without embedding (nil).") }
            sql = "INSERT OR REPLACE INTO JournalEntries (id, text, mood, date, intensity, embedding) VALUES (?, ?, ?, ?, ?, NULL);"
            params = [.text(entry.id.uuidString), .text(entry.text), .text(entry.mood.rawValue),
                      .integer(Int64(entry.date.timeIntervalSince1970)), .integer(Int64(entry.intensity))]
            guard params.count == 5 else { throw DatabaseError.saveDataFailed("Param count mismatch (JE/NoEmbed)") }
        }
        do { _ = try self.connection.execute(sql, params) }
        catch { throw DatabaseError.saveDataFailed("JournalEntry \(entry.id): \(error.localizedDescription)") }
    }

    func saveChatMessage(_ message: ChatMessage, chatId: UUID, embedding: [Float]?) throws {
        let sql: String
        let params: [Value]

         if let validEmbedding = embedding, validEmbedding.count == self.embeddingDimension {
            guard let embJSON = embeddingToJson(validEmbedding) else {
                 print("Warning: Failed to convert CM embedding to JSON. Saving without embedding.")
                 sql = "INSERT OR REPLACE INTO ChatMessages (id, chatId, text, isUser, date, isStarred, embedding) VALUES (?, ?, ?, ?, ?, ?, NULL);"
                 params = [.text(message.id.uuidString), .text(chatId.uuidString), .text(message.text),
                           .integer(message.isUser ? 1 : 0), .integer(Int64(message.date.timeIntervalSince1970)),
                           .integer(message.isStarred ? 1 : 0)]
                 guard params.count == 6 else { throw DatabaseError.saveDataFailed("Param count mismatch (CM/NoEmbed/JSONFail)") }
                 do { _ = try self.connection.execute(sql, params) }
                 catch { throw DatabaseError.saveDataFailed("ChatMessage \(message.id): \(error.localizedDescription)") }
                 return // Exit after saving without embedding
            }
            let safeEmbJSON = embJSON.replacingOccurrences(of: "'", with: "''")
            sql = """
                INSERT OR REPLACE INTO ChatMessages (id, chatId, text, isUser, date, isStarred, embedding)
                VALUES (?, ?, ?, ?, ?, ?, vector32('\(safeEmbJSON)'));
                """
            params = [.text(message.id.uuidString), .text(chatId.uuidString), .text(message.text),
                      .integer(message.isUser ? 1 : 0), .integer(Int64(message.date.timeIntervalSince1970)),
                      .integer(message.isStarred ? 1 : 0)]
             guard params.count == 6 else { throw DatabaseError.saveDataFailed("Param count mismatch (CM/Embed)") }
         } else {
             if embedding != nil { print("Warning: Dim mismatch CM \(message.id). Saving without embedding.") }
             else { print("Warning: Saving CM \(message.id) without embedding (nil).") }
             sql = "INSERT OR REPLACE INTO ChatMessages (id, chatId, text, isUser, date, isStarred, embedding) VALUES (?, ?, ?, ?, ?, ?, NULL);"
             params = [.text(message.id.uuidString), .text(chatId.uuidString), .text(message.text),
                       .integer(message.isUser ? 1 : 0), .integer(Int64(message.date.timeIntervalSince1970)),
                       .integer(message.isStarred ? 1 : 0)]
              guard params.count == 6 else { throw DatabaseError.saveDataFailed("Param count mismatch (CM/NoEmbed)") }
         }
        do { _ = try self.connection.execute(sql, params) }
        catch { throw DatabaseError.saveDataFailed("ChatMessage \(message.id): \(error.localizedDescription)") }
    }

    // --- Delete Operations ---
    /// Deletes a JournalEntry from the database based on its ID.
    func deleteJournalEntry(id: UUID) throws {
        let sql = "DELETE FROM JournalEntries WHERE id = ?;"
        let params: [Value] = [.text(id.uuidString)]

        do {
            _ = try self.connection.execute(sql, params)
            print("Attempted delete for JournalEntry ID: \(id.uuidString)")
        } catch {
            print("‼️ Error deleting JournalEntry \(id.uuidString): \(error)")
            throw DatabaseError.deleteFailed("Failed to delete JournalEntry \(id.uuidString): \(error.localizedDescription)")
        }
    }

    /// Deletes all ChatMessages associated with a given chatId.
    func deleteChatFromDB(id: UUID) throws {
        let sql = "DELETE FROM ChatMessages WHERE chatId = ?;"
        let params: [Value] = [.text(id.uuidString)]
        do {
            _ = try self.connection.execute(sql, params)
            print("Attempted delete for all messages in Chat ID: \(id.uuidString)")
        } catch {
            print("‼️ Error deleting Chat \(id.uuidString): \(error)")
            throw DatabaseError.deleteFailed("Failed to delete Chat \(id.uuidString): \(error.localizedDescription)")
        }
    }

    /// Deletes a single ChatMessage from the database based on its ID.
    func deleteMessageFromDB(id: UUID) throws {
        let sql = "DELETE FROM ChatMessages WHERE id = ?;"
        let params: [Value] = [.text(id.uuidString)]
        do {
            _ = try self.connection.execute(sql, params)
            print("Attempted delete for ChatMessage ID: \(id.uuidString)")
        } catch {
            print("‼️ Error deleting ChatMessage \(id.uuidString): \(error)")
            throw DatabaseError.deleteFailed("Failed to delete ChatMessage \(id.uuidString): \(error.localizedDescription)")
        }
    }

    // --- Update Operations ---

    /// Toggles the 'isStarred' status for all messages within a specific chat.
    func toggleChatStarInDB(id: UUID, isStarred: Bool) throws {
        let sql = "UPDATE ChatMessages SET isStarred = ? WHERE chatId = ?;"
        let params: [Value] = [.integer(isStarred ? 1 : 0), .text(id.uuidString)]
        do {
            _ = try self.connection.execute(sql, params)
            print("Attempted toggle star (\(isStarred)) for all messages in Chat ID: \(id.uuidString)")
        } catch {
            print("‼️ Error toggling star for Chat \(id.uuidString): \(error)")
            throw DatabaseError.saveDataFailed("Failed to toggle star for Chat \(id.uuidString): \(error.localizedDescription)")
        }
    }

    /// Toggles the 'isStarred' status for a single ChatMessage.
    func toggleMessageStarInDB(id: UUID, isStarred: Bool) throws {
        let sql = "UPDATE ChatMessages SET isStarred = ? WHERE id = ?;"
        let params: [Value] = [.integer(isStarred ? 1 : 0), .text(id.uuidString)]
        do {
            _ = try self.connection.execute(sql, params)
            print("Attempted toggle star (\(isStarred)) for ChatMessage ID: \(id.uuidString)")
        } catch {
            print("‼️ Error toggling star for ChatMessage \(id.uuidString): \(error)")
            throw DatabaseError.saveDataFailed("Failed to toggle star for ChatMessage \(id.uuidString): \(error.localizedDescription)")
        }
    }


    // --- Search Operations ---
    func findSimilarJournalEntries(to queryVector: [Float], limit: Int = 5) throws -> [JournalEntry] {
        guard !queryVector.isEmpty else { return [] }
        guard queryVector.count == self.embeddingDimension else {
             throw DatabaseError.dimensionMismatch(expected: self.embeddingDimension, actual: queryVector.count)
        }
        guard let queryJSON = embeddingToJson(queryVector) else {
             throw DatabaseError.embeddingGenerationFailed("Failed to convert query vector to JSON.")
        }
        // ** FIXED JOIN CONDITION **
        let sql = """
            SELECT E.id, E.text, E.mood, E.date, E.intensity
            FROM JournalEntries AS E
            JOIN vector_top_k('journal_embedding_idx', vector32(?), ?) AS V
              ON E.rowid = V.rowid -- Join on rowid, which vector_top_k returns as 'rowid' or implicitly uses
            WHERE E.embedding IS NOT NULL
            ORDER BY V.distance ASC;
            """
        let params: [Value] = [.text(queryJSON), .integer(Int64(limit))]

        do {
            let rows = try self.connection.query(sql, params)
            var results: [JournalEntry] = []
            for row in rows {
                // Decoding logic remains the same, assuming SELECT clause is correct
                guard let idStr = try? row.getString(0), let id = UUID(uuidString: idStr),
                      let text = try? row.getString(1),
                      let moodStr = try? row.getString(2), let mood = Mood(rawValue: moodStr),
                      let dateTimestamp = try? row.getInt(3), let intensityInt = try? row.getInt(4)
                else { print("Warning: Failed decode JournalEntry row: \(row)"); continue }
                let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
                results.append(JournalEntry(id: id, text: text, mood: mood, date: date, intensity: Int(intensityInt)))
            }
            return results
        } catch {
            print("‼️ Error during findSimilarJournalEntries query: \(error)") // Log specific error
            throw DatabaseError.queryFailed("Find JournalEntries: \(error.localizedDescription)")
        }
    }

    func findSimilarChatMessages(to queryVector: [Float], limit: Int = 5) throws -> [(message: ChatMessage, chatId: UUID)] {
         guard !queryVector.isEmpty else { return [] }
         guard queryVector.count == self.embeddingDimension else {
              throw DatabaseError.dimensionMismatch(expected: self.embeddingDimension, actual: queryVector.count)
         }
         guard let queryJSON = embeddingToJson(queryVector) else {
              throw DatabaseError.embeddingGenerationFailed("Failed to convert query vector to JSON.")
         }
         // ** FIXED JOIN CONDITION **
         let sql = """
             SELECT M.id, M.chatId, M.text, M.isUser, M.date, M.isStarred
             FROM ChatMessages AS M
             JOIN vector_top_k('chat_embedding_idx', vector32(?), ?) AS V
               ON M.rowid = V.rowid -- Join on rowid
             WHERE M.embedding IS NOT NULL
             ORDER BY V.distance ASC;
             """
         let params: [Value] = [.text(queryJSON), .integer(Int64(limit))]

        do {
            let rows = try self.connection.query(sql, params)
            var results: [(message: ChatMessage, chatId: UUID)] = []
            for row in rows {
                 // Decoding logic remains the same
                 guard let idStr = try? row.getString(0), let id = UUID(uuidString: idStr),
                       let chatIdStr = try? row.getString(1), let chatId = UUID(uuidString: chatIdStr),
                       let text = try? row.getString(2),
                       let isUserInt = try? row.getInt(3), let dateTimestamp = try? row.getInt(4),
                       let isStarredInt = try? row.getInt(5)
                 else { print("Warning: Failed decode ChatMessage row: \(row)"); continue }
                 let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
                 let message = ChatMessage(id: id, text: text, isUser: isUserInt == 1, date: date, isStarred: isStarredInt == 1)
                 results.append((message: message, chatId: chatId))
            }
            return results
        } catch {
            print("‼️ Error during findSimilarChatMessages query: \(error)") // Log specific error
            throw DatabaseError.queryFailed("Find ChatMessages: \(error.localizedDescription)")
        }
    }

    // --- Load Operations ---

    /// Loads all JournalEntries from the database.
    func loadAllJournalEntries() throws -> [JournalEntry] {
        let sql = "SELECT id, text, mood, date, intensity FROM JournalEntries ORDER BY date DESC;"
        do {
            let rows = try self.connection.query(sql)
            var results: [JournalEntry] = []
            for row in rows {
                guard let idStr = try? row.getString(0), let id = UUID(uuidString: idStr),
                      let text = try? row.getString(1),
                      let moodStr = try? row.getString(2), let mood = Mood(rawValue: moodStr),
                      let dateTimestamp = try? row.getInt(3), let intensityInt = try? row.getInt(4)
                else {
                    print("Warning: Failed to decode JournalEntry row during loadAll: \(row)")
                    continue // Skip this row
                }
                let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
                results.append(JournalEntry(id: id, text: text, mood: mood, date: date, intensity: Int(intensityInt)))
            }
            print("Loaded \(results.count) journal entries from DB.")
            return results
        } catch {
            print("‼️ Error loading all JournalEntries: \(error)")
            throw DatabaseError.queryFailed("Load All JournalEntries: \(error.localizedDescription)")
        }
    }

    /// Loads all Chats by querying messages and reconstructing Chat objects.
    func loadAllChats() throws -> [Chat] {
        let sql = "SELECT id, chatId, text, isUser, date, isStarred FROM ChatMessages ORDER BY chatId ASC, date ASC;"

        do {
            let rows = try self.connection.query(sql)
            var messagesByChatId: [UUID: [ChatMessage]] = [:]

            for row in rows {
                guard let idStr = try? row.getString(0), let id = UUID(uuidString: idStr),
                      let chatIdStr = try? row.getString(1), let chatId = UUID(uuidString: chatIdStr),
                      let text = try? row.getString(2),
                      let isUserInt = try? row.getInt(3),
                      let dateTimestamp = try? row.getInt(4),
                      let isStarredInt = try? row.getInt(5)
                else {
                    print("Warning: Failed to decode ChatMessage row during loadAllChats grouping: \(row)")
                    continue
                }
                let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
                let message = ChatMessage(id: id, text: text, isUser: isUserInt == 1, date: date, isStarred: isStarredInt == 1)

                messagesByChatId[chatId, default: []].append(message)
            }

            var chats: [Chat] = []
            for (chatId, messages) in messagesByChatId {
                guard !messages.isEmpty else { continue }

                let sortedMessages = messages.sorted { $0.date < $1.date }
                let createdAt = sortedMessages.first!.date
                let lastUpdatedAt = sortedMessages.last!.date
                // Determine Chat's starred status based on any message being starred
                let isChatStarred = sortedMessages.contains { $0.isStarred }

                var chat = Chat(id: chatId, messages: sortedMessages, createdAt: createdAt, lastUpdatedAt: lastUpdatedAt, isStarred: isChatStarred)
                chat.generateTitle()
                chats.append(chat)
            }

            chats.sort { $0.lastUpdatedAt > $1.lastUpdatedAt }

            print("Loaded and reconstructed \(chats.count) chats from DB messages.")
            return chats

        } catch {
            print("‼️ Error loading all Chats: \(error)")
            throw DatabaseError.queryFailed("Load All Chats: \(error.localizedDescription)")
        }
    }
} // --- End of DatabaseService class ---
    