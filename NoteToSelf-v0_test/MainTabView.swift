import SwiftUI
import Combine

struct MainTabView: View {
  @StateObject private var appState = AppState()
  @StateObject private var chatManager = ChatManager()
  @State private var selectedTab = 0
  
  // Settings-related states
  @State private var showingSettings = false
  @State private var settingsOffset: CGFloat = -UIScreen.main.bounds.width // Changed to negative for left side
  @State private var dragOffset: CGFloat = 0
  @State private var isSwipingSettings = false
  
  // Chat History-related states
  @State private var showingChatHistory = false
  @State private var chatHistoryOffset: CGFloat = UIScreen.main.bounds.width // Start offscreen to the right
  @State private var isSwiping = false
  
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
  
  // Add a new state variable to track keyboard visibility
  @State private var isKeyboardVisible = false
  
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
                       tabBarVisible: .constant(true),
                       chatManager: chatManager,
                       showChatHistory: {
                           withAnimation(.easeInOut(duration: 0.3)) {
                               showingChatHistory = true
                               chatHistoryOffset = 0
                           }
                       })
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
                  if !isKeyboardVisible {
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
                                      icon: "pencil",
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
              }
              .frame(height: isKeyboardVisible ? 0 : (bottomSheetExpanded ? fullSheetHeight : peekHeight))
              .opacity(isKeyboardVisible ? 0 : 1)
              .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
              .gesture(bottomSheetDrag)
          }
          .disabled(isSwipingSettings || showingChatHistory)
          .gesture(settingsDrag)
          
          // Dim overlay for Settings
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
          
          // Dim overlay for Chat History
          Color.black
              .opacity(showingChatHistory ? 0.5 : 0)
              .ignoresSafeArea()
              .allowsHitTesting(false)
          
          // Settings overlay, no disable so we can swipe inside it
          ZStack(alignment: .top) {
              VStack(spacing: 0) {
                  // Header with title and close button
                  ZStack(alignment: .center) {
                      // Title truly centered
                      VStack(spacing: 8) {
                          Text("Settings")
                              .font(styles.typography.title1)
                              .foregroundColor(styles.colors.text)
                          
                          Rectangle()
                              .fill(styles.colors.accent)
                              .frame(width: 20, height: 3)
                      }
                      
                      // Close button on right
                      HStack {
                          Spacer()
                          
                          // Close button (double chevron) at right side
                          Button(action: {
                              withAnimation(.easeInOut(duration: 0.3)) {
                                  showingSettings = false
                                  settingsOffset = -screenWidth
                              }
                          }) {
                              Image(systemName: "chevron.right.2")
                                  .font(.system(size: 20, weight: .bold))
                                  .foregroundColor(styles.colors.accent)
                                  .frame(width: 36, height: 36)
                          }
                      }
                      .padding(.horizontal, styles.layout.paddingXL)
                  }
                  .padding(.top, 8) // Further reduced top padding
                  .padding(.bottom, 8)
                  
                  // Actual Settings content
                  SettingsView()
                      .background(styles.colors.menuBackground)
              }
              .background(styles.colors.menuBackground)
              .zIndex(100)
          }
          .contentShape(Rectangle())
          .simultaneousGesture(settingsDrag)
          .frame(width: screenWidth)
          .background(styles.colors.menuBackground)
          .offset(x: settingsOffset)
          .zIndex(2)
          
          // Chat History overlay
          ZStack(alignment: .top) {
              VStack(spacing: 0) {
                  // Header with title and close button
                  ZStack(alignment: .center) {
                      // Title truly centered
                      VStack(spacing: 8) {
                          Text("Chat History")
                              .font(styles.typography.title1)
                              .foregroundColor(styles.colors.text)
                          
                          Rectangle()
                              .fill(styles.colors.accent)
                              .frame(width: 20, height: 3)
                      }
                      
                      // Left-aligned back button and right-aligned new chat button
                      HStack {
                          // Back button (double chevron left) at left side
                          Button(action: {
                              withAnimation(.easeInOut(duration: 0.3)) {
                                  showingChatHistory = false
                                  chatHistoryOffset = screenWidth
                              }
                          }) {
                              Image(systemName: "chevron.left.2")
                                  .font(.system(size: 20, weight: .bold))
                                  .foregroundColor(styles.colors.accent)
                                  .frame(width: 36, height: 36)
                          }
                          
                          Spacer()
                          
                          // New chat button on right side
                          Button(action: {
                              // Start a new chat and close the history view
                              chatManager.startNewChat()
                              withAnimation(.easeInOut(duration: 0.3)) {
                                  showingChatHistory = false
                                  chatHistoryOffset = screenWidth
                              }
                          }) {
                              Image(systemName: "square.and.pencil")
                                  .font(.system(size: 20, weight: .bold))
                                  .foregroundColor(Color.white)
                                  .frame(width: 36, height: 36)
                          }
                      }
                      .padding(.horizontal, styles.layout.paddingXL)
                  }
                  .padding(.top, 8) // Same top padding as other views
                  .padding(.bottom, 8)
                  
                  // Actual Chat History content
                  ChatHistoryView(chatManager: chatManager, onSelectChat: { selectedChat in
                      // Load the selected chat
                      chatManager.loadChat(selectedChat)
                      
                      // Close the chat history view
                      withAnimation(.easeInOut(duration: 0.3)) {
                          showingChatHistory = false
                          chatHistoryOffset = screenWidth
                      }
                      
                      // Make sure we're on the Reflections tab
                      if selectedTab != 2 {
                          withAnimation {
                              selectedTab = 2
                          }
                      }
                  })
                  .background(styles.colors.menuBackground)
              }
              .background(styles.colors.menuBackground)
              .zIndex(100)
          }
          .contentShape(Rectangle())
          .frame(width: screenWidth)
          .background(styles.colors.menuBackground)
          .offset(x: chatHistoryOffset)
          .zIndex(2)
      }
      .environment(\.mainScrollingDisabled, showingSettings || isSwipingSettings || showingChatHistory)
      .environment(\.settingsScrollingDisabled, isSwipingSettings)
      .environmentObject(appState)
      .environmentObject(chatManager)
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
          
          // Add notification observer for chat history button
          NotificationCenter.default.addObserver(forName: NSNotification.Name("ToggleChatHistory"), object: nil, queue: .main) { _ in
              withAnimation(.easeInOut(duration: 0.3)) {
                  showingChatHistory.toggle()
                  if showingChatHistory {
                      chatHistoryOffset = 0
                  } else {
                      chatHistoryOffset = screenWidth
                  }
              }
          }
          
          // Add keyboard observers
          NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
              withAnimation {
                  isKeyboardVisible = true
              }
          }
          
          NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
              withAnimation {
                  isKeyboardVisible = false
              }
          }
      }
      .environment(\.keyboardVisible, isKeyboardVisible)
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

