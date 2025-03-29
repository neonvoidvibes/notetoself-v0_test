import SwiftUI

@main
struct NoteToSelf_v0_testApp: App {
    // Load AppState first if DatabaseService depends on it, or vice versa
    // Instantiate DatabaseService first as ChatManager depends on it
    @StateObject private var databaseService = DatabaseService()
    @StateObject private var appState = AppState() // AppState might load sample data initially
    // Update ChatManager init to pass DatabaseService
    @StateObject private var chatManager: ChatManager

    // Define UserDefaults key for migration flag
    private let migrationKey = "didRunLibSQLMigration_v1"

    init() {
        // Initialize ChatManager with DatabaseService
        // Must be done in init because databaseService needs to exist first
        _chatManager = StateObject(wrappedValue: ChatManager(databaseService: databaseService))
    }

    var body: some Scene {
    WindowGroup {
        MainTabView()
            .environmentObject(appState)
            .environmentObject(chatManager)
            .environmentObject(databaseService)
            .preferredColorScheme(.dark)
            .onAppear {
                runInitialMigrationIfNeeded()
            }
    }
    } // End of body Scene

    // --- Migration Logic ---
    private func runInitialMigrationIfNeeded() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: migrationKey) {
            print("Migration flag '\(migrationKey)' not found. Running initial data migration...")

            // Run migration in a background task to avoid blocking the UI
            Task.detached(priority: .background) {
                do {
                    // 1. Migrate Journal Entries (from AppState's initial sample data)
                    print("Migrating Journal Entries...")
                    for entry in appState.journalEntries {
                        let embedding = generateEmbedding(for: entry.text)
                        try await databaseService.saveJournalEntry(entry, embedding: embedding)
                        // Add a small delay to avoid overwhelming CPU/DB if needed
                        // try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    }
                    print("Finished migrating \(appState.journalEntries.count) Journal Entries.")

                    // 2. Migrate Chat Messages (from ChatManager's loaded UserDefaults data)
                    print("Migrating Chat Messages...")
                    var migratedMessageCount = 0
                    for chat in chatManager.chats {
                        for message in chat.messages {
                            let embedding = generateEmbedding(for: message.text)
                            try await databaseService.saveChatMessage(message, chatId: chat.id, embedding: embedding)
                            migratedMessageCount += 1
                            // Add a small delay if needed
                            // try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                        }
                    }
                    print("Finished migrating \(migratedMessageCount) Chat Messages from \(chatManager.chats.count) chats.")

                    // 3. Set the migration flag upon successful completion
                    defaults.set(true, forKey: migrationKey)
                    print("Successfully set migration flag '\(migrationKey)'.")

                } catch {
                    // Log the error, but still consider setting the flag
                    // to avoid retrying a potentially failing migration repeatedly.
                    // Alternatively, implement more robust error handling/retry logic.
                    print("‼️ ERROR during initial data migration: \(error)")
                    // Optionally set the flag even on error to prevent loops:
                    // defaults.set(true, forKey: migrationKey)
                    // print("Set migration flag '\(migrationKey)' even after error to prevent retries.")
                }
            }
        } else {
            print("Migration flag '\(migrationKey)' is set. Skipping initial migration.")
        }
    }
}
