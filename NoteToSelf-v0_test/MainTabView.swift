import SwiftUI
import Combine

// Define standard notification name
extension Notification.Name {
    static let switchToTabNotification = Notification.Name("SwitchToTabNotification")
    static let toggleSettingsNotification = Notification.Name("ToggleSettings")
    static let toggleChatHistoryNotification = Notification.Name("ToggleChatHistory")
}


struct MainTabView: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var chatManager: ChatManager
  @EnvironmentObject private var databaseService: DatabaseService
  @State private var selectedTab = 0 // Default to Journal

  // Settings-related states
  @State private var showingSettings = false
  @State private var settingsOffset: CGFloat = -UIScreen.main.bounds.width
  @State private var dragOffset: CGFloat = 0
  @State private var isSwipingSettings = false

  // Chat History-related states
  @State private var showingChatHistory = false
  @State private var chatHistoryOffset: CGFloat = UIScreen.main.bounds.width
  @State private var isSwiping = false

  // Bottom sheet / tab bar states
  @State private var bottomSheetOffset: CGFloat = 0
  @State private var bottomSheetExpanded = false
  @State private var isDragging = false

  // Shared UI styles
  @ObservedObject private var styles = UIStyles.shared

  // Computed geometry
  private var screenHeight: CGFloat { UIScreen.main.bounds.height }
  private var screenWidth: CGFloat { UIScreen.main.bounds.width }
  private var peekHeight: CGFloat { styles.layout.bottomSheetPeekHeight }
  private var fullSheetHeight: CGFloat { styles.layout.bottomSheetFullHeight }

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
                  withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded = true }
              } else if dragAmount > 20 || dragVelocity > 500 {
                  withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded = false; bottomSheetOffset = peekHeight - fullSheetHeight }
              } else {
                  let snapUpThreshold = (peekHeight - fullSheetHeight) * 0.3
                  withAnimation(styles.animation.bottomSheetAnimation) {
                      if bottomSheetOffset < snapUpThreshold { bottomSheetOffset = 0; bottomSheetExpanded = true }
                      else { bottomSheetOffset = peekHeight - fullSheetHeight; bottomSheetExpanded = false }
                  }
              }
          }
  }

  // Drag gesture for Settings
  private var settingsDrag: some Gesture {
      DragGesture(minimumDistance: 10)
          .onChanged { value in
              if bottomSheetExpanded { withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded = false; bottomSheetOffset = peekHeight - fullSheetHeight } }
              let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
              let isSignificant = abs(value.translation.width) > 10
              if !showingSettings {
                  if isHorizontal && isSignificant && value.translation.width > 0 && value.startLocation.x < 50 {
                      isSwipingSettings = true; dragOffset = min(value.translation.width, screenWidth); settingsOffset = -screenWidth + dragOffset
                  }
              } else {
                  if isHorizontal && isSignificant && value.translation.width < 0 {
                      isSwipingSettings = true; dragOffset = max(value.translation.width, -screenWidth); settingsOffset = dragOffset
                  }
              }
          }
          .onEnded { value in
              if isSwipingSettings {
                  let horizontalAmount = value.translation.width
                  let velocity = value.predictedEndLocation.x - value.location.x
                  if !showingSettings {
                      if horizontalAmount > screenWidth * 0.3 || (horizontalAmount > 20 && velocity > 100) { withAnimation(.easeOut(duration: 0.25)) { showingSettings = true; settingsOffset = 0 } }
                      else { withAnimation(.easeOut(duration: 0.25)) { settingsOffset = -screenWidth } }
                  } else {
                      if horizontalAmount < -screenWidth * 0.3 || (horizontalAmount < -20 && velocity < -100) { withAnimation(.easeOut(duration: 0.25)) { showingSettings = false; settingsOffset = -screenWidth } }
                      else { withAnimation(.easeOut(duration: 0.25)) { settingsOffset = 0 } }
                  }
              }
              isSwipingSettings = false; dragOffset = 0
          }
  }

  // Keyboard visibility state
  @State private var isKeyboardVisible = false

  // Function to handle tab switching and closing bottom sheet from nav buttons
   private func switchTab(to index: Int) {
       guard index != selectedTab else {
           if bottomSheetExpanded { withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded = false; bottomSheetOffset = peekHeight - fullSheetHeight } }
           return
       }
       // Use DispatchQueue to ensure UI updates smoothly
       DispatchQueue.main.async {
           selectedTab = index
           withAnimation(styles.animation.bottomSheetAnimation) {
               bottomSheetExpanded = false
               bottomSheetOffset = peekHeight - fullSheetHeight
           }
       }
   }

  var body: some View {
      ZStack {
          // Background layers
          styles.colors.appBackground.ignoresSafeArea()
          styles.colors.inputBackground.ignoresSafeArea()
          if !bottomSheetExpanded {
              if selectedTab == 0 || selectedTab == 1 { styles.colors.appBackground.ignoresSafeArea() }
          } else { styles.colors.bottomSheetBackground.ignoresSafeArea() }
          // Status bar background
          VStack(spacing: 0) { styles.colors.statusBarBackground.frame(height: styles.layout.topSafeAreaPadding); Spacer() }.ignoresSafeArea()

          // Main content container
          VStack(spacing: 0) {
              ZStack {
                  // ZStack for view switching
                  Group {
                       if selectedTab == 0 {
                           JournalView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true))
                               .transition(.opacity)
                       } else if selectedTab == 1 {
                           InsightsView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true))
                               .transition(.opacity)
                       } else if selectedTab == 2 {
                           ReflectionsView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true),
                               showChatHistory: { withAnimation(.easeInOut(duration: 0.3)) { showingChatHistory = true; chatHistoryOffset = 0 } })
                               .environmentObject(chatManager)
                               .transition(.opacity)
                       }
                   }
              }
              .offset(y: bottomSheetExpanded ? -fullSheetHeight * 0.25 : 0)
              .animation(styles.animation.bottomSheetAnimation, value: bottomSheetExpanded)
              .environment(\.bottomSheetExpanded, bottomSheetExpanded)
              // Auto-close gestures...
              .onTapGesture { if bottomSheetExpanded { withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded = false; bottomSheetOffset = peekHeight - fullSheetHeight } } }
              .simultaneousGesture( DragGesture(minimumDistance: 1).onChanged { _ in if bottomSheetExpanded { withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded = false; bottomSheetOffset = peekHeight - fullSheetHeight } } } )
              .simultaneousGesture( TapGesture().onEnded { if bottomSheetExpanded { withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded = false; bottomSheetOffset = peekHeight - fullSheetHeight } } } )


              // Bottom sheet / tab bar
              GeometryReader { geometry in
                  if !isKeyboardVisible {
                      VStack(spacing: 0) {
                          Button(action: { withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded.toggle() } }) {
                              VStack(spacing: 4) {
                                  Image(systemName: bottomSheetExpanded ? "chevron.down" : "chevron.up").font(.system(size: 18, weight: .bold)).foregroundColor(styles.colors.accent)
                                  if !bottomSheetExpanded { Text("Navigation").font(.system(size: 10, weight: .regular, design: .monospaced)).foregroundColor(styles.colors.text) }
                              }
                              .frame(height: bottomSheetExpanded ? peekHeight / 2 : peekHeight)
                              .contentShape(Rectangle())
                              .padding(.top, bottomSheetExpanded ? 0 : 20)
                              .padding(.bottom, bottomSheetExpanded ? 16 : 8)
                          }.buttonStyle(PlainButtonStyle())

                          if bottomSheetExpanded {
                              HStack(spacing: 0) {
                                  Spacer()
                                  NavigationTabButton(icon: "pencil", title: "Journal", isSelected: selectedTab == 0, index: 0, action: switchTab)
                                  Spacer()
                                  NavigationTabButton(icon: "chart.bar.fill", title: "Insights", isSelected: selectedTab == 1, index: 1, action: switchTab)
                                  Spacer()
                                  NavigationTabButton(icon: "bubble.left.fill", title: "Reflect", isSelected: selectedTab == 2, index: 2, action: switchTab)
                                  Spacer()
                              }
                              .padding(.vertical, 12)
                              .padding(.bottom, 8)
                              .frame(height: bottomSheetExpanded ? fullSheetHeight - (peekHeight / 2) : 0)
                          }
                      }
                      .frame(width: geometry.size.width, height: bottomSheetExpanded ? fullSheetHeight : peekHeight)
                      .opacity(isKeyboardVisible ? 0 : 1)
                      .animation(.default, value: isKeyboardVisible)
                      .background( bottomSheetExpanded ? styles.colors.bottomSheetBackground : (selectedTab == 2 ? styles.colors.inputBackground : styles.colors.appBackground) )
                  }
              }
              .frame(height: isKeyboardVisible ? 0 : (bottomSheetExpanded ? fullSheetHeight : peekHeight))
              .gesture(bottomSheetDrag)
          }
          .disabled(isSwipingSettings || showingChatHistory)
          .gesture(settingsDrag)

          // Overlays (Settings, Chat History)...
           Color.black.opacity(showingSettings ? 0.5 : 0).opacity(dragOffset != 0 ? (showingSettings ? 0.5 - (dragOffset / screenWidth) * 0.5 : (dragOffset / screenWidth) * 0.5) : (showingSettings ? 0.5 : 0)).ignoresSafeArea().allowsHitTesting(false)
           Color.black.opacity(showingChatHistory ? 0.5 : 0).ignoresSafeArea().allowsHitTesting(false)
           ZStack(alignment: .top) { SettingsView().environmentObject(databaseService).background(styles.colors.menuBackground) }.background(styles.colors.menuBackground).zIndex(100).contentShape(Rectangle()).simultaneousGesture(settingsDrag).frame(width: screenWidth).background(styles.colors.menuBackground).offset(x: settingsOffset).zIndex(2)
           ZStack(alignment: .top) { ChatHistoryView(chatManager: chatManager, onSelectChat: { selectedChat in chatManager.loadChat(selectedChat); withAnimation(.easeInOut(duration: 0.3)) { showingChatHistory = false; chatHistoryOffset = screenWidth }; if selectedTab != 2 { selectedTab = 2 } }, onDismiss: { withAnimation(.easeInOut(duration: 0.3)) { showingChatHistory = false; chatHistoryOffset = screenWidth } }).background(styles.colors.menuBackground) }.background(styles.colors.menuBackground).zIndex(100).contentShape(Rectangle()).frame(width: screenWidth).background(styles.colors.menuBackground).offset(x: chatHistoryOffset).zIndex(2)

      }
      .environment(\.settingsScrollingDisabled, isSwipingSettings)
      // Present New Entry Sheet Modally
      .fullScreenCover(isPresented: $appState.presentNewJournalEntrySheet) {
          EditableFullscreenEntryView(
              onSave: { text, mood, intensity in
                  print("[MainTabView] New Entry Saved.")
                  let newEntry = JournalEntry(text: text, mood: mood, date: Date(), intensity: intensity)
                  Task {
                      let embeddingVector = await generateEmbedding(for: newEntry.text)
                      do {
                          try databaseService.saveJournalEntry(newEntry, embedding: embeddingVector)
                          await MainActor.run {
                               appState._journalEntries.insert(newEntry, at: 0)
                               appState._journalEntries.sort { $0.date > $1.date }
                               withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                   appState.journalExpandedEntryId = newEntry.id
                               }
                               print("[MainTabView] Saved new entry, state updated.")
                               // Switch tab directly after saving state
                               self.selectedTab = 0
                               print("[MainTabView] Switched to Journal tab (0) after save.")
                          }
                          await triggerAllInsightGenerations(llmService: LLMService.shared, databaseService: databaseService, appState: appState)
                      } catch {
                          print("‼️ Error saving new journal entry from MainTabView: \(error)")
                      }
                  }
              },
              onCancel: {
                  print("[MainTabView] New Entry Cancelled. No tab switch.")
              },
              autoFocusText: true,
              startFaded: true // Pass true here for the fade effect
          )
      }
      .onAppear {
          bottomSheetOffset = peekHeight - fullSheetHeight
          if !appState.hasSeenOnboarding { appState.hasSeenOnboarding = true }
          // Notification observers...
           NotificationCenter.default.addObserver(forName: .toggleSettingsNotification, object: nil, queue: .main) { _ in print("[MainTabView] Received toggleSettingsNotification"); withAnimation(.easeInOut(duration: 0.3)) { showingSettings.toggle(); settingsOffset = showingSettings ? 0 : -screenWidth } }
           NotificationCenter.default.addObserver(forName: .toggleChatHistoryNotification, object: nil, queue: .main) { _ in print("[MainTabView] Received toggleChatHistoryNotification"); withAnimation(.easeInOut(duration: 0.3)) { showingChatHistory.toggle(); chatHistoryOffset = showingChatHistory ? 0 : screenWidth } }
           NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in withAnimation(.easeInOut(duration: 0.25)) { isKeyboardVisible = true } }
           NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in withAnimation(.easeInOut(duration: 0.25)) { isKeyboardVisible = false } }
      }
       // Keep observer for tab switching notification (used by Reflect/Insights buttons)
       .onReceive(NotificationCenter.default.publisher(for: .switchToTabNotification)) { notification in
             print("[MainTabView] Received switchToTabNotification")
             if let userInfo = notification.userInfo, let tabIndex = userInfo["tabIndex"] as? Int {
                 print("[MainTabView] Current tab: \(selectedTab), Requested tab: \(tabIndex)")
                  if tabIndex >= 0 && tabIndex < 3 {
                      if selectedTab != tabIndex {
                           print("[MainTabView] Switching to tab index: \(tabIndex)")
                          selectedTab = tabIndex
                      } else {
                          print("[MainTabView] Already on tab index: \(tabIndex). No switch needed.")
                      }
                  } else { print("[MainTabView] Error: Received invalid tab index \(tabIndex)") }
             } else { print("[MainTabView] Error: Received notification without valid tabIndex") }
       }
       // Modified onChange to only reset flag after dismissal
       .onChange(of: appState.presentNewJournalEntrySheet) { _, isPresented in
            // Only act when the sheet is dismissed
            if !isPresented {
                // Reset the flag in AppState if it was set
                if appState.tabToSelectAfterSheetDismissal != nil {
                    print("[MainTabView] Sheet dismissed, resetting tabToSelectAfterSheetDismissal flag.")
                    appState.tabToSelectAfterSheetDismissal = nil
                }
            }
        }
      .environment(\.keyboardVisible, isKeyboardVisible)
  }
}

