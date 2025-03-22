import SwiftUI

@main
struct NoteToSelf_v0_testApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        appState.loadSampleData()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
        }
    }
}
