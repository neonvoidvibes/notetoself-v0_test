import SwiftUI
import Combine

struct MainTabView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    
    // Settings-related states
    @State private var showingSettings = false
    @State private var settingsOffset: CGFloat = -UIScreen.main.bounds.width // Changed to negative for left side
    @State private var dragOffset: CGFloat = 0
    @State private var isSwipingSettings = false
    
    // Bottom sheet / tab bar states
    @State private var bottomSheetOffset: CGFloat = 0
    @State private var bottomSheetExpanded = false
    @State private var isDragging = false
    
    // Shared UI styles
    private let styles = UIStyles.shared
    
    // Computed geometry
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
    
    // Drag gesture for bottom sheet
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
    
    // Drag gesture for Settings: Allow swipe from left edge to open
    private var settingsDrag: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // Collapse bottom sheet if expanded
                if bottomSheetExpanded {
                    withAnimation(styles.animation.bottomSheetAnimation) {
                        bottomSheetExpanded = false
                        bottomSheetOffset = peekHeight - fullSheetHeight
                    }
                }
                
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                let isSignificant = abs(value.translation.width) > 10
                
                if !showingSettings {
                    // Opening from left edge - check for right swipe from left edge
                    if isHorizontal && isSignificant && value.translation.width > 0 && value.startLocation.x < 50 {
                        isSwipingSettings = true
                        dragOffset = min(value.translation.width, screenWidth)
                        settingsOffset = -screenWidth + dragOffset
                    }
                } else {
                    // Closing - check for left swipe
                    if isHorizontal && isSignificant && value.translation.width < 0 {
                        isSwipingSettings = true
                        dragOffset = max(value.translation.width, -screenWidth)
                        settingsOffset = dragOffset
                    }
                }
            }
            .onEnded { value in
                if isSwipingSettings {
                    let horizontalAmount = value.translation.width
                    let velocity = value.predictedEndLocation.x - value.location.x
                    
                    if !showingSettings {
                        // Opening gesture
                        if horizontalAmount > screenWidth * 0.3 || (horizontalAmount > 20 && velocity > 100) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showingSettings = true
                                settingsOffset = 0
                            }
                        } else {
                            withAnimation(.easeOut(duration: 0.25)) {
                                settingsOffset = -screenWidth
                            }
                        }
                    } else {
                        // Closing gesture
                        if horizontalAmount < -screenWidth * 0.3 || (horizontalAmount < -20 && velocity < -100) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showingSettings = false
                                settingsOffset = -screenWidth
                            }
                        } else {
                            withAnimation(.easeOut(duration: 0.25)) {
                                settingsOffset = 0
                            }
                        }
                    }
                }
                
                isSwipingSettings = false
                dragOffset = 0
            }
    }
    
    var body: some View {
        ZStack {
            // Background - conditional based on nav area state and selected tab
            ZStack {
                // Base background - use gray for Reflections tab, black for others
                (selectedTab == 2 ? styles.colors.reflectionsNavBackground : styles.colors.appBackground)
                    .ignoresSafeArea()
                
                // Conditional gradient background when nav is expanded
                if bottomSheetExpanded {
                    // Single continuous gradient for the entire screen
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                styles.colors.appBackground, // Start with black at the top
                                styles.colors.appBackgroundDarker.opacity(0.8), // Transition to dark gray
                                styles.colors.navBackgroundBottom // End with the nav bottom color
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
                
            // Status bar area
            VStack(spacing: 0) {
                Color.black
                    .frame(height: styles.layout.topSafeAreaPadding)
                Spacer()
            }
            .ignoresSafeArea()
            
            // Main content: disabled during settings swipes
            VStack(spacing: 0) {
                Group {
                    if selectedTab == 0 {
                        JournalView(tabBarOffset: .constant(0),
                                    lastScrollPosition: .constant(0),
                                    tabBarVisible: .constant(true))
                    } else if selectedTab == 1 {
                        InsightsView(tabBarOffset: .constant(0),
                         lastScrollPosition: .constant(0),
                         tabBarVisible: .constant(true))
                    } else if selectedTab == 2 {
                        ReflectionsView(tabBarOffset: .constant(0),
                         lastScrollPosition: .constant(0),
                         tabBarVisible: .constant(true))
                    }
                }
                .mainCardStyle()
                .offset(y: bottomSheetExpanded ? -fullSheetHeight * 0.25 : 0)
                .animation(styles.animation.bottomSheetAnimation, value: bottomSheetExpanded)
                .environment(\.bottomSheetExpanded, bottomSheetExpanded)
                // Auto-close on tap
                .onTapGesture {
                    if bottomSheetExpanded {
                        withAnimation(styles.animation.bottomSheetAnimation) {
                            bottomSheetExpanded = false
                            bottomSheetOffset = peekHeight - fullSheetHeight
                        }
                    }
                }
                // Auto-close on any drag (scroll) gesture in the main content
                .simultaneousGesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { _ in
                            if bottomSheetExpanded {
                                withAnimation(styles.animation.bottomSheetAnimation) {
                                    bottomSheetExpanded = false
                                    bottomSheetOffset = peekHeight - fullSheetHeight
                                }
                            }
                        }
                )
                // Also preserve the previous tap gesture (for redundancy)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if bottomSheetExpanded {
                            withAnimation(styles.animation.bottomSheetAnimation) {
                                bottomSheetExpanded = false
                                bottomSheetOffset = peekHeight - fullSheetHeight
                            }
                        }
                    }
                )
                
                // Bottom sheet / tab bar - using GeometryReader for precise positioning
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Chevron button - positioned at the very top with no spacing
                        Button(action: {
                            withAnimation(styles.animation.bottomSheetAnimation) {
                                bottomSheetExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: bottomSheetExpanded ? "chevron.down" : "chevron.up")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color.white) // Always white for better contrast
                                Spacer()
                            }
                            .frame(height: peekHeight)
                            .contentShape(Rectangle())
                            .padding(.bottom, bottomSheetExpanded ? 16 : 8) // More padding below the chevron
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Tab buttons - only shown when expanded
                        if bottomSheetExpanded {
                            HStack(spacing: 0) {
                                Spacer()
                                NavigationTabButton(
                                    icon: "book.fill",
                                    title: "Journal",
                                    isSelected: selectedTab == 0
                                ) {
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
                                Spacer()
                                NavigationTabButton(
                                    icon: "chart.bar.fill",
                                    title: "Insights",
                                    isSelected: selectedTab == 1
                                ) {
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
                                Spacer()
                                NavigationTabButton(
                                    icon: "bubble.left.fill",
                                    title: "Reflect",
                                    isSelected: selectedTab == 2
                                ) {
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
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.bottom, 8)
                            .frame(height: fullSheetHeight - peekHeight)
                        }
                    }
                    .frame(width: geometry.size.width, height: bottomSheetExpanded ? fullSheetHeight : peekHeight)
                    .background(
                        Group {
                            if bottomSheetExpanded {
                                // Make the nav area background transparent to let the main gradient show through
                                Color.clear
                            } else {
                                // Use reflectionsNavBackground for Reflections tab, black for others
                                selectedTab == 2 ? styles.colors.reflectionsNavBackground : styles.colors.appBackground
                            }
                        }
                    )
                }
                .frame(height: bottomSheetExpanded ? fullSheetHeight : peekHeight)
                .gesture(bottomSheetDrag)
            }
            .disabled(isSwipingSettings)
            .gesture(settingsDrag)
            
            // Dim overlay
            Color.black
                .opacity(showingSettings ? 0.5 : 0)
                .opacity(
                    dragOffset != 0
                        ? (showingSettings
                            ? 0.5 - (dragOffset / screenWidth) * 0.5
                            : (dragOffset / screenWidth) * 0.5)
                        : (showingSettings ? 0.5 : 0)
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // Settings overlay, no disable so we can swipe inside it
            ZStack(alignment: .top) {
                ZStack {
                    Text("Settings")
                        .font(styles.typography.title1)
                        .foregroundColor(styles.colors.text)
                        .frame(maxWidth: .infinity, alignment: .center)
        
                    HStack {
                        Spacer()
            
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSettings = false
                                settingsOffset = -screenWidth
                            }
                        }) {
                            VStack(spacing: 4) {
                                HStack {
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 24, height: 2) // Top bar
                                    Spacer()
                                }
                                HStack {
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 20, height: 2) // Bottom bar (shorter)
                                    Spacer()
                                }
                            }
                            .frame(width: 36, height: 36)
                        }
                        .padding(.trailing, styles.layout.paddingXL)
                    }
                }
                .padding(.top, styles.layout.topSafeAreaPadding - 10)
                .background(styles.colors.menuBackground)
                .zIndex(100)
                
                // Actual Settings content
                SettingsView()
                    .background(styles.colors.menuBackground)
                    .padding(.top, styles.layout.topSafeAreaPadding + 40)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(settingsDrag)
            .frame(width: screenWidth)
            .background(styles.colors.menuBackground)
            .offset(x: settingsOffset)
            .zIndex(2)
        }
        .environment(\.mainScrollingDisabled, showingSettings || isSwipingSettings)
        .environment(\.settingsScrollingDisabled, isSwipingSettings)
        .environmentObject(appState)
        .preferredColorScheme(.dark)
        .onAppear {
            bottomSheetOffset = peekHeight - fullSheetHeight
            appState.loadSampleData()
            if !appState.hasSeenOnboarding {
                appState.hasSeenOnboarding = true
            }
            
            // Add notification observer for menu button
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ToggleSettings"), object: nil, queue: .main) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSettings.toggle()
                    if showingSettings {
                        settingsOffset = 0
                    } else {
                        settingsOffset = -screenWidth
                    }
                }
            }
        }
    }
}

// Add environment key for bottom sheet expanded state
private struct BottomSheetExpandedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var bottomSheetExpanded: Bool {
        get { self[BottomSheetExpandedKey.self] }
        set { self[BottomSheetExpandedKey.self] = newValue }
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
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.clear) // Lighter selection circle
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? Color.white : Color.white.opacity(0.6)) // White for selected, light gray for unselected
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                Text(title)
                    .font(isSelected ? 
                          .system(size: 12, weight: .bold, design: .monospaced) : 
                          styles.typography.caption)
                    .foregroundColor(isSelected ? Color.white : Color.white.opacity(0.6)) // White for selected, light gray for unselected
                    .opacity(isSelected ? 1 : 0.8)
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

