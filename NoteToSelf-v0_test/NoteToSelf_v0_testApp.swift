import SwiftUI
import NaturalLanguage
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
            .onAppear { // <-- The code you just added starts here
                // --- Temporary code to find embedding dimension ---
                #if canImport(NaturalLanguage)
                if #available(iOS 16.0, *) {
                    if let embeddingModel = NLEmbedding.sentenceEmbedding(for: .english) {
                        let dimension = embeddingModel.dimension
                        print("✅ NLEmbedding Dimension: \(dimension)")
                    } else {
                        print("❌ Failed to load NLEmbedding model.")
                    }
                } else {
                    print("ℹ️ NLEmbedding requires iOS 16 or later.")
                }
                #else
                    print("❌ NaturalLanguage framework not available.")
                #endif
                // --- End of temporary code ---
            } // <-- The code you just added ends here
    }
    }
}