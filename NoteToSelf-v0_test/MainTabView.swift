import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var bottomSheetOffset: CGFloat = 0
    @State private var bottomSheetExpanded = false
    @State private var isDragging = false
    @State private var settingsOffset: CGFloat = UIScreen.main.bounds.width

    // Access shared styles
    private let styles = UIStyles.shared

    // Calculated properties for layout
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private var peekHeight: CGFloat {
        styles.layout.bottomSheetPeekHeight
    }
    
    private var fullSheetHeight: CGFloat {
        styles.layout.bottomSheetFullHeight
    }
    
    // Drag gesture for the bottom sheet
    private var bottomSheetDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                let dragAmount = value.translation.height
                let newOffset = max(0, min(peekHeight - fullSheetHeight, bottomSheetOffset + dragAmount))
                bottomSheetOffset = newOffset
            }
            .onEnded { value in
                isDragging = false
                let dragAmount = value.translation.height
                let dragVelocity = value.predictedEndTranslation.height - value.translation.height
                if dragAmount + dragVelocity < 0 && dragAmount < -20 {
                    withAnimation(styles.animation.bottomSheetAnimation) {
                        bottomSheetExpanded = true
                    }
                } else if dragAmount > 20 || dragVelocity > 500 {
                    withAnimation(styles.animation.bottomSheetAnimation) {
                        bottomSheetOffset = peekHeight - fullSheetHeight
                        bottomSheetExpanded = false
                    }
                } else {
                    let snapUpThreshold = (peekHeight - fullSheetHeight) * 0.3
                    withAnimation(styles.animation.bottomSheetAnimation) {
                        if bottomSheetOffset < snapUpThreshold {
                            bottomSheetOffset = 0
                            bottomSheetExpanded = true
                        } else {
                            bottomSheetOffset = peekHeight - fullSheetHeight
                            bottomSheetExpanded = false
                        }
                    }
                }
            }
    }
    
    var body: some View {
        ZStack {
            // Background
            styles.colors.bottomSheetBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content with universal card style
                Group {
                    if selectedTab == 0 {
                        JournalView(
                            tabBarOffset: .constant(0),
                            lastScrollPosition: .constant(0),
                            tabBarVisible: .constant(true)
                        )
                    } else if selectedTab == 1 {
                        InsightsView(
                            tabBarOffset: .constant(0),
                            lastScrollPosition: .constant(0),
                            tabBarVisible: .constant(true)
                        )
                    } else if selectedTab == 2 {
                        ReflectionsView(
                            tabBarOffset: .constant(0),
                            lastScrollPosition: .constant(0),
                            tabBarVisible: .constant(true)
                        )
                    }
                }
                .mainCardStyle()
                .overlay(
                    // Settings menu button overlay remains outside the card style
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showingSettings = true
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
                            .padding(.top, styles.layout.topSafeAreaPadding - 10)
                        }
                        Spacer()
                    }
                )
                .offset(x: showingSettings ? -screenWidth : 0)
                .scaleEffect(showingSettings ? 0.85 : 1)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSettings)
                
                // Bottom navigation area with gray background extended to the screen bottom
                VStack(spacing: 0) {
                    // Tappable chevron with dynamic vertical spacing
                    Button(action: {
                        withAnimation(styles.animation.bottomSheetAnimation) {
                            bottomSheetExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: bottomSheetExpanded ? "chevron.down" : "chevron.up")
                                .font(.system(size: bottomSheetExpanded ? 14 : 18, weight: .bold))
                                .foregroundColor(styles.colors.textSecondary)
                            Spacer()
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, bottomSheetExpanded ? 32 : 24)
                    
                    if bottomSheetExpanded {
                        // Navigation tabs with added bottom padding to avoid overlap with chevron
                        HStack(spacing: 0) {
                            Spacer()
                            NavigationTabButton(
                                icon: "book.fill",
                                title: "Journal",
                                isSelected: selectedTab == 0,
                                action: {
                                    withAnimation(styles.animation.tabSwitchAnimation) {
                                        selectedTab = 0
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(styles.animation.bottomSheetAnimation) {
                                            bottomSheetExpanded = false
                                            bottomSheetOffset = peekHeight - fullSheetHeight
                                        }
                                    }
                                }
                            )
                            Spacer()
                            NavigationTabButton(
                                icon: "chart.bar.fill",
                                title: "Insights",
                                isSelected: selectedTab == 1,
                                action: {
                                    withAnimation(styles.animation.tabSwitchAnimation) {
                                        selectedTab = 1
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(styles.animation.bottomSheetAnimation) {
                                            bottomSheetExpanded = false
                                            bottomSheetOffset = peekHeight - fullSheetHeight
                                        }
                                    }
                                }
                            )
                            Spacer()
                            NavigationTabButton(
                                icon: "bubble.left.fill",
                                title: "Reflections",
                                isSelected: selectedTab == 2,
                                action: {
                                    withAnimation(styles.animation.tabSwitchAnimation) {
                                        selectedTab = 2
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(styles.animation.bottomSheetAnimation) {
                                            bottomSheetExpanded = false
                                            bottomSheetOffset = peekHeight - fullSheetHeight
                                        }
                                    }
                                }
                            )
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.bottom, 8)
                        .frame(height: fullSheetHeight - peekHeight)
                        .background(styles.colors.bottomSheetBackground)
                    }
                }
                .frame(height: bottomSheetExpanded ? fullSheetHeight : peekHeight)
                // Removed the frame modifier to prevent excessive height
                .background(styles.colors.bottomSheetBackground)
                .gesture(bottomSheetDrag)
                .shadow(color: styles.colors.bottomSheetShadow, radius: 4, x: 0, y: -2)
                .offset(x: showingSettings ? -screenWidth : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSettings)
            }
            
            // Settings view overlay
            SettingsView()
                .background(styles.colors.appBackground)
                .frame(width: screenWidth)
                .offset(x: settingsOffset)
                .overlay(
                    VStack {
                        HStack {
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showingSettings = false
                                    settingsOffset = screenWidth
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
                            .padding(.top, styles.layout.topSafeAreaPadding - 10)
                            Spacer()
                        }
                        Spacer()
                    }
                    .opacity(showingSettings ? 1 : 0)
                )
                .zIndex(2)
        }
        .environmentObject(appState)
        .preferredColorScheme(.dark)
        .onAppear {
            bottomSheetOffset = peekHeight - fullSheetHeight
            appState.loadSampleData()
            if !appState.hasSeenOnboarding {
                appState.hasSeenOnboarding = true
            }
        }
    }
}

struct NavigationTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    private let styles = UIStyles.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? styles.colors.accent.opacity(0.2) : Color.clear)
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? styles.colors.accent : styles.colors.textSecondary)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
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

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}