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
    case deleteFailed(String)
    case noResultsFound
    case insightNotFound(String) // Specific error for insights
    case insightDecodingError(String)
}

// --- Service Class Definition ---
class DatabaseService: ObservableObject {
    // MARK: - Properties
    private let db: Database // Libsql Database object
    private let connection: Connection // Active connection to the database
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
                    embedding FLOAT32(\(self.embeddingDimension))
                );
                """
            )
            // ChatMessages Table
            _ = try self.connection.execute(
                """
                CREATE TABLE IF NOT EXISTS ChatMessages (
                    id TEXT PRIMARY KEY, chatId TEXT NOT NULL, text TEXT NOT NULL,
                    isUser INTEGER NOT NULL, date INTEGER NOT NULL, isStarred INTEGER NOT NULL,
                    embedding FLOAT32(\(self.embeddingDimension))
                );
                """
            )
            // GeneratedInsights Table
             _ = try self.connection.execute(
                 """
                 CREATE TABLE IF NOT EXISTS GeneratedInsights (
                     id TEXT PRIMARY KEY,
                     insightType TEXT UNIQUE NOT NULL,
                     generatedDate INTEGER NOT NULL,
                     relatedStartDate INTEGER,
                     relatedEndDate INTEGER,
                     jsonData TEXT NOT NULL
                 );
                 """
             )

            print("Database tables checked/created.")

            // Journal Entry Index
            _ = try self.connection.execute(
                """
                CREATE INDEX IF NOT EXISTS journal_embedding_idx
                ON JournalEntries( libsql_vector_idx(embedding) );
                """
            )
            // Chat Message Index
            _ = try self.connection.execute(
                """
                CREATE INDEX IF NOT EXISTS chat_embedding_idx
                ON ChatMessages( libsql_vector_idx(embedding) );
                """
            )
            print("Vector indexes checked/created.")

        } catch {
            print("Error during schema/index setup: \(error)")
            throw DatabaseError.schemaSetupFailed(error.localizedDescription)
        }
    }

    // MARK: - Journal Entry Operations

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
                 _ = try self.connection.execute(sql, params)
                 return
            }
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
        _ = try self.connection.execute(sql, params)
    }

    func deleteJournalEntry(id: UUID) throws {
        let sql = "DELETE FROM JournalEntries WHERE id = ?;"
        let params: [Value] = [.text(id.uuidString)]
        _ = try self.connection.execute(sql, params)
        print("Attempted delete for JournalEntry ID: \(id.uuidString)")
    }

    func loadAllJournalEntries() throws -> [JournalEntry] {
        let sql = "SELECT id, text, mood, date, intensity FROM JournalEntries ORDER BY date DESC;"
        let rows = try self.connection.query(sql)
        var results: [JournalEntry] = []
        for row in rows {
            guard let idStr = try? row.getString(0), let id = UUID(uuidString: idStr),
                  let text = try? row.getString(1),
                  let moodStr = try? row.getString(2), let mood = Mood(rawValue: moodStr),
                  let dateTimestamp = try? row.getInt(3),
                  let intensityInt = try? row.getInt(4)
            else {
                print("Warning: Failed to decode JournalEntry row during loadAll: \(row)")
                continue
            }
            let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
            results.append(JournalEntry(id: id, text: text, mood: mood, date: date, intensity: Int(intensityInt)))
        }
        print("Loaded \(results.count) journal entries from DB.")
        return results
    }

    func findSimilarJournalEntries(to queryVector: [Float], limit: Int = 5) throws -> [JournalEntry] {
        guard !queryVector.isEmpty else { return [] }
        guard queryVector.count == self.embeddingDimension else {
             throw DatabaseError.dimensionMismatch(expected: self.embeddingDimension, actual: queryVector.count)
        }
        guard let queryJSON = embeddingToJson(queryVector) else {
             throw DatabaseError.embeddingGenerationFailed("Failed to convert query vector to JSON.")
        }

        let sql = """
            SELECT E.id, E.text, E.mood, E.date, E.intensity,
                   vector_distance_cos(E.embedding, vector32(?)) AS distance
            FROM JournalEntries AS E
            JOIN vector_top_k('journal_embedding_idx', vector32(?), ?) AS V
              ON E.rowid = V.id
            WHERE E.embedding IS NOT NULL
            ORDER BY distance ASC;
            """
        let params: [Value] = [.text(queryJSON), .text(queryJSON), .integer(Int64(limit))]

        print("[DB Search] Executing corrected JournalEntries search...")
        let rows = try self.connection.query(sql, params)
        var results: [JournalEntry] = []
        for row in rows {
            guard let idStr = try? row.getString(0), let id = UUID(uuidString: idStr),
                  let text = try? row.getString(1),
                  let moodStr = try? row.getString(2), let mood = Mood(rawValue: moodStr),
                  let dateTimestamp = try? row.getInt(3),
                  let intensityInt = try? row.getInt(4)
            else { print("Warning: Failed decode JournalEntry row: \(row)"); continue }
            let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
            results.append(JournalEntry(id: id, text: text, mood: mood, date: date, intensity: Int(intensityInt)))
        }
        print("[DB Search] Corrected JournalEntries search successful. Found \(results.count) entries.")
        return results
    }

    // MARK: - Chat Message / Chat Operations

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
                 _ = try self.connection.execute(sql, params)
                 return
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
        _ = try self.connection.execute(sql, params)
    }

    func deleteChatFromDB(id: UUID) throws {
        let sql = "DELETE FROM ChatMessages WHERE chatId = ?;"
        let params: [Value] = [.text(id.uuidString)]
        _ = try self.connection.execute(sql, params)
        print("Attempted delete for all messages in Chat ID: \(id.uuidString)")
    }

    func deleteMessageFromDB(id: UUID) throws {
        let sql = "DELETE FROM ChatMessages WHERE id = ?;"
        let params: [Value] = [.text(id.uuidString)]
        _ = try self.connection.execute(sql, params)
        print("Attempted delete for ChatMessage ID: \(id.uuidString)")
    }

    func toggleChatStarInDB(id: UUID, isStarred: Bool) throws {
        let sql = "UPDATE ChatMessages SET isStarred = ? WHERE chatId = ?;"
        let params: [Value] = [.integer(isStarred ? 1 : 0), .text(id.uuidString)]
        _ = try self.connection.execute(sql, params)
        print("Attempted toggle star (\(isStarred)) for all messages in Chat ID: \(id.uuidString)")
    }

    func toggleMessageStarInDB(id: UUID, isStarred: Bool) throws {
        let sql = "UPDATE ChatMessages SET isStarred = ? WHERE id = ?;"
        let params: [Value] = [.integer(isStarred ? 1 : 0), .text(id.uuidString)]
        _ = try self.connection.execute(sql, params)
        print("Attempted toggle star (\(isStarred)) for ChatMessage ID: \(id.uuidString)")
    }

    func findSimilarChatMessages(to queryVector: [Float], limit: Int = 5) throws -> [(message: ChatMessage, chatId: UUID)] {
         guard !queryVector.isEmpty else { return [] }
         guard queryVector.count == self.embeddingDimension else {
              throw DatabaseError.dimensionMismatch(expected: self.embeddingDimension, actual: queryVector.count)
         }
         guard let queryJSON = embeddingToJson(queryVector) else {
              throw DatabaseError.embeddingGenerationFailed("Failed to convert query vector to JSON.")
         }

         let sql = """
             SELECT M.id, M.chatId, M.text, M.isUser, M.date, M.isStarred,
                    vector_distance_cos(M.embedding, vector32(?)) AS distance
             FROM ChatMessages AS M
             JOIN vector_top_k('chat_embedding_idx', vector32(?), ?) AS V
               ON M.rowid = V.id
             WHERE M.embedding IS NOT NULL
             ORDER BY distance ASC;
             """
         let params: [Value] = [.text(queryJSON), .text(queryJSON), .integer(Int64(limit))]

         print("[DB Search] Executing corrected ChatMessages search...")
        let rows = try self.connection.query(sql, params)
        var results: [(message: ChatMessage, chatId: UUID)] = []
        for row in rows {
             guard let idStr = try? row.getString(0), let id = UUID(uuidString: idStr),
                   let chatIdStr = try? row.getString(1), let chatId = UUID(uuidString: chatIdStr),
                   let text = try? row.getString(2),
                   let isUserInt = try? row.getInt(3),
                   let dateTimestamp = try? row.getInt(4),
                   let isStarredInt = try? row.getInt(5)
             else { print("Warning: Failed decode ChatMessage row: \(row)"); continue }
             let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
             let message = ChatMessage(id: id, text: text, isUser: isUserInt == 1, date: date, isStarred: isStarredInt == 1)
             results.append((message: message, chatId: chatId))
        }
        print("[DB Search] Corrected ChatMessages search successful. Found \(results.count) messages.")
        return results
    }

    func loadAllChats() throws -> [Chat] {
        let sql = "SELECT id, chatId, text, isUser, date, isStarred FROM ChatMessages ORDER BY chatId ASC, date ASC;"
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
            let isChatStarred = sortedMessages.contains { $0.isStarred }
            var chat = Chat(id: chatId, messages: sortedMessages, createdAt: createdAt, lastUpdatedAt: lastUpdatedAt, isStarred: isChatStarred)
            chat.generateTitle()
            chats.append(chat)
        }
        chats.sort { $0.lastUpdatedAt > $1.lastUpdatedAt }
        print("Loaded and reconstructed \(chats.count) chats from DB messages.")
        return chats
    }

    // MARK: - Generated Insight Operations (Phase 5)

    /// Saves or updates a generated insight JSON string for a specific type.
    func saveGeneratedInsight(type: String, date: Date, jsonData: String, startDate: Date? = nil, endDate: Date? = nil) throws {
        let sql = """
        INSERT OR REPLACE INTO GeneratedInsights (insightType, generatedDate, relatedStartDate, relatedEndDate, jsonData, id)
        VALUES (?, ?, ?, ?, ?, ?);
        """
        let uniqueId = UUID().uuidString
        let params: [Value] = [
            .text(type),
            .integer(Int64(date.timeIntervalSince1970)),
            startDate != nil ? .integer(Int64(startDate!.timeIntervalSince1970)) : .null,
            endDate != nil ? .integer(Int64(endDate!.timeIntervalSince1970)) : .null,
            .text(jsonData),
            .text(uniqueId)
        ]

        print("[DB Insight] Saving insight of type '\(type)'...")
        _ = try self.connection.execute(sql, params)
        print("✅ [DB Insight] Saved insight type '\(type)'.")
    }


    /// Loads the most recently generated insight JSON string for a specific type.
    /// NOTE: This is a synchronous function. Callers should dispatch to a background thread.
    func loadLatestInsight(type: String) throws -> (jsonData: String, generatedDate: Date)? {
        let sql = "SELECT jsonData, generatedDate FROM GeneratedInsights WHERE insightType = ?;"
        let params: [Value] = [.text(type)]

        print("[DB Insight] Loading latest insight of type '\(type)'...")
        let rows = try self.connection.query(sql, params) // Synchronous call

        // Iterate through rows, process the first one found
        for row in rows {
            guard let json = try? row.getString(0),
                  let dateTimestamp = try? row.getInt(1) else {
                print("‼️ [DB Insight] Failed to decode insight row for type '\(type)': \(row)")
                throw DatabaseError.insightDecodingError("Failed to decode columns for insight type '\(type)'")
            }

            let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
            print("[DB Insight] Loaded insight type '\(type)' generated on \(date.formatted()).")
            return (jsonData: json, generatedDate: date) // Return the first valid row
        }

        // If loop finishes without returning, no insight was found
        print("[DB Insight] No insight found for type '\(type)'.")
        return nil
    }


     /// Updates the timestamp of an existing insight without changing its data.
     /// NOTE: This is a synchronous function. Callers should dispatch to a background thread.
     func updateInsightTimestamp(type: String, date: Date) throws {
         let sql = "UPDATE GeneratedInsights SET generatedDate = ? WHERE insightType = ?;"
         let params: [Value] = [.integer(Int64(date.timeIntervalSince1970)), .text(type)]

         print("[DB Insight] Updating timestamp for insight type '\(type)'...")
         let affectedRows = try self.connection.execute(sql, params) // Synchronous call

         if affectedRows > 0 {
             print("✅ [DB Insight] Timestamp updated for insight type '\(type)'.")
         } else {
             print("⚠️ [DB Insight] Timestamp update attempted, but no insight found for type '\(type)'.")
             // Optionally throw an error or just log
             // throw DatabaseError.insightNotFound(type)
         }
     }


} // --- End of DatabaseService class ---