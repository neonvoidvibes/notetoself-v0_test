import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background
            styles.colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with settings button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: styles.layout.iconSizeM))
                            .foregroundColor(styles.colors.accent)
                    }
                    .padding(.trailing, styles.layout.paddingL)
                    .padding(.top, styles.layout.paddingM)
                }
                
                // Tab content
                TabView(selection: $selectedTab) {
                    JournalView()
                        .tag(0)
                    
                    InsightsView()
                        .tag(1)
                    
                    ReflectionsView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom tab bar
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .environmentObject(appState)
        .preferredColorScheme(.dark)
        .onAppear {
            // Load sample data for preview
            appState.loadSampleData()
            
            // Check if user has seen onboarding
            if !appState.hasSeenOnboarding {
                // In a real app, you would present the onboarding flow here
                appState.hasSeenOnboarding = true
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        HStack {
            Spacer()
            
            // Journal tab
            TabBarButton(
                icon: "book.fill",
                title: "Journal",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            Spacer()
            
            // Insights tab
            TabBarButton(
                icon: "chart.bar.fill",
                title: "Insights",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            Spacer()
            
            // Reflections tab
            TabBarButton(
                icon: "bubble.left.fill",
                title: "Reflections",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
            
            Spacer()
        }
        .padding(.vertical, styles.layout.paddingM)
        .background(styles.colors.tabBarBackground)
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: styles.layout.spacingXS) {
                Image(systemName: icon)
                    .font(.system(size: styles.layout.iconSizeM))
                
                Text(title)
                    .font(styles.typography.caption)
            }
            .foregroundColor(isSelected ? styles.colors.accent : styles.colors.tabBarInactive)
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
