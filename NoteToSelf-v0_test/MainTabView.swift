import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            JournalView()
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("Journal")
                }
            // Replace with actual InsightsView when available
            Text("Insights View Placeholder")
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Insights")
                }
            // Replace with actual ReflectionsView when available
            Text("Reflections View Placeholder")
                .tabItem {
                    Image(systemName: "quote.bubble")
                    Text("Reflections")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}