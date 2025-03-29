import SwiftUI

@main
struct NoteToSelf_v0_testApp: App {
    // Create services before @StateObject declarations to avoid capturing self
    private let dbService = DatabaseService()
    private let appStateService = AppState()
    private let chatManagerService: ChatManager
    
    // Initialize StateObjects with pre-created services
    @StateObject private var databaseService: DatabaseService
    @StateObject private var appState: AppState 
    @StateObject private var chatManager: ChatManager

    // Define UserDefaults key for migration flag
    private let migrationKey = "didRunLibSQLMigration_v1"
    
    init() {
        // Initialize ChatManager with DatabaseService
        chatManagerService = ChatManager(databaseService: dbService)
        
        // Initialize StateObjects with our pre-created instances
        _databaseService = StateObject(wrappedValue: dbService)
        _appState = StateObject(wrappedValue: appStateService)
        _chatManager = StateObject(wrappedValue: chatManagerService)
    }

    var body: some Scene {
    WindowGroup {
        MainTabView()
            .environmentObject(appState)
            .environmentObject(chatManager)
            .environmentObject(databaseService)
            .preferredColorScheme(.dark)
            .onAppear {
                // Run migration first if needed (this runs async)
                runInitialMigrationIfNeeded()

                // Then load initial data from DB for AppState
                // This should run after potential migration finishes,
                // but for simplicity, we run it here. If migration is slow,
                // the initial load might fetch data before migration completes.
                // A more robust solution might use completion handlers or async/await.
                // For now, load directly.
                loadInitialAppStateData()
            }
    }
    } // End of body Scene

    // --- Load Initial AppState Data ---
    private func loadInitialAppStateData() {
        Task { // Run loading in a background task
            do {
                let entries = try databaseService.loadAllJournalEntries()
                // Switch back to main thread to update @Published property
                await MainActor.run {
                    appState.journalEntries = entries
                    print("Successfully loaded \(entries.count) journal entries into AppState.")
                }
            } catch {
                print("‼️ ERROR loading initial journal entries into AppState: \(error)")
                // Handle error appropriately, maybe show an alert or load empty state
                await MainActor.run {
                     appState.journalEntries = [] // Ensure it's empty on error
                }
            }
        }
    }

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
                    // Use await to access MainActor-isolated property from background
                    let entriesToMigrate = await appState.journalEntries
                    for entry in entriesToMigrate {
                        let embedding = generateEmbedding(for: entry.text)
                        try await databaseService.saveJournalEntry(entry, embedding: embedding)
                        // Add a small delay to avoid overwhelming CPU/DB if needed
                        // try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    }
                    // Use await to access MainActor-isolated property from background
                    print("Finished migrating \(await appState.journalEntries.count) Journal Entries.")

                    // 2. Migrate Chat Messages (from ChatManager's loaded UserDefaults data)
                    print("Migrating Chat Messages...")
                    var migratedMessageCount = 0
                    // Use await to access MainActor-isolated property from background
                    let chatsToMigrate = await chatManager.chats
                    for chat in chatsToMigrate {
                        for message in chat.messages {
                            let embedding = generateEmbedding(for: message.text)
                            try await databaseService.saveChatMessage(message, chatId: chat.id, embedding: embedding)
                            migratedMessageCount += 1
                            // Add a small delay if needed
                            // try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                        }
                    }
                     // Use await to access MainActor-isolated property from background
                    print("Finished migrating \(migratedMessageCount) Chat Messages from \(await chatManager.chats.count) chats.")

                    // 3. Set the migration flag upon successful completion
                    // Accessing defaults is synchronous, no await needed here
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