// ... (EnvironmentKey, NavigationTabButton, ScaleButtonStyle remain the same) ...

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

// Modify NavigationTabButton to accept index and callback
struct NavigationTabButton: View {
  let icon: String
  let title: String
  let isSelected: Bool
  let index: Int // Add index
  var foregroundColor: Color = Color.white
  let action: (Int) -> Void // Change action to accept index
  @ObservedObject private var styles = UIStyles.shared

  private let buttonWidth: CGFloat = 80
  private let iconSize: CGFloat = 24
  private let underscoreHeight: CGFloat = 4

  var body: some View {
      Button(action: { action(index) }) { // Call action with index
          VStack(spacing: 6) {
              Spacer()
              Image(systemName: icon)
                  .font(.system(size: iconSize, weight: isSelected ? .bold : .regular))
                  .foregroundColor(foregroundColor)
                  .frame(height: iconSize)
              Text(title)
                  .font(isSelected ?
                        .system(size: 12, weight: .bold, design: .monospaced) :
                        styles.typography.caption)
                  .foregroundColor(foregroundColor)
              Rectangle()
                  .fill(foregroundColor)
                  .frame(width: 40, height: underscoreHeight)
                  .opacity(isSelected ? 1 : 0)
              Spacer(minLength: 2)
          }
          .frame(width: buttonWidth)
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