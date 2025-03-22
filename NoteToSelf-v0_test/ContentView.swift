import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var hasSeenOnboarding: Bool = false
    
    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                .environmentObject(appState)
        } else {
            MainTabView()
                .environmentObject(appState)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
