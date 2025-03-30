import SwiftUI

// Old ChatBubble struct definition (restored)
struct ChatBubble: View {
    let message: ChatMessage // Use the correct model type
    let isExpanded: Bool
    let onTap: () -> Void
    @State private var isCopied: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    // @EnvironmentObject var chatManager: ChatManager // Not needed in old bubble

    private let styles = UIStyles.shared

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .textSelection(.enabled) // Keep text selection
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.userBubbleText)
                        .padding(styles.layout.paddingM)
                        .background(styles.colors.userBubbleColor)
                        .clipShape(ChatBubbleShape(isUser: true))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .contentShape(Rectangle()) // Ensure tap area covers padding
                        // .padding(.vertical, 8) // Remove extra vertical padding from old
                        .onTapGesture {
                            // Dismiss keyboard first, then handle the tap
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            onTap()
                        }

                    if isExpanded {
                        Button(action: {
                            // Copy to clipboard
                            UIPasteboard.general.string = message.text

                            // Show confirmation
                            withAnimation {
                                isCopied = true
                            }

                            // Reset after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    isCopied = false
                                }
                            }
                        }) {
                            Image(systemName: isCopied ? "checkmark" : "rectangle.on.rectangle")
                                .font(.system(size: 16))
                                .foregroundColor(isCopied ? styles.colors.accent : Color.gray.opacity(0.9))
                        }
                        .padding(.trailing, 8)
                        .padding(.top, 3)
                        .transition(.opacity)
                    }
                }
                 .padding(.leading, 40) // Indent user messages more from old
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .textSelection(.enabled) // Keep text selection
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.assistantBubbleText)
                        .padding(styles.layout.paddingM) // Added padding like user bubble
                        .background(styles.colors.assistantBubbleColor)
                        .clipShape(ChatBubbleShape(isUser: false))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Dismiss keyboard first, then handle the tap
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            onTap()
                        }

                    if isExpanded {
                        Button(action: {
                            // Copy to clipboard
                            UIPasteboard.general.string = message.text

                            // Show confirmation
                            withAnimation {
                                isCopied = true
                            }

                            // Reset after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    isCopied = false
                                }
                            }
                        }) {
                            Image(systemName: isCopied ? "checkmark" : "rectangle.on.rectangle")
                                .font(.system(size: 16))
                                .foregroundColor(isCopied ? styles.colors.accent : Color.gray.opacity(0.9))
                        }
                        .padding(.leading, 8)
                        .padding(.top, 6)
                        .transition(.opacity)
                    }
                }
                 .padding(.trailing, 40) // Indent AI messages more from old

                Spacer()
            }
        }
         // Remove frame alignment from current version
    }
}

// Old ChatBubbleShape (restored radius)
struct ChatBubbleShape: Shape {
  var isUser: Bool
  private let cornerRadius: CGFloat = 12 // Use original radius

  func path(in rect: CGRect) -> Path {
      let path = UIBezierPath(
          roundedRect: rect,
          byRoundingCorners: isUser
              ? [.topLeft, .topRight, .bottomLeft]
              : [.topLeft, .topRight, .bottomRight],
          cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
      )
      return Path(path.cgPath)
  }
}

// Old TypingIndicator struct definition (restored)
struct TypingIndicator: View {
    private let styles = UIStyles.shared
    @State private var scale: CGFloat = 0.5 // Matches current implementation start

    var body: some View {
        HStack { // Keep outer HStack from old
            HStack(spacing: styles.layout.spacingS) { // Use spacing from old
                ForEach(0..<3) { index in
                    Circle()
                        .fill(styles.colors.offWhite) // Use offWhite from old
                        .frame(width: 8, height: 8)
                        .scaleEffect(scale)
                        .animation(
                            Animation.easeInOut(duration: 0.6) // Use duration from old
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2), // Use delay from old
                            value: scale
                        )
                }
            }
            .padding(styles.layout.paddingM) // Use padding from old
            .background(
                styles.colors.assistantBubbleColor // Use assistant color from old
                    .clipShape(ChatBubbleShape(isUser: false)) // Use shape from old
            )
            Spacer() // Keep spacer from old
        }
        .padding(.leading, styles.layout.paddingL) // Add leading padding like old bubbles
        .padding(.trailing, 40) // Ensure it doesn't go full width
        .onAppear {
            scale = 1.0 // Animate to full size
        }
    }
}

