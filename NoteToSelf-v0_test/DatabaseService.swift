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

        // Temporary variables needed because self cannot be used before all properties are initialized
        let tempDb: Database
        let tempConnection: Connection

        do {
            // Step 1: Initialize Database Object
            tempDb = try Database(dbPath)
            print("Database object created.")

            // Step 2: Establish Connection
            tempConnection = try tempDb.connect()
            print("Database connection established.")

            // --- Assign to class properties AFTER successful initialization ---
            self.db = tempDb
            self.connection = tempConnection

            // --- Step 3: Setup Schema and Indexes ---
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
            // --- Table Creation ---
            _ = try self.connection.execute(
                """
                CREATE TABLE IF NOT EXISTS JournalEntries (
                    id TEXT PRIMARY KEY,
                    text TEXT NOT NULL,
                    mood TEXT NOT NULL,
                    date INTEGER NOT NULL,      -- Unix timestamp (Int64)
                    intensity INTEGER NOT NULL,
                    embedding FLOAT32(\(self.embeddingDimension)) -- Try FLOAT32(512) syntax directly
                );
                """
            )
            _ = try self.connection.execute(
                """
                CREATE TABLE IF NOT EXISTS ChatMessages (
                    id TEXT PRIMARY KEY,
                    chatId TEXT NOT NULL,
                    text TEXT NOT NULL,
                    isUser INTEGER NOT NULL,    -- Boolean as Int64 (0 or 1)
                    date INTEGER NOT NULL,      -- Unix timestamp (Int64)
                    isStarred INTEGER NOT NULL,
                    embedding FLOAT32(\(self.embeddingDimension)) -- Try FLOAT32(512) syntax directly
                );
                """
            )
            print("Database tables checked/created.")

            // --- Index Creation ---
            // Explicitly pass dimension to the index: 'dim=...'
            // Revert index creation to basic form - hoping dimension is inferred from column
            _ = try self.connection.execute(
                """
                CREATE INDEX IF NOT EXISTS journal_embedding_idx
                ON JournalEntries( libsql_vector_idx(embedding) );
                """ // Removed explicit dimension parameter
            )
            // Explicitly pass dimension to the index: 'dim=...'
            // Revert index creation to basic form - hoping dimension is inferred from column
            _ = try self.connection.execute(
                """
                CREATE INDEX IF NOT EXISTS chat_embedding_idx
                ON ChatMessages( libsql_vector_idx(embedding) );
                """ // Removed explicit dimension parameter
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
        let helperEmbeddingToJson = embeddingToJson // Local ref to global helper

        if let validEmbedding = embedding, validEmbedding.count == self.embeddingDimension {
            let embJSON = helperEmbeddingToJson(validEmbedding)
            let safeEmbJSON = embJSON.replacingOccurrences(of: "'", with: "''") // Basic escaping

            // Using interpolation for vector32 for debugging
            sql = """
                INSERT OR REPLACE INTO JournalEntries (id, text, mood, date, intensity, embedding)
                VALUES (?, ?, ?, ?, ?, vector32('\(safeEmbJSON)'));
                """
            params = [
                .text(entry.id.uuidString), .text(entry.text), .text(entry.mood.rawValue),
                .integer(Int64(entry.date.timeIntervalSince1970)), .integer(Int64(entry.intensity))
            ]
             guard params.count == 5 else { throw DatabaseError.saveDataFailed("Param count mismatch (JournalEntry/Embed)") }
        } else {
            // Handle missing or mismatched embedding
            if embedding != nil { print("Warning: Dimension mismatch for JournalEntry \(entry.id). Saving without embedding.") }
            else { print("Warning: Saving JournalEntry \(entry.id) without embedding (nil).") }
            sql = """
                INSERT OR REPLACE INTO JournalEntries (id, text, mood, date, intensity, embedding)
                VALUES (?, ?, ?, ?, ?, NULL);
                """
            params = [
                .text(entry.id.uuidString), .text(entry.text), .text(entry.mood.rawValue),
                .integer(Int64(entry.date.timeIntervalSince1970)), .integer(Int64(entry.intensity))
            ]
             guard params.count == 5 else { throw DatabaseError.saveDataFailed("Param count mismatch (JournalEntry/NoEmbed)") }
        }

        do {
            _ = try self.connection.execute(sql, params)
            print("Database execute call completed for JournalEntry \(entry.id).")
        } catch {
            // Catch any error from execute
            print("‼️ Error saving JournalEntry \(entry.id): \(error)")
            throw DatabaseError.saveDataFailed("JournalEntry \(entry.id): \(error.localizedDescription)")
        }
    }

    func saveChatMessage(_ message: ChatMessage, chatId: UUID, embedding: [Float]?) throws {
        let sql: String
        let params: [Value]
        let helperEmbeddingToJson = embeddingToJson // Local ref to global helper

         if let validEmbedding = embedding, validEmbedding.count == self.embeddingDimension {
            let embJSON = helperEmbeddingToJson(validEmbedding)
            let safeEmbJSON = embJSON.replacingOccurrences(of: "'", with: "''") // Basic escaping

            // Using interpolation for vector32 for debugging
            sql = """
                INSERT OR REPLACE INTO ChatMessages (id, chatId, text, isUser, date, isStarred, embedding)
                VALUES (?, ?, ?, ?, ?, ?, vector32('\(safeEmbJSON)'));
                """
            params = [
                .text(message.id.uuidString), .text(chatId.uuidString), .text(message.text),
                .integer(message.isUser ? 1 : 0), .integer(Int64(message.date.timeIntervalSince1970)),
                .integer(message.isStarred ? 1 : 0)
            ]
             guard params.count == 6 else { throw DatabaseError.saveDataFailed("Param count mismatch (ChatMessage/Embed)") }
         } else {
             if embedding != nil { print("Warning: Dimension mismatch for ChatMessage \(message.id). Saving without embedding.") }
             else { print("Warning: Saving ChatMessage \(message.id) without embedding (nil).") }
             sql = """
                 INSERT OR REPLACE INTO ChatMessages (id, chatId, text, isUser, date, isStarred, embedding)
                 VALUES (?, ?, ?, ?, ?, ?, NULL);
                 """
             params = [
                 .text(message.id.uuidString), .text(chatId.uuidString), .text(message.text),
                 .integer(message.isUser ? 1 : 0), .integer(Int64(message.date.timeIntervalSince1970)),
                 .integer(message.isStarred ? 1 : 0)
             ]
              guard params.count == 6 else { throw DatabaseError.saveDataFailed("Param count mismatch (ChatMessage/NoEmbed)") }
         }

        do {
            _ = try self.connection.execute(sql, params)
            print("Database execute call completed for ChatMessage \(message.id).")
        } catch {
            // Catch any error from execute
            print("‼️ Error saving ChatMessage \(message.id): \(error)")
            throw DatabaseError.saveDataFailed("ChatMessage \(message.id): \(error.localizedDescription)")
        }
    }

    // --- Search Operations ---
    func findSimilarJournalEntries(to queryVector: [Float], limit: Int = 5) throws -> [JournalEntry] {
        guard !queryVector.isEmpty else { return [] }
        guard queryVector.count == self.embeddingDimension else {
             throw DatabaseError.dimensionMismatch(expected: self.embeddingDimension, actual: queryVector.count)
        }
        let queryJSON = embeddingToJson(queryVector)
        let sql = """
            SELECT E.id, E.text, E.mood, E.date, E.intensity
            FROM JournalEntries AS E
            JOIN vector_top_k('journal_embedding_idx', vector32(?), ?) AS V
              ON E.id = V.id COLLATE NOCASE
            WHERE E.embedding IS NOT NULL
            ORDER BY V.distance ASC;
            """
        let params: [Value] = [.text(queryJSON), .integer(Int64(limit))]

        do {
            let rows = try self.connection.query(sql, params)
            var results: [JournalEntry] = []
            for row in rows {
                guard let idStr = try? row.getString(0), let id = UUID(uuidString: idStr),
                      let text = try? row.getString(1),
                      let moodStr = try? row.getString(2), let mood = Mood(rawValue: moodStr),
                      let dateTimestamp = try? row.getInt(3), let intensityInt = try? row.getInt(4)
                else { print("Warning: Failed decode JournalEntry row: \(row)"); continue }
                let date = Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
                results.append(JournalEntry(id: id, text: text, mood: mood, date: date, intensity: Int(intensityInt)))
            }
            return results
        } catch { throw DatabaseError.queryFailed("Find JournalEntries: \(error.localizedDescription)") }
    }

    func findSimilarChatMessages(to queryVector: [Float], limit: Int = 5) throws -> [(message: ChatMessage, chatId: UUID)] {
         guard !queryVector.isEmpty else { return [] }
         guard queryVector.count == self.embeddingDimension else {
              throw DatabaseError.dimensionMismatch(expected: self.embeddingDimension, actual: queryVector.count)
         }
         let queryJSON = embeddingToJson(queryVector)
         let sql = """
             SELECT M.id, M.chatId, M.text, M.isUser, M.date, M.isStarred
             FROM ChatMessages AS M
             JOIN vector_top_k('chat_embedding_idx', vector32(?), ?) AS V
               ON M.id = V.id COLLATE NOCASE
             WHERE M.embedding IS NOT NULL
             ORDER BY V.distance ASC;
             """
         let params: [Value] = [.text(queryJSON), .integer(Int64(limit))]

        do {
            let rows = try self.connection.query(sql, params)
            var results: [(message: ChatMessage, chatId: UUID)] = []
            for row in rows {
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
        } catch { throw DatabaseError.queryFailed("Find ChatMessages: \(error.localizedDescription)") }
    }

    // TODO: Add methods for deleting, loading specific items, etc. as needed later.

} // --- End of DatabaseService class ---


// MARK: - Global Embedding Generation Helpers (Outside Class)
// Needs 'import NaturalLanguage' at the top of the file.

// Corrected Embedding Dimension (Matches class property)
fileprivate let EXPECTED_EMBEDDING_DIMENSION = 512

// Internal cache for the embedding model
@available(iOS 16.0, *)
private struct EmbeddingModelProvider {
    static let sharedModel: NLEmbedding? = {
        let model = NLEmbedding.sentenceEmbedding(for: .english)
        if model == nil { print("‼️ Error: Failed to load NLEmbedding sentence model for English.") }
        else if let loadedModel = model, loadedModel.dimension != EXPECTED_EMBEDDING_DIMENSION {
             print("‼️ Error: Loaded NLEmbedding dimension (\(loadedModel.dimension)) doesn't match EXPECTED (\(EXPECTED_EMBEDDING_DIMENSION)).")
        }
        return model
    }()
}

/// Generates a sentence embedding for the given text using NLEmbedding (iOS 16+).
// Made this function internal (default access)
func generateEmbedding(for text: String) -> [Float]? {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    if #available(iOS 16.0, *) {
        guard let embeddingModel = EmbeddingModelProvider.sharedModel else { return nil }
        guard let vector = embeddingModel.vector(for: text) else { return nil }
        let floatVector = vector.map { Float($0) }
        guard floatVector.count == EXPECTED_EMBEDDING_DIMENSION else { return nil }
        return floatVector
    } else { return nil }
}

/// Converts a list of Float numbers into a JSON array string for libSQL's vector32 function.
// Made this function internal (default access)
func embeddingToJson(_ embedding: [Float]) -> String {
    let numberStrings = embedding.map { String(format: "%.8f", $0) }
    return "[" + numberStrings.joined(separator: ",") + "]"
}