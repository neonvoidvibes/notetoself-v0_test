import SwiftUI
import Combine

// Define standard notification name
extension Notification.Name {
    static let switchToTabNotification = Notification.Name("SwitchToTabNotification")
    // Keep existing settings toggle notification
    static let toggleSettingsNotification = Notification.Name("ToggleSettings")
     // Keep existing chat history toggle notification
     static let toggleChatHistoryNotification = Notification.Name("ToggleChatHistory")
}


struct MainTabView: View {
  @EnvironmentObject private var appState: AppState // Use EnvironmentObject
  @EnvironmentObject private var chatManager: ChatManager // Use EnvironmentObject
  @EnvironmentObject private var databaseService: DatabaseService // Inject DatabaseService
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

  // Function to handle tab switching and closing bottom sheet
   private func switchTab(to index: Int) {
       guard index != selectedTab else { // Don't do anything if already on the target tab
           // Close sheet if trying to tap current tab's button again
           if bottomSheetExpanded {
               withAnimation(styles.animation.bottomSheetAnimation) {
                   bottomSheetExpanded = false
                   bottomSheetOffset = peekHeight - fullSheetHeight
               }
           }
           return
       }

       DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Keep delay for visual feedback
           selectedTab = index
           // Always close bottom sheet on tab switch from nav buttons
           withAnimation(styles.animation.bottomSheetAnimation) {
               bottomSheetExpanded = false
               bottomSheetOffset = peekHeight - fullSheetHeight
           }
       }
   }

  var body: some View {
      ZStack {
          // Base background layer
          styles.colors.appBackground.ignoresSafeArea()
          // Input area background
          styles.colors.inputBackground.ignoresSafeArea()

          // Conditional content background
          if !bottomSheetExpanded {
              if selectedTab == 0 || selectedTab == 1 {
                  styles.colors.appBackground.ignoresSafeArea()
              }
              // No specific background needed for Tab 2 (Reflect) when closed, handled by inputBackground
          } else {
              styles.colors.bottomSheetBackground.ignoresSafeArea()
          }

          // Status bar area
          VStack(spacing: 0) {
              styles.colors.statusBarBackground
                  .frame(height: styles.layout.topSafeAreaPadding)
              Spacer()
          }
          .ignoresSafeArea()

          // Main content container
          VStack(spacing: 0) {
              ZStack {
                  // Use TabView for content switching
                   TabView(selection: $selectedTab) {
                       JournalView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true))
                            .tag(0)
                       InsightsView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true))
                           .tag(1)
                       ReflectionsView(tabBarOffset: .constant(0), lastScrollPosition: .constant(0), tabBarVisible: .constant(true),
                           showChatHistory: {
                               withAnimation(.easeInOut(duration: 0.3)) { showingChatHistory = true; chatHistoryOffset = 0 }
                           })
                           .environmentObject(chatManager)
                           .tag(2)
                   }
                   .tabViewStyle(.page(indexDisplayMode: .never)) // Keep paging style
                   // Remove tab switch animation here to prevent conflict with modal presentation
                   // .animation(styles.animation.tabSwitchAnimation, value: selectedTab)

              }
              .offset(y: bottomSheetExpanded ? -fullSheetHeight * 0.25 : 0)
              .animation(styles.animation.bottomSheetAnimation, value: bottomSheetExpanded)
              .environment(\.bottomSheetExpanded, bottomSheetExpanded)
              // Auto-close gestures... (kept as is)
              .onTapGesture { if bottomSheetExpanded { withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded = false; bottomSheetOffset = peekHeight - fullSheetHeight } } }
              .simultaneousGesture( DragGesture(minimumDistance: 1).onChanged { _ in if bottomSheetExpanded { withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded = false; bottomSheetOffset = peekHeight - fullSheetHeight } } } )
              .simultaneousGesture( TapGesture().onEnded { if bottomSheetExpanded { withAnimation(styles.animation.bottomSheetAnimation) { bottomSheetExpanded = false; bottomSheetOffset = peekHeight - fullSheetHeight } } } )


              // Bottom sheet / tab bar
              GeometryReader { geometry in
                  if !isKeyboardVisible {
                      VStack(spacing: 0) {
                          // Chevron button
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

                          // Tab buttons (use direct callback)
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

          // Overlays (Settings, Chat History)... (kept as is)
           // Dim overlay for Settings
           Color.black.opacity(showingSettings ? 0.5 : 0).opacity(dragOffset != 0 ? (showingSettings ? 0.5 - (dragOffset / screenWidth) * 0.5 : (dragOffset / screenWidth) * 0.5) : (showingSettings ? 0.5 : 0)).ignoresSafeArea().allowsHitTesting(false)
           // Dim overlay for Chat History
           Color.black.opacity(showingChatHistory ? 0.5 : 0).ignoresSafeArea().allowsHitTesting(false)
           // Settings overlay
           ZStack(alignment: .top) { SettingsView().environmentObject(databaseService).background(styles.colors.menuBackground) }.background(styles.colors.menuBackground).zIndex(100).contentShape(Rectangle()).simultaneousGesture(settingsDrag).frame(width: screenWidth).background(styles.colors.menuBackground).offset(x: settingsOffset).zIndex(2)
           // Chat History overlay
           ZStack(alignment: .top) { ChatHistoryView(chatManager: chatManager, onSelectChat: { selectedChat in chatManager.loadChat(selectedChat); withAnimation(.easeInOut(duration: 0.3)) { showingChatHistory = false; chatHistoryOffset = screenWidth }; if selectedTab != 2 { selectedTab = 2 } }, onDismiss: { withAnimation(.easeInOut(duration: 0.3)) { showingChatHistory = false; chatHistoryOffset = screenWidth } }).background(styles.colors.menuBackground) }.background(styles.colors.menuBackground).zIndex(100).contentShape(Rectangle()).frame(width: screenWidth).background(styles.colors.menuBackground).offset(x: chatHistoryOffset).zIndex(2)

      }
      // IMPORTANT: Remove the mainScrollingDisabled environment variable to allow scrolling
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
                               // Ensure tab is Journal after save
                               if selectedTab != 0 { selectedTab = 0 }
                          }
                          await triggerAllInsightGenerations(llmService: LLMService.shared, databaseService: databaseService, appState: appState)
                      } catch {
                          print("‼️ Error saving new journal entry from MainTabView: \(error)")
                      }
                  }
                  // Flag is automatically set to false by .fullScreenCover dismissal
              },
              onCancel: {
                  print("[MainTabView] New Entry Cancelled.")
                  // Switch back to Insights tab if cancelled
                  if selectedTab != 1 {
                       print("[MainTabView] Switching back to Insights tab (1).")
                       // Use standard notification for consistency, MainTabView will receive it
                       NotificationCenter.default.post(name: .switchToTabNotification, object: nil, userInfo: ["tabIndex": 1])
                  }
                   // Flag is automatically set to false by .fullScreenCover dismissal
              },
              autoFocusText: true
          )
      }
      .onAppear {
          bottomSheetOffset = peekHeight - fullSheetHeight
          if !appState.hasSeenOnboarding { appState.hasSeenOnboarding = true }
          // Add notification observers... (kept as is)
           NotificationCenter.default.addObserver(forName: .toggleSettingsNotification, object: nil, queue: .main) { _ in withAnimation(.easeInOut(duration: 0.3)) { showingSettings.toggle(); settingsOffset = showingSettings ? 0 : -screenWidth } }
           NotificationCenter.default.addObserver(forName: .toggleChatHistoryNotification, object: nil, queue: .main) { _ in withAnimation(.easeInOut(duration: 0.3)) { showingChatHistory.toggle(); chatHistoryOffset = showingChatHistory ? 0 : screenWidth } }
           NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in withAnimation(.easeInOut(duration: 0.25)) { isKeyboardVisible = true } }
           NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in withAnimation(.easeInOut(duration: 0.25)) { isKeyboardVisible = false } }
      }
       // Add observer for tab switching notification
       .onReceive(NotificationCenter.default.publisher(for: .switchToTabNotification)) { notification in
             print("[MainTabView] Received switchToTabNotification") // Debug Print
             if let userInfo = notification.userInfo, let tabIndex = userInfo["tabIndex"] as? Int {
                 print("[MainTabView] Current tab: \(selectedTab), Requested tab: \(tabIndex)") // Debug Print
                  if tabIndex >= 0 && tabIndex < 3 { // Basic validation
                      if selectedTab != tabIndex { // Avoid redundant sets
                           print("[MainTabView] Switching to tab index: \(tabIndex)") // Debug Print
                          selectedTab = tabIndex
                      } else {
                          print("[MainTabView] Already on tab index: \(tabIndex). No switch needed.") // Debug Print
                      }
                  } else {
                      print("[MainTabView] Error: Received invalid tab index \(tabIndex)")
                  }
             } else {
                 print("[MainTabView] Error: Received notification without valid tabIndex")
             }
       }
       // Handle triggering the sheet presentation
        .onChange(of: appState.presentNewJournalEntrySheet) { _, shouldPresent in
             if shouldPresent {
                 print("[MainTabView] Detected presentNewJournalEntrySheet = true")
                 // Ensure we are on the Journal tab *before* the sheet tries to present
                 // Disable animation during this specific tab switch
                 if selectedTab != 0 {
                     print("[MainTabView] Switching to Journal tab (0) without animation.")
                     withAnimation(nil) { // Disable animation
                         selectedTab = 0
                     }
                 }
                 // The .fullScreenCover modifier will handle the actual presentation
                 // We don't need to reset the flag here, sheet dismissal handles it.
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