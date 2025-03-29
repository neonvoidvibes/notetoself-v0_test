import Foundation
import CouchbaseLiteSwift // Import Couchbase Lite

// Import the Vector Search extension if needed (may or may not be required depending on how CBL packages it)
// If you get errors later about vector types not being found, uncomment the line below.
// import CouchbaseLiteSwiftVectorSearch

/// Manages data persistence using Couchbase Lite.
class DataManager {
    /// Shared singleton instance
    static let shared = DataManager()

    // --- Configuration ---
    private let databaseName = "notetoself-db"
    // Use literal names for default scope and collection
    let defaultScopeName = "_default"
    let defaultCollectionName = "_default"
    let journalCollectionName = "journal" // Example: Separate collection
    let chatCollectionName = "chats"       // Example: Separate collection
    let vectorIndexName = "embeddingVectorIndex" // Give it a descriptive name
    // NOTE: Ensure your actual embedding model outputs vectors of this size!
    let vectorDimensions: UInt = 384 // Specify as UInt for Couchbase config
    // --- End Configuration ---

    /// The Couchbase Lite database instance.
    private(set) var database: Database?
    /// The default collection within the database.
    private(set) var defaultCollection: Collection?
    // Add properties for other collections if using them:
    // private(set) var journalCollection: Collection?
    // private(set) var chatCollection: Collection?


    /// Private initializer to ensure singleton usage and set up the database.
    private init() {
        print("Initializing DataManager with Couchbase Lite...")
        do {
            // 1. Specify Database Configuration
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            var dbConfig = DatabaseConfiguration()
            // Store database in a subdirectory within Documents for better organization
            dbConfig.directory = documentsDirectory.appendingPathComponent(databaseName + ".cblite2").path

            // 2. Open (or Create) the Database
            // The database name is used as the directory name (.cblite2) within the specified config.directory
            database = try Database(name: databaseName, config: dbConfig)
            print("Couchbase Lite database opened successfully at: \(dbConfig.directory)")

            // 3. Get the Default Collection (or create/get others)
            // Use the correct default scope and collection names
            defaultCollection = try database?.collection(name: defaultCollectionName, scope: defaultScopeName)

            // Check if collection was obtained
            guard defaultCollection != nil else {
                 throw DataManagerError.collectionUnavailable // Throw if default collection couldn't be accessed
            }
            print("Default collection ('\(defaultCollectionName)') obtained.")

            // Example: Get or create custom collections if needed
            // journalCollection = try database?.createCollection(name: journalCollectionName, scope: defaultScopeName) ?? database?.collection(name: journalCollectionName, scope: defaultScopeName)
            // chatCollection = try database?.createCollection(name: chatCollectionName, scope: defaultScopeName) ?? database?.collection(name: chatCollectionName, scope: defaultScopeName)
            // print("Journal and Chat collections obtained/created.")

            // 4. Create Indexes (including Vector Index) - Do this *once*
            createIndexesIfNeeded()

        } catch {
            print("‼️ FATAL ERROR: Failed to initialize Couchbase Lite database: \(error.localizedDescription)")
            // In a real app, you might want more robust error handling.
            database = nil
            defaultCollection = nil
        }
    }

    /// Creates necessary indexes if they don't already exist.
    private func createIndexesIfNeeded() {
        guard let collection = defaultCollection else { // Use the specific collection you want to index
            print("‼️ Cannot create indexes: Default collection is not available.")
            return
        }

        do {
            let indexes = try collection.indexes()

            // --- Vector Index ---
            if !indexes.contains(vectorIndexName) {
                print("Creating vector index '\(vectorIndexName)'...")
                // Configuration for the vector index
                // Replace "embedding" with the actual field name you'll use in your documents
                let vectorConfig = VectorIndexConfiguration(
                                       expression: "embedding", // JSON field containing the vector array
                                       dimensions: vectorDimensions,
                                       centroids: 8 // Start with a small number, e.g., 8 or sqrt(expected_N)
                                    // metric: .cosine // Default is cosine squared / euclidean
                                   )

                 // Create the index
                 try collection.createVectorIndex(name: vectorIndexName, config: vectorConfig)
                 print("Vector index '\(vectorIndexName)' created successfully.")
            } else {
                 print("Vector index '\(vectorIndexName)' already exists.")
            }

            // --- Other Indexes (Example: Index on date for sorting) ---
            let dateIndexName = "dateIndex"
            if !indexes.contains(dateIndexName) {
                print("Creating value index '\(dateIndexName)' on 'date' field...")
                // Use Expression.property() to specify the field name
                let dateExpression = ValueIndexItem.expression(Expression.property("date"))
                try collection.createValueIndex(name: dateIndexName, config: ValueIndexConfiguration(items: [dateExpression]))
                 print("Value index '\(dateIndexName)' created successfully.")
            } else {
                 print("Value index '\(dateIndexName)' already exists.")
            }

        } catch {
            print("‼️ Error creating indexes: \(error.localizedDescription)")
        }
    }


