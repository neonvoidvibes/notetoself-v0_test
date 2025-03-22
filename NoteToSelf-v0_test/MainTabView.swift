import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    @State private var showingNavigation = false
    @State private var showingSettings = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground
                .ignoresSafeArea()
            
            // Main content
            ZStack {
                // Current tab content
                Group {
                    if selectedTab == 0 {
                        JournalView()
                    } else if selectedTab == 1 {
                        InsightsView()
                    } else if selectedTab == 2 {
                        ReflectionsView()
                    }
                }
                .offset(x: showingSettings ? -styles.layout.settingsMenuWidth * 0.3 : 0)
                .scaleEffect(showingSettings ? 0.9 : 1)
                
                // Navigation toggle button
                VStack {
                    Spacer()
                    
                    VStack(spacing: styles.layout.spacingXS) {
                        Text(showingNavigation ? "Close Navigation" : "Navigation")
                            .font(styles.typography.navLabel)
                            .foregroundColor(styles.colors.textSecondary)
                        
                        Button(action: {
                            withAnimation(styles.animation.defaultAnimation) {
                                showingNavigation.toggle()
                            }
                        }) {
                            Image(systemName: showingNavigation ? "chevron.up" : "chevron.down")
                                .font(.system(size: styles.layout.iconSizeM))
                                .foregroundColor(styles.colors.accent)
                                .frame(width: 44, height: 44)
                                .background(styles.colors.secondaryBackground.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, showingNavigation ? 120 : 20)
                }
                .zIndex(1)
                
                // Settings menu
                if showingSettings {
                    SettingsView()
                        .frame(width: styles.layout.settingsMenuWidth)
                        .transition(.move(edge: .trailing))
                        .offset(x: UIScreen.main.bounds.width - styles.layout.settingsMenuWidth)
                        .zIndex(2)
                }
            }
            .overlay(
                // Top bar with settings button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(styles.animation.defaultAnimation) {
                                showingSettings.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: styles.layout.iconSizeM))
                                .foregroundColor(styles.colors.accent)
                                .padding()
                        }
                    }
                    .padding(.top, styles.layout.topSafeAreaPadding)
                    
                    Spacer()
                }
                .zIndex(3)
            )
            
            // Custom tab bar (shown only when navigation is toggled)
            VStack {
                Spacer()
                
                if showingNavigation {
                    CustomTabBar(selectedTab: $selectedTab)
                        .transition(.move(edge: .bottom))
                        .zIndex(4)
                }
            }
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
            .foregroundColor(isSelected ? styles.colors.accent : styles.colors.textSecondary)
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
