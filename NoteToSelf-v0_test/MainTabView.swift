import SwiftUI
import Combine

struct MainTabView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    
    // Settings-related states
    @State private var showingSettings = false
    @State private var settingsOffset: CGFloat = UIScreen.main.bounds.width
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
    
    // Drag gesture for Settings: Only allow swipe-to-open; disable swipe-to-close when settings are open
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
                if !showingSettings {
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                    let isSignificant = abs(value.translation.width) > 10
                    if isHorizontal && isSignificant {
                        isSwipingSettings = true
                        dragOffset = value.translation.width
                    }
                }
            } 
            .onEnded { value in
                if !showingSettings && isSwipingSettings {
                    let horizontalAmount = value.translation.width
                    let velocity = value.predictedEndLocation.x - value.location.x
                    if horizontalAmount < -screenWidth * 0.3 || (horizontalAmount < -20 && velocity < -100) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showingSettings = true
                            settingsOffset = 0
                            dragOffset = 0
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragOffset = 0
                        }
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.25)) {
                        dragOffset = 0
                    }
                }
                isSwipingSettings = false
            }
    }
    
    var body: some View {
        ZStack {
            // Background
            VStack(spacing: 0) {
                Color.black
                    .frame(height: styles.layout.topSafeAreaPadding)
                if bottomSheetExpanded {
                    styles.colors.navBackground
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()
            
            if bottomSheetExpanded {
                Color.black
                    .frame(height: styles.layout.topSafeAreaPadding)
                    .ignoresSafeArea(edges: .top)
            }
            
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
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                // Collapse bottom sheet if open before opening SettingsView
                                withAnimation(styles.animation.bottomSheetAnimation) {
                                    if bottomSheetExpanded {
                                        bottomSheetExpanded = false
                                        bottomSheetOffset = peekHeight - fullSheetHeight
                                    }
                                }
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
                
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(styles.animation.bottomSheetAnimation) {
                            bottomSheetExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: bottomSheetExpanded ? "chevron.down" : "chevron.up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(bottomSheetExpanded ? styles.colors.navIconSelected : Color.white)
                            Spacer()
                        }
                    }
                    .padding(.top, 18)
                    .padding(.bottom, bottomSheetExpanded ? 18 : 12)
                    
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
                                title: "Reflections",
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
                        .background(styles.colors.navBackground)
                    }
                }
                .frame(height: bottomSheetExpanded ? fullSheetHeight : peekHeight)
                .background(
                    Group {
                        if bottomSheetExpanded {
                            styles.colors.navBackground
                        } else {
                            Color.black
                        }
                    }
                )
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
                            : 0.5 + (dragOffset / screenWidth) * 0.5)
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
                        
                        Spacer()
                    }
                }
                .padding(EdgeInsets(
                    top: styles.layout.topSafeAreaPadding,
                    leading: styles.layout.paddingXL,
                    bottom: styles.layout.paddingM,
                    trailing: styles.layout.paddingXL
                ))
                .background(styles.colors.menuBackground)
                .zIndex(100)
                
                // Actual Settings content
                SettingsView()
                    .background(styles.colors.menuBackground)
                    .padding(.top, styles.layout.topSafeAreaPadding + 60)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(settingsDrag)
            .frame(width: screenWidth)
            .background(styles.colors.menuBackground)
            .offset(x: showingSettings ? settingsOffset + dragOffset : screenWidth + dragOffset)
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
                        .fill(isSelected ? styles.colors.navSelectionCircle : Color.clear)
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? styles.colors.navIconSelected : styles.colors.navIconDefault)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                Text(title)
                    .font(isSelected ? 
                          .system(size: 12, weight: .bold, design: .monospaced) : 
                          styles.typography.caption)
                    .foregroundColor(isSelected ? styles.colors.navIconSelected : styles.colors.navIconDefault)
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