// Add a new environment key for keyboard visibility
private struct KeyboardVisibleKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

extension EnvironmentValues {
  var keyboardVisible: Bool {
      get { self[KeyboardVisibleKey.self] }
      set { self[KeyboardVisibleKey.self] = newValue }
  }
}

struct NavigationTabButton: View {
  let icon: String
  let title: String
  let isSelected: Bool
  let action: () -> Void
  private let styles = UIStyles.shared
  
  // Fixed dimensions
  private let buttonHeight: CGFloat = 60
  private let textHeight: CGFloat = 15
  private let iconSize: CGFloat = 24
  
  var body: some View {
      Button(action: action) {
          ZStack(alignment: .bottom) {
              // Container
              Rectangle()
                  .fill(Color.clear)
                  .frame(width: 80, height: buttonHeight)
              
              // Text label - always at the same position from bottom
              Text(title)
                  .font(isSelected ? 
                        .system(size: 12, weight: .bold, design: .monospaced) : 
                        styles.typography.caption)
                  .foregroundColor(isSelected ? styles.colors.accent : Color.white)
                  .frame(height: textHeight)
                  .padding(.bottom, 5) // Fixed padding from bottom
              
              // Icon - positioned relative to text
              Image(systemName: icon)
                  .font(.system(size: iconSize, 
                               weight: isSelected ? .bold : .regular))
                  .foregroundColor(isSelected ? styles.colors.accent : Color.white)
                  .frame(height: iconSize)
                  .offset(y: isSelected ? -30 : -textHeight - 10) // Position icon above text
          }
      }
      .buttonStyle(ScaleButtonStyle())
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
  }
}

struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
      configuration.label
          .scaleEffect(configuration.isPressed ? 0.9 : 1)
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