// Main ReflectionsView
struct ReflectionsView: View {
    @EnvironmentObject var appState: AppState // Keep
    @EnvironmentObject var chatManager: ChatManager // Keep
    // @EnvironmentObject var databaseService: DatabaseService // Keep commented out

    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled // Keep
    @Environment(\.bottomSheetExpanded) private var bottomSheetExpanded // Keep
    @State private var messageText: String = "" // Keep
    @State private var showingSubscriptionPrompt: Bool = false // Keep
    @Binding var tabBarOffset: CGFloat // Keep
    @Binding var lastScrollPosition: CGFloat // Keep
    @Binding var tabBarVisible: Bool // Keep
    @FocusState private var isInputFocused: Bool // Keep
    @State private var textEditorHeight: CGFloat = 30 // Keep (but old UI logic will control it)
    @State private var expandedMessageId: UUID? = nil // Keep

    // Function to show chat history (passed from parent)
    var showChatHistory: () -> Void // Keep

    // Access to shared styles
    private let styles = UIStyles.shared // Keep

    var body: some View {
        ZStack {
            // Background - using standard black background for the view itself (from old)
            styles.colors.appBackground
                .ignoresSafeArea()

            // Add a tap gesture to the entire view to dismiss keyboard (from old)
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    isInputFocused = false
                }

            VStack(spacing: 0) {
                // Header (Identical to old, keep)
                ZStack(alignment: .center) {
                    VStack(spacing: 8) {
                        Text("Reflect")
                            .font(styles.typography.title1)
                            .foregroundColor(styles.colors.text)
                        Rectangle()
                            .fill(styles.colors.accent)
                            .frame(width: 20, height: 3)
                    }
                    HStack {
                        Button(action: {
                            NotificationCenter.default.post(name: NSNotification.Name("ToggleSettings"), object: nil)
                        }) {
                            VStack(spacing: 6) {
                                HStack { Rectangle().fill(styles.colors.accent).frame(width: 28, height: 2); Spacer() }
                                HStack { Rectangle().fill(styles.colors.accent).frame(width: 20, height: 2); Spacer() }
                            }
                            .frame(width: 36, height: 36)
                        }
                        Spacer()
                        Menu {
                            Button(action: { chatManager.startNewChat() }) {
                                Label("New Chat", systemImage: "square.and.pencil")
                            }
                            Button(action: showChatHistory) {
                                Label("Chat History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            }
                        } label: {
                            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                .font(.system(size: 22))
                                .foregroundColor(styles.colors.text)
                                .frame(width: 36, height: 36)
                        }
                    }
                    .padding(.horizontal, styles.layout.paddingXL)
                }
                .padding(.top, 8)
                .padding(.bottom, 8)

                // Chat messages
                ScrollViewReader { scrollView in
                    ScrollView {
                        // Inspiring prompt - only show when chat is empty (Use chatManager data)
                        if chatManager.currentChat.messages.isEmpty { // Adapted from old logic
                            VStack(alignment: .center, spacing: styles.layout.spacingL) {
                                Text("My AI")
                                    .font(styles.typography.headingFont)
                                    .foregroundColor(styles.colors.text)
                                    .padding(.bottom, 4)
                                Text("Ask questions, find clarity.")
                                    .font(styles.typography.bodyLarge)
                                    .foregroundColor(styles.colors.accent)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, styles.layout.paddingXL)
                            .padding(.vertical, styles.layout.spacingXL * 1.5)
                            .padding(.top, 80)
                            .padding(.bottom, 40)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        styles.colors.appBackground,
                                        styles.colors.appBackground.opacity(0.9)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }

                        LazyVStack(spacing: styles.layout.spacingL) {
                            // Iterate over messages from ChatManager's current chat
                            ForEach(chatManager.currentChat.messages) { message in
                                // Use the restored ChatBubble
                                ChatBubble(
                                    message: message,
                                    isExpanded: expandedMessageId == message.id,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            expandedMessageId = (expandedMessageId == message.id) ? nil : message.id
                                        }
                                    }
                                )
                                .id(message.id)
                                // REMOVED: .swipeActions and .contextMenu from current version
                            }

                            // Observe isTyping directly from ChatManager
                            if chatManager.isTyping {
                                // Use the restored TypingIndicator
                                TypingIndicator()
                                // REMOVED: id("TypingIndicator")
                            }

                            // Invisible anchor to scroll to (from old)
                            Color.clear
                                .frame(height: 1)
                                .id("BottomAnchor")
                        }
                        .padding(.horizontal, styles.layout.paddingL)
                        .padding(.vertical, styles.layout.paddingL)
                        .padding(.bottom, 20) // Keep original padding
                    }
                    .onChange(of: chatManager.currentChat.messages.count) { _, _ in
                        // Use simpler scrollToBottom from old version
                        scrollToBottom(proxy: scrollView, anchor: "BottomAnchor")
                    }
                    .onChange(of: chatManager.isTyping) { _, newValue in
                        // Use simpler scrollToBottom from old version
                        // Scroll slightly later after typing indicator appears/disappears
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                              // Always scroll to bottom anchor
                              scrollToBottom(proxy: scrollView, anchor: "BottomAnchor")
                         }
                    }
                    .onAppear {
                        // Use simpler scrollToBottom from old version
                        scrollToBottom(proxy: scrollView, anchor: "BottomAnchor")
                    }
                    // Add clear background with gestures (from old)
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isInputFocused = false
                            }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { _ in
                                isInputFocused = false
                            }
                    )
                } // End ScrollViewReader

                // Message input container - only shown when bottom sheet is closed (Reverted to Old Structure)
                if !bottomSheetExpanded {
                    VStack(spacing: 0) {
                        HStack(alignment: .bottom, spacing: styles.layout.spacingM) {
                            // Input field with dynamic height (Old structure)
                            ZStack(alignment: .topLeading) {
                                // Use chatManager.isTyping for disabled state
                                if messageText.isEmpty && !chatManager.isTyping {
                                    Text("Ask anything") // Old placeholder
                                        .font(styles.typography.bodyFont)
                                        .foregroundColor(styles.colors.placeholderText)
                                        .padding(.leading, 8 + 5) // Old padding calculation (approx)
                                        .padding(.top, 8) // Old padding
                                        .allowsHitTesting(false)
                                }

                                GeometryReader { geometry in
                                    TextEditor(text: chatManager.isTyping ? .constant("") : $messageText)
                                        .font(styles.typography.bodyFont)
                                        .padding(4) // Old padding
                                        .background(Color.clear) // Old background
                                        .foregroundColor(chatManager.isTyping ? styles.colors.textDisabled : styles.colors.text)
                                        .frame(height: textEditorHeight) // Use state variable
                                        .colorScheme(.dark) // Old setting
                                        .disabled(chatManager.isTyping)
                                        .scrollContentBackground(.hidden) // Old setting
                                        .focused($isInputFocused)
                                        .onChange(of: messageText) { _, newValue in
                                            // Old height calculation logic
                                            let availableWidth = geometry.size.width - 16 // Old calculation (approx)
                                            let font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular) // Assuming same font
                                            let attributes = [NSAttributedString.Key.font: font]
                                            let size = (newValue as NSString).size(withAttributes: attributes)

                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                // Check width OR newline for expansion
                                                if size.width > availableWidth || newValue.contains("\n") {
                                                    textEditorHeight = 60 // Old expanded height
                                                } else {
                                                    textEditorHeight = 30 // Old single line height
                                                }
                                            }
                                        }
                                }
                                .frame(height: textEditorHeight) // Apply calculated height
                            }
                            .padding(8) // Old padding
                            .background(styles.colors.reflectionsNavBackground) // Old background color
                            .cornerRadius(20) // Old corner radius

                            // Send button (Old structure)
                            Button(action: sendMessage) { // Keep calling current sendMessage
                                if chatManager.isTyping {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(styles.colors.appBackground) // Old color
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(styles.colors.appBackground) // Old color
                                }
                            }
                            .frame(width: 40, height: 40)
                            .background(styles.colors.accent)
                            .clipShape(Circle())
                            .disabled(messageText.isEmpty && !chatManager.isTyping) // Use chatManager.isTyping
                            .opacity((messageText.isEmpty && !chatManager.isTyping) ? 0.5 : 1.0) // Use chatManager.isTyping
                        }
                        .padding(.vertical, styles.layout.paddingM) // Old padding
                        .padding(.horizontal, styles.layout.paddingL) // Old padding

                        Spacer().frame(height: 40) // Old spacer height
                    }
                    .background( // Old background container
                        styles.colors.reflectionsNavBackground
                            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                             .ignoresSafeArea(.container, edges: .bottom) // Keep ignoresSafeArea
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity)) // Keep transition
                } // End if !bottomSheetExpanded
            } // End VStack
        } // End ZStack
        .alert(isPresented: $showingSubscriptionPrompt) { // Keep alert
            Alert(
                title: Text("Daily Limit Reached"),
                message: Text("You've used all your free reflections for today. Upgrade to premium for unlimited reflections."),
                primaryButton: .default(Text("Upgrade")) {
                    // TODO: Show subscription options / navigate to settings?
                },
                secondaryButton: .cancel(Text("Maybe Later"))
            )
        }
         // Keep commented-out receiver
         /*
         .onReceive(chatManager.limitReachedPublisher) { _ in
             showingSubscriptionPrompt = true
         }
         */
    } // End body

    // Function to calculate TextEditor height dynamically (Keep current version as it's better)
    private func calculateEditorHeight(text: String, geometry: GeometryProxy) -> CGFloat {
        let font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular) // Match TextEditor font
        let attributes = [NSAttributedString.Key.font: font]
        let textWidth = geometry.size.width - (8 * 2) - (5 * 2) // Account for ZStack padding and TextEditor internal padding

        // Calculate the bounding box for the text
        let size = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let estimatedSize = (text as NSString).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)

        let baseHeight: CGFloat = 30 // Minimum height for roughly one line + padding
        let maxHeight: CGFloat = 100 // Maximum height (e.g., 4-5 lines)
        let calculatedHeight = max(baseHeight, estimatedSize.height + (8 * 2)) // Add vertical padding

        return min(calculatedHeight, maxHeight)
    }


    // Local function to handle sending the message via the chatManager (Keep Current Logic)
    private func sendMessage() {
        if chatManager.isTyping {
            // TODO: Implement stop functionality if needed in ChatManager/LLMService
            print("Stop request (not implemented in ChatManager yet)")
            return
        }

        let messageToSend = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageToSend.isEmpty else { return }

        isInputFocused = false // Dismiss keyboard
        let textToSend = messageText // Capture current text
        messageText = "" // Clear input field immediately

        // Reset height after clearing text (Use old logic's height)
         withAnimation(.easeInOut(duration: 0.1)) {
             textEditorHeight = 30 // Reset to single line height
         }

        // Call the correct method on the observed object instance
        chatManager.sendUserMessageToAI(text: textToSend)
    }

    // Simplified scrolling function (Keep Current Version)
    private func scrollToBottom(proxy: ScrollViewProxy, anchor: String) {
         DispatchQueue.main.async { // Ensure scroll happens after UI updates
             withAnimation(.easeOut(duration: 0.3)) { // Add animation
                 proxy.scrollTo(anchor, anchor: .bottom)
             }
         }
    }
}

// Extension for TextEditor height calculation (Keep)
extension View {
     func calculateEditorHeight(text: String, geometry: GeometryProxy) -> CGFloat {
         let font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular) // Match TextEditor font
         let attributes = [NSAttributedString.Key.font: font]
         // Calculate width available inside TextEditor (Geometry - ZStack Padding - TextEditor Padding)
         let textWidth = geometry.size.width - (8 * 2) - (5 * 2)

         let size = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
         let estimatedSize = (text as NSString).boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)

         let baseHeight: CGFloat = 30 // Minimum height for roughly one line + internal padding
         let maxHeight: CGFloat = 100 // Maximum height (e.g., ~4-5 lines)
         // Add TextEditor's vertical padding (approx 8 top + 8 bottom)
         let calculatedHeight = max(baseHeight, ceil(estimatedSize.height) + 16)

         return min(calculatedHeight, maxHeight)
     }
}