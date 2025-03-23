import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var bottomSheetOffset: CGFloat = 0
    @State private var bottomSheetExpanded = false
    @State private var isDragging = false
    @State private var settingsOffset: CGFloat = UIScreen.main.bounds.width
    @State private var dragOffset: CGFloat = 0

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
    
    // Interactive drag gesture for settings
    private var settingsDrag: some Gesture {
    DragGesture()
        .onChanged { value in
            // When settings is closed, only allow left swipes (negative translation)
            if !showingSettings {
                dragOffset = min(0, value.translation.width)
            } 
            // When settings is open, only allow right swipes (positive translation)
            else {
                dragOffset = max(0, value.translation.width)
            }
        }
        .onEnded { value in
            let horizontalAmount = value.translation.width
            let velocity = value.predictedEndLocation.x - value.location.x
            
            // If settings is open and swiping right
            if showingSettings {
                if horizontalAmount > screenWidth * 0.3 || (horizontalAmount > 20 && velocity > 100) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showingSettings = false
                        settingsOffset = screenWidth
                        dragOffset = 0 // Reset drag offset immediately
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.25)) {
                        dragOffset = 0
                    }
                }
            } 
            // If settings is closed and swiping left
            else {
                if horizontalAmount < -screenWidth * 0.3 || (horizontalAmount < -20 && velocity < -100) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showingSettings = true
                        settingsOffset = 0
                        dragOffset = 0 // Reset drag offset immediately
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.25)) {
                        dragOffset = 0
                    }
                }
            }
        }
}
    
    var body: some View {
    ZStack {
        // Background: top safe area always black; bottom area changes based on bottomSheetExpanded state
        VStack(spacing: 0) {
            Color.black
                .frame(height: styles.layout.topSafeAreaPadding)
            if bottomSheetExpanded {
                styles.colors.bottomSheetBackground
            } else {
                Color.black
            }
        }
        .ignoresSafeArea()
        
        if bottomSheetExpanded {
            Color.black
                .frame(height: UIStyles.shared.layout.topSafeAreaPadding)
                .ignoresSafeArea(edges: .top)
        }
        
        // Main content that stays in place
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
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSettings.toggle()
                                settingsOffset = showingSettings ? 0 : screenWidth
                            }
                        }) {
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(styles.colors.accent)
                                    .frame(width: 20, height: 2)
                                Rectangle()
                                    .fill(styles.colors.accent)
                                    .frame(width: 20, height: 2)
                            }
                            .frame(width: 36, height: 36)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, styles.layout.topSafeAreaPadding)
                    }
                    Spacer()
                }
            )
            
            // Bottom navigation area with gray background extended to the screen bottom
            VStack(spacing: 0) {
            // Tappable chevron with dynamic vertical spacing and fixed chevron size
                Button(action: {
                    withAnimation(styles.animation.bottomSheetAnimation) {
                        bottomSheetExpanded.toggle()
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: bottomSheetExpanded ? "chevron.down" : "chevron.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(bottomSheetExpanded ? styles.colors.textSecondary : styles.colors.text)
                        Spacer()
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, bottomSheetExpanded ? 18 : 12)
                
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
                    .background(bottomSheetExpanded ? styles.colors.bottomSheetBackground : Color.black)
                }
            }
            .frame(height: bottomSheetExpanded ? fullSheetHeight : peekHeight)
            .background(
                Group {
                    if bottomSheetExpanded {
                        styles.colors.bottomSheetBackground
                    } else {
                        Color.black
                    }
                }
            )
            .gesture(bottomSheetDrag)
        }
        .gesture(settingsDrag)
        
        // Dark overlay when settings is open
        Color.black
            .opacity(showingSettings ? 0.5 : 0)
            .opacity(dragOffset != 0 ? (showingSettings ? 0.5 - (dragOffset / screenWidth) * 0.5 : 0.5 + (dragOffset / screenWidth) * 0.5) : (showingSettings ? 0.5 : 0))
            .ignoresSafeArea()
            .allowsHitTesting(false)
        
        // Settings view overlay that slides in from the right - now includes the header
        ZStack(alignment: .top) {
            // Settings header
            ZStack {
                Text("Settings")
                    .font(styles.typography.title1)
                    .foregroundColor(styles.colors.text)
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSettings = false
                            settingsOffset = screenWidth
                        }
                    }) {
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(styles.colors.accent)
                                .frame(width: 20, height: 2)
                            if showingSettings {
                                HStack {
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 16, height: 2)
                                    Spacer()
                                }
                            } else {
                                HStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 16, height: 2)
                                }
                            }
                        }
                        .frame(width: 36, height: 36)
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
            }
            .padding(EdgeInsets(top: styles.layout.topSafeAreaPadding, leading: styles.layout.paddingXL, bottom: styles.layout.paddingM, trailing: styles.layout.paddingXL))
            .background(styles.colors.menuBackground)
            .zIndex(100)
            
            // Settings content
            SettingsView()
                .background(styles.colors.menuBackground)
                .padding(.top, styles.layout.topSafeAreaPadding + 60) // Add padding to account for header
        }
        .frame(width: screenWidth)
        .background(styles.colors.menuBackground)
        .offset(x: showingSettings ? settingsOffset + dragOffset : screenWidth + dragOffset)
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
