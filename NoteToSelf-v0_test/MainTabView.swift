import SwiftUI
import Combine

struct MainTabView: View {
  @EnvironmentObject private var appState: AppState // Use EnvironmentObject
  @EnvironmentObject private var chatManager: ChatManager // Use EnvironmentObject
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
  @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

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
          // Conditional Background: Accent when sheet expanded, otherwise gradient/solid based on tab
          if bottomSheetExpanded {
              // Use accent color when bottom sheet is expanded
              styles.colors.bottomSheetBackground // Might want bottomSheetBackground here? Keeping accent for now.
                  .ignoresSafeArea()
          } else {
              // Use background logic based on tab when bottom sheet is collapsed
              if selectedTab == 2 {
                  // Specific background for ReflectionsView tab (Tab 2) when closed
                  styles.colors.inputBackground // Use input background for reflections
                      .ignoresSafeArea()
              } else {
                  // Standard background for Journal (Tab 0) and Insights (Tab 1) when closed
                  styles.colors.appBackground
                      .ignoresSafeArea()
              }
          }


          // Status bar area
          VStack(spacing: 0) {
              styles.colors.statusBarBackground // Use dedicated status bar background color
                  .frame(height: styles.layout.topSafeAreaPadding)
              Spacer()
          }
          .ignoresSafeArea()

          // Main content: disabled during settings swipes
          VStack(spacing: 0) {
              ZStack {
                  if selectedTab == 0 {
                      JournalView(tabBarOffset: .constant(0),
                                  lastScrollPosition: .constant(0),
                                  tabBarVisible: .constant(true))
                           // Pass bottomSheetExpanded state to the modifier
                          .mainCardStyle(isExpanded: bottomSheetExpanded)
                  } else if selectedTab == 1 {
                      InsightsView(tabBarOffset: .constant(0),
                       lastScrollPosition: .constant(0),
                       tabBarVisible: .constant(true))
                           // Pass bottomSheetExpanded state to the modifier
                          .mainCardStyle(isExpanded: bottomSheetExpanded)
                  } else if selectedTab == 2 {
                      ReflectionsView(tabBarOffset: .constant(0),
                       lastScrollPosition: .constant(0),
                       tabBarVisible: .constant(true),
                       // chatManager: chatManager, // Removed argument
                       showChatHistory: {
                           withAnimation(.easeInOut(duration: 0.3)) {
                               showingChatHistory = true
                               chatHistoryOffset = 0
                           }
                       })
                          // Pass bottomSheetExpanded state to the modifier
                          .mainCardStyle(isExpanded: bottomSheetExpanded)
                          .environmentObject(chatManager) // Added modifier
                  }
              }
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
                              VStack(spacing: 4) { // Add spacing for the text
                                  Image(systemName: bottomSheetExpanded ? "chevron.down" : "chevron.up")
                                      .font(.system(size: 18, weight: .bold))
                                      // Use Accent when closed, White when expanded (will be overridden below)
                                      .foregroundColor(bottomSheetExpanded ? Color.white : styles.colors.accent) // Color.white for expanded state

                                  // Add Navigation text below the chevron, only when not expanded
                                  if !bottomSheetExpanded {
                                      Text("Navigation")
                                          .font(.system(size: 10, weight: .regular, design: .monospaced))
                                          // Use Accent color when closed
                                          .foregroundColor(styles.colors.text)
                                  }
                              }
                              // Apply conditional height for chevron button area
                              .frame(height: bottomSheetExpanded ? peekHeight / 2 : peekHeight)
                              .contentShape(Rectangle())
                               // Increase conditional top padding: more when closed
                              .padding(.top, bottomSheetExpanded ? 0 : 20) // Increased from 10 to 20
                              // Restore original padding logic below chevron
                              .padding(.bottom, bottomSheetExpanded ? 16 : 8)
                          }
                          .buttonStyle(PlainButtonStyle())

