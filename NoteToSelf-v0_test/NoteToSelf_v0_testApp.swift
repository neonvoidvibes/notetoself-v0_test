import SwiftUI

@main
struct NoteToSelf_v0_testApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // Load sample data
        let appState = AppState()
        appState.loadSampleData()
        self._appState = StateObject(wrappedValue: appState)
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}
