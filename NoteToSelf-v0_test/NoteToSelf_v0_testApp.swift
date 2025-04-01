import SwiftUI

@main
struct NoteToSelf_v0_testApp: App {
    // Initialize services and managers as StateObjects where needed.
    // DatabaseService might not need @StateObject if it has no @Published properties
    // and is only used for its methods. Let's try initializing it normally first.
    private var databaseService: DatabaseService
    private var llmService: LLMService // Assuming singleton access is fine
    @StateObject private var appState: AppState
    @StateObject private var subscriptionManager: SubscriptionManager
    @StateObject private var chatManager: ChatManager
    @StateObject private var themeManager: ThemeManager // Add ThemeManager

    init() {
        // Initialize Theme Manager First (it interacts with UIStyles singleton)
        let themeMgr = ThemeManager.shared
        _themeManager = StateObject(wrappedValue: themeMgr)

        // Initialize other services
        let dbService = DatabaseService()
        let llmSvc = LLMService.shared // Use singleton
        let subMgr = SubscriptionManager.shared // Use singleton
        let initialAppState = AppState() // Create initial instance

        // Assign to instance properties
        self.databaseService = dbService
        self.llmService = llmSvc

        // Initialize StateObjects using the created services
        _appState = StateObject(wrappedValue: initialAppState)
        _subscriptionManager = StateObject(wrappedValue: subMgr)
        _chatManager = StateObject(wrappedValue: ChatManager(
            databaseService: dbService,
            llmService: llmSvc,
            subscriptionManager: subMgr
        ))

        print("App Initialized: Services and Managers created in App init.")

        // Load initial AppState data AFTER services are initialized
        // Pass the instance directly to the loading function
        loadInitialAppStateData(databaseService: dbService, appState: initialAppState)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView() // Use MainTabView directly
                // Provide all necessary environment objects
                .environmentObject(appState)
                .environmentObject(chatManager)
                .environmentObject(subscriptionManager)
                .environmentObject(databaseService)
                .environmentObject(themeManager) // Inject ThemeManager
                // REMOVED: .environmentObject(llmService)
                // .preferredColorScheme(.dark) // REMOVED - Let theme/system control scheme
                // Removed onAppear here, data loading triggered from init
                // Add temporary developer theme toggle (Triple tap)
                .onTapGesture(count: 3) {
                    print("Triple tap detected - cycling theme.")
                    themeManager.cycleTheme()
                }
        }
    }

    // --- Load Initial AppState Data ---
    // Modified to accept appState instance as well
    private func loadInitialAppStateData(databaseService: DatabaseService, appState: AppState) {
        print("App: Triggering initial data load...")
        Task { // Keep async loading
            do {
                let entries = try databaseService.loadAllJournalEntries()
                await MainActor.run {
                    appState.journalEntries = entries
                    print("✅ Successfully loaded \(entries.count) journal entries into AppState.")
                }
            } catch {
                print("‼️ ERROR loading initial journal entries into AppState: \(error)")
                await MainActor.run {
                     appState.journalEntries = []
                }
            }
        }
    }

    // Migration logic remains commented out
    /*
    private func runInitialMigrationIfNeeded() { ... }
    */
}