                          // Tab buttons - only shown when expanded
                          if bottomSheetExpanded {
                              HStack(spacing: 0) {
                                  Spacer()
                                  NavigationTabButton(
                                      icon: "pencil",
                                      title: "Journal",
                                      isSelected: selectedTab == 0,
                                      // Use Accent color when expanded
                                      foregroundColor: styles.colors.accent
                                  ) {
                                      // Move selectedTab change inside asyncAfter
                                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Short delay before starting collapse
                                          selectedTab = 0 // Change tab state *just before* animating sheet collapse
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
                                      isSelected: selectedTab == 1,
                                      // Use Accent color when expanded
                                      foregroundColor: styles.colors.accent
                                  ) {
                                      // Move selectedTab change inside asyncAfter
                                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Short delay
                                          selectedTab = 1
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
                                      isSelected: selectedTab == 2,
                                      // Use Accent color when expanded
                                      foregroundColor: styles.colors.accent
                                  ) {
                                      // Move selectedTab change inside asyncAfter
                                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Short delay
                                          selectedTab = 2
                                          withAnimation(styles.animation.bottomSheetAnimation) {
                                              bottomSheetExpanded = false
                                              bottomSheetOffset = peekHeight - fullSheetHeight
                                          }
                                      }
                                  }
                                  Spacer()
                              }
                              .padding(.vertical, 12) // Restore original vertical padding
                              .padding(.bottom, 8)
                              // Apply conditional height for tab buttons area
                              .frame(height: bottomSheetExpanded ? fullSheetHeight - (peekHeight / 2) : 0)
                          }
                      }
                      .frame(width: geometry.size.width, height: bottomSheetExpanded ? fullSheetHeight : peekHeight)
                      .opacity(isKeyboardVisible ? 0 : 1)
                      .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
                      .background(
                           Group {
                               // Determine background based on expanded state and current tab
                               if bottomSheetExpanded {
                                   styles.colors.bottomSheetBackground // Use specific color when open
                               } else {
                                   if selectedTab == 2 { // Reflections View
                                       styles.colors.inputBackground // Specific color for Reflections closed nav
                                   } else { // Journal or Insights View
                                       styles.colors.appBackground // Match main app background
                                   }
                               }
                           }
                      )
                  }
              }
              .frame(height: isKeyboardVisible ? 0 : (bottomSheetExpanded ? fullSheetHeight : peekHeight))
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
                  // Header is now handled inside SettingsView

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
                  // The header is now handled inside ChatHistoryView

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
                          // No animation needed here, change happens before view appears
                          selectedTab = 2
                      }
                  }, onDismiss: {
                      // Close the chat history view
                      withAnimation(.easeInOut(duration: 0.3)) {
                          showingChatHistory = false
                          chatHistoryOffset = screenWidth
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
      // IMPORTANT: Remove the mainScrollingDisabled environment variable to allow scrolling
      .environment(\.settingsScrollingDisabled, isSwipingSettings)
      // No need to pass environment objects down again here
      // .preferredColorScheme(.dark) // REMOVED
      .onAppear {
          bottomSheetOffset = peekHeight - fullSheetHeight
          // Remove sample data loading

          if !appState.hasSeenOnboarding {
              // This logic might need review - should onboarding status be persisted?
              // For now, keep the logic but remove sample data load.
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
  // Add foregroundColor parameter with default value
  var foregroundColor: Color = Color.white
  let action: () -> Void
  @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

  // Fixed dimensions
  private let buttonWidth: CGFloat = 80 // Define button width
  private let iconSize: CGFloat = 24
  private let underscoreHeight: CGFloat = 4 // Increased thickness

  var body: some View {
      Button(action: action) {
          VStack(spacing: 6) { // Increased spacing from 4 to 6
              Spacer() // Pushes content down within the button frame initially

              // Icon
              Image(systemName: icon)
                  .font(.system(size: iconSize, weight: isSelected ? .bold : .regular))
                  .foregroundColor(foregroundColor) // Use parameter
                  .frame(height: iconSize) // Keep icon height fixed

              // Text label
              Text(title)
                  .font(isSelected ?
                        .system(size: 12, weight: .bold, design: .monospaced) : // Consider theme typography?
                        styles.typography.caption)
                  .foregroundColor(foregroundColor) // Use parameter

              // Underscore indicator
              Rectangle()
                  .fill(foregroundColor) // Use parameter
                  .frame(width: 40, height: underscoreHeight) // Increased width from 35 to 40
                  .opacity(isSelected ? 1 : 0)

              Spacer(minLength: 2) // Add small spacer below underscore if needed
          }
          // Remove horizontal padding from VStack to allow text full width
          .frame(width: buttonWidth) // Keep fixed width for the overall button tap area
          // Removed explicit height and temporary background
      }
      .buttonStyle(ScaleButtonStyle())
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected) // Restore animation
  }
}

struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
      configuration.label
          .scaleEffect(configuration.isPressed ? 0.9 : 1)
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
  }
}