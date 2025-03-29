import SwiftUI

@main
struct NoteToSelf_v0_testApp: App {
    // Load AppState first if DatabaseService depends on it, or vice versa
    @StateObject private var appState = AppState()
    @StateObject private var databaseService = DatabaseService() // <-- Add this line
    @StateObject private var chatManager = ChatManager() // Consider if ChatManager needs DatabaseService injected

    // Removed the sample data loading from init() as it's now in AppState's init or a separate method

    var body: some Scene {
    WindowGroup {
        MainTabView()
            .environmentObject(appState)
            .environmentObject(chatManager)
            .environmentObject(databaseService)
            .preferredColorScheme(.dark)
    }
    }
}