    // MARK: - Persistence Management

    /// Closes the database cleanly. Call when app terminates or backgrounds.
    func closePersistence() {
        do {
            try database?.close()
            print("Couchbase Lite database closed.")
            database = nil
            defaultCollection = nil
        } catch {
            print("‼️ Error closing Couchbase Lite database: \(error.localizedDescription)")
        }
    }

    // MARK: - Basic Document Operations (Placeholders/Examples)

    /// Saves a Codable object as a document in the default collection.
    /// The object's `id` (if it conforms to Identifiable and id is String) can be used as document ID.
    func saveDocument<T: Codable & Identifiable>(_ object: T, id: String? = nil) throws where T.ID == String {
        guard let collection = defaultCollection else { throw DataManagerError.collectionUnavailable }
        let docId = id ?? object.id
        let dictionary = try objectToDictionary(object)
        let mutableDoc = MutableDocument(id: docId, data: dictionary)
        try collection.save(document: mutableDoc)
        print("Saved document with ID: \(docId)")
    }

    /// Fetches a document by ID and decodes it into a Codable object.
    func getDocument<T: Codable>(withId id: String) throws -> T? {
        guard let collection = defaultCollection else { throw DataManagerError.collectionUnavailable }
        guard let document = try collection.document(id: id) else { return nil }
        return try dictionaryToObject(document.toDictionary())
    }

    /// Deletes a document by ID.
    func deleteDocument(withId id: String) throws {
         guard let collection = defaultCollection else { throw DataManagerError.collectionUnavailable }
         if let document = try collection.document(id: id) {
             try collection.delete(document: document)
             print("Deleted document with ID: \(id)")
         } else {
             print("Warning: Document with ID \(id) not found for deletion.")
         }
    }

    // MARK: - Vector Search (Placeholder/Example)

    /// Performs a vector similarity search.
    /// Assumes documents have an 'embedding' field matching the index config.
    /// Returns raw SearchResult objects for now.
    func findSimilarEntries(queryVector: [Float], k: Int) throws -> [Any] {
         guard let collection = defaultCollection else { throw DataManagerError.collectionUnavailable }

         // Create the vector search query using prediction
         // NOTE: CBL uses a placeholder 'model' name here. How you link this to an actual
         // embedding function/model needs investigation in CBL docs/examples.
         // For now, we construct the query assuming 'embedding' is the query vector property.
         // A common pattern is to have the query itself provide the vector.

         // Let's try QueryBuilder approach:
         // SELECT meta().id FROM _ WHERE vector_match(vectorIndexName, embedding, ?) LIMIT ?
         // The '?' needs to be bound to the query vector.

         let query = QueryBuilder
            .select(SelectResult.expression(Meta.id)) // Select document ID
            .from(DataSource.collection(collection))
            // The WHERE clause uses the vectorMatch function
            .where(VectorMatchFunction.match(index: vectorIndexName, vector: queryVector))
            // Order by vector distance (implicit in match? Check CBL docs)
            // .orderBy(Ordering.expression( ??? How to order by match score ???)) // Ordering might be implicit or need specific syntax
            .limit(Expression.int(k))


         print("Executing vector search...")
         let results = try query.execute()
         let allRawResults = results.allResults()
         print("Vector search found \(allRawResults.count) potential matches.")

         // TODO: Process results correctly - extract ID and potentially score/distance
         // The structure of SearchResult and how vector match score is accessed needs checking in CBL docs v3.2
         return allRawResults
    }


    // MARK: - Codable Helpers

    private func objectToDictionary<T: Codable>(_ object: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(object)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw DataManagerError.encodingError
        }
        return dictionary
    }

    private func dictionaryToObject<T: Codable>(_ dictionary: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        // Use a date decoding strategy if your Codable structs use Date
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Or .secondsSince1970, etc. Choose one.
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Custom Errors
enum DataManagerError: Error {
    case databaseUnavailable
    case collectionUnavailable
    case encodingError
    case decodingError
    case indexCreationFailed
}