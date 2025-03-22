import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var tabBarOffset: CGFloat = 0
    @State private var lastScrollPosition: CGFloat = 0
    @State private var tabBarVisible = true
    @State private var settingsOffset: CGFloat = UIScreen.main.bounds.width
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground
                .ignoresSafeArea()
            
            // Main content
            ZStack {
                // Current tab content with parallax effect
                Group {
                    if selectedTab == 0 {
                        JournalView(tabBarOffset: $tabBarOffset, lastScrollPosition: $lastScrollPosition, tabBarVisible: $tabBarVisible)
                    } else if selectedTab == 1 {
                        InsightsView(tabBarOffset: $tabBarOffset, lastScrollPosition: $lastScrollPosition, tabBarVisible: $tabBarVisible)
                    } else if selectedTab == 2 {
                        ReflectionsView(tabBarOffset: $tabBarOffset, lastScrollPosition: $lastScrollPosition, tabBarVisible: $tabBarVisible)
                    }
                }
                .offset(x: showingSettings ? -UIScreen.main.bounds.width * 0.85 : 0)
                .scaleEffect(showingSettings ? 0.85 : 1)
                .cornerRadius(showingSettings ? 30 : 0)
                .shadow(color: Color.black.opacity(showingSettings ? 0.2 : 0), radius: 20, x: 0, y: 0)
                .blur(radius: showingSettings ? 2 : 0)
                
                // Settings view
                SettingsView()
                    .frame(width: UIScreen.main.bounds.width)
                    .offset(x: settingsOffset)
                    .zIndex(2)
            }
            .overlay(
                // Top bar with settings button
                VStack {
                    HStack {
                        if showingSettings {
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showingSettings.toggle()
                                    settingsOffset = UIScreen.main.bounds.width
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(styles.colors.accent)
                                    .frame(width: 36, height: 36)
                                    .background(styles.colors.secondaryBackground.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .padding(.leading, 20)
                            .transition(.scale.combined(with: .opacity))
                            
                            Spacer()
                        } else {
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showingSettings.toggle()
                                    settingsOffset = 0
                                }
                            }) {
                                VStack(spacing: 5) {
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 20, height: 2)
                                        .cornerRadius(1)
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 14, height: 2)
                                        .cornerRadius(1)
                                }
                                .frame(width: 36, height: 36)
                                .background(styles.colors.secondaryBackground.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            }
                            .padding(.trailing, 20)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.top, styles.layout.topSafeAreaPadding - 10)
                    .zIndex(100)
                    
                    Spacer()
                }
                .zIndex(3)
            )
            
            // Modern floating tab bar
            VStack {
                Spacer()
                
                ModernTabBar(selectedTab: $selectedTab, visible: tabBarVisible)
                    .offset(y: tabBarOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tabBarOffset)
            }
            .ignoresSafeArea(.keyboard)
            .zIndex(4)
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

struct ModernTabBar: View {
    @Binding var selectedTab: Int
    var visible: Bool
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Blurred background
            BlurView(style: .systemUltraThinMaterialDark)
                .frame(height: 70)
                .cornerRadius(25)
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
                .padding(.horizontal, 40)
            
            // Tab buttons
            HStack(spacing: 0) {
                Spacer()
                
                // Journal tab
                ModernTabButton(
                    icon: "book.fill",
                    title: "Journal",
                    isSelected: selectedTab == 0,
                    action: { withAnimation { selectedTab = 0 } }
                )
                
                Spacer()
                
                // Insights tab
                ModernTabButton(
                    icon: "chart.bar.fill",
                    title: "Insights",
                    isSelected: selectedTab == 1,
                    action: { withAnimation { selectedTab = 1 } }
                )
                
                Spacer()
                
                // Reflections tab
                ModernTabButton(
                    icon: "bubble.left.fill",
                    title: "Reflections",
                    isSelected: selectedTab == 2,
                    action: { withAnimation { selectedTab = 2 } }
                )
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 70)
        }
        .padding(.bottom, 20)
        .opacity(visible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: visible)
    }
}

struct ModernTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Background circle for selected tab
                    Circle()
                        .fill(isSelected ? styles.colors.accent.opacity(0.2) : Color.clear)
                        .frame(width: 48, height: 48)
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? styles.colors.accent : styles.colors.textSecondary)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                
                // Title
                Text(title)
                    .font(styles.typography.caption)
                    .foregroundColor(isSelected ? styles.colors.accent : styles.colors.textSecondary)
                    .opacity(isSelected ? 1 : 0.7)
            }
            .frame(width: 80)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
