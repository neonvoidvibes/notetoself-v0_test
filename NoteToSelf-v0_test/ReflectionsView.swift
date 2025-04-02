import SwiftUI

// Old ChatBubble struct definition (restored)
struct ChatBubble: View {
    let message: ChatMessage // Use the correct model type
    let isExpanded: Bool
    let onTap: () -> Void
    @State private var isCopied: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    // @EnvironmentObject var chatManager: ChatManager // Not needed in old bubble

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .textSelection(.enabled) // Keep text selection
                        .font(styles.typography.bodyFont) // Larger font
                        .lineSpacing(6) // Add more line spacing
                        .foregroundColor(styles.colors.userBubbleText)
                        .padding(styles.layout.paddingM) // Restore original padding
                        .background(styles.colors.userBubbleColor) // Restore background
                        .clipShape(ChatBubbleShape(isUser: true))
                        .clipShape(ChatBubbleShape(isUser: false)) // Apply shape to Text content only
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
                        .padding(.trailing, 8)
                        .padding(.top, 3)
                        .transition(.opacity)
                    }
                }
                 .padding(.leading, UIScreen.main.bounds.width * 0.25) // Make user messages 3/4 width
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .textSelection(.enabled) // Keep text selection
                        .font(styles.typography.bodyFont) // Larger font
                        .lineSpacing(6) // Add more line spacing
                        .foregroundColor(styles.colors.assistantBubbleText)
                        .padding(styles.layout.paddingM) // Added padding like user bubble
                        // REMOVED: .background(styles.colors.assistantBubbleColor)
                        .clipShape(ChatBubbleShape(isUser: false))
                        // REMOVED: .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
                // Ensure padding is explicitly zero
                .padding(.trailing, 0)
                .padding(.leading, 0)

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

// Replace the entire ReflectionsView implementation with this cleaner approach

struct ReflectionsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager

    @Environment(\.bottomSheetExpanded) private var bottomSheetExpanded
    @State private var messageText: String = ""
    @State private var showingSubscriptionPrompt: Bool = false
    @Binding var tabBarOffset: CGFloat
    @Binding var lastScrollPosition: CGFloat
    @Binding var tabBarVisible: Bool
    @FocusState private var isInputFocused: Bool
    @State private var expandedMessageId: UUID? = nil

    // CRITICAL: Track scroll position manually
    @State private var scrollAtBottom: Bool = true

    // Function to show chat history (passed from parent)
    var showChatHistory: () -> Void

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    var body: some View {
        ZStack {
            // Background (Reverted to original)
            styles.colors.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
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

                // Chat content - FIXED HEIGHT to prevent layout shifts
                GeometryReader { geometry in
                    ScrollViewReader { scrollView in
                        ScrollView {
                            // Empty state
                            if chatManager.currentChat.messages.isEmpty {
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

                            // Messages - NO ANIMATIONS on the container
                            LazyVStack(spacing: styles.layout.spacingL) {
                                ForEach(chatManager.currentChat.messages) { message in
                                    ChatBubble(
                                        message: message,
                                        isExpanded: expandedMessageId == message.id,
                                        onTap: {
                                            expandedMessageId = (expandedMessageId == message.id) ? nil : message.id
                                        }
                                    )
                                    .id(message.id)
                                }

                                // Typing indicator
                                if chatManager.isTyping {
                                    BreathingDotIndicator() // Use the new component
                                        .id("TypingIndicator") // Keep ID for scrolling if needed
                                        .transition(.opacity) // Add fade transition
                                }

                                // Scroll anchor - make it stick directly to the last message with minimal height
                                Color.clear
                                    .frame(height: 1)
                                    .id("BottomAnchor")
                            }
                            .padding(.horizontal, styles.layout.paddingL)
                            .padding(.vertical, styles.layout.paddingL)
                            // Reduce bottom padding to prevent excessive scrolling space
                            .padding(.bottom, 8)
                        }
                        .frame(height: geometry.size.height)
                        .onTapGesture {
                            // Dismiss keyboard on tap
                            if isInputFocused {
                                isInputFocused = false
                            }
                        }
                        // --- Refined Scrolling Logic ---
                        .onChange(of: chatManager.currentChat.messages.count) { _, _ in
                            // Scroll to the *last message* when the count changes
                            if scrollAtBottom, let lastMessageId = chatManager.currentChat.messages.last?.id {
                                // Scroll immediately, ScrollViewReader waits for the ID
                                scrollView.scrollTo(lastMessageId, anchor: .bottom)
                                print("Scrolled to last message: \(lastMessageId)")
                            }
                        }
                        .onChange(of: chatManager.isTyping) { _, isTyping in
                            // Scroll to the indicator *when it appears*
                            if isTyping && scrollAtBottom {
                                // Scroll immediately, ScrollViewReader waits for the ID
                                scrollView.scrollTo("TypingIndicator", anchor: .bottom)
                                print("Scrolled to TypingIndicator")
                            }
                        }
                        .onAppear {
                            // Initial scroll: Target last message if available, else anchor
                            if let lastMessageId = chatManager.currentChat.messages.last?.id {
                                scrollView.scrollTo(lastMessageId, anchor: .bottom)
                            } else {
                                scrollView.scrollTo("BottomAnchor", anchor: .bottom)
                            }
                        }
                        // Removed DragGesture interaction with scrollAtBottom
                        // --- End Refined Scrolling Logic ---
                    }
                }

                // Input area - FIXED HEIGHT to prevent layout shifts
                if !bottomSheetExpanded {
                    VStack(spacing: 0) {
                        // Change alignment to .center for vertical alignment
                        HStack(alignment: .center, spacing: styles.layout.spacingM) {
                            // Text input field - FIXED HEIGHT
                            ZStack(alignment: .topLeading) {
                                if messageText.isEmpty && !chatManager.isTyping {
                                    Text("Ask anything")
                                        .font(styles.typography.bodyFont) // Use larger font to match messages
                                        .foregroundColor(styles.colors.placeholderText)
                                        .padding(.leading, 5) // Reduced padding to align with assistant messages
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                }

                                // FIXED HEIGHT TextEditor
                                TextEditor(text: chatManager.isTyping ? .constant("") : $messageText)
                                    .font(styles.typography.bodyFont) // Use larger font to match messages
                                    .padding(4)
                                    .padding(.leading, 1) // Reduced padding to align with assistant messages
                                    .background(Color.clear)
                                    .foregroundColor(chatManager.isTyping ? styles.colors.textDisabled : styles.colors.text)
                                    .frame(height: 40) // FIXED HEIGHT
                                    // REMOVED: .colorScheme(.dark)
                                    .disabled(chatManager.isTyping)
                                    .scrollContentBackground(.hidden)
                                    .focused($isInputFocused)
                                    // REMOVED: .modifier(AdaptiveColorSchemeModifier())
                            }
                            .frame(height: 40) // FIXED HEIGHT
                            .padding(8)
                            // Make the text field area transparent
                            .background(Color.clear)
                            .cornerRadius(20) // Keep the rounding for visual consistency if needed

                            // Send button
                            Button(action: sendMessage) {
                                if chatManager.isTyping {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(styles.colors.appBackground) // Stop icon uses background color
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 20, weight: .bold)) // Make arrow slightly smaller
                                        .foregroundColor(styles.colors.userBubbleText) // Confirm contrast color
                                }
                            }
                            .frame(width: 40, height: 40)
                            .background(styles.colors.accent)
                            .clipShape(Circle())
                            .disabled(messageText.isEmpty && !chatManager.isTyping)
                            .opacity((messageText.isEmpty && !chatManager.isTyping) ? 0.5 : 1.0)
                        }
                        .padding(.vertical, styles.layout.paddingM)
                        .padding(.horizontal, styles.layout.paddingL)

                        Spacer().frame(height: 40)
                    }
                    // Restore the background for the input area container
                    .background(
                        styles.colors.reflectionsNavBackground
                            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                            .ignoresSafeArea(.container, edges: .bottom)
                    )
                }
            }
        }
        .alert(isPresented: $showingSubscriptionPrompt) {
            Alert(
                title: Text("Daily Limit Reached"),
                message: Text("You've used all your free reflections for today. Upgrade to premium for unlimited reflections."),
                primaryButton: .default(Text("Upgrade")) {
                    // TODO: Show subscription options
                },
                secondaryButton: .cancel(Text("Maybe Later"))
            )
        }
        // CRITICAL: Reset scroll position when sending a message
        .onChange(of: isInputFocused) { _, newValue in
            if !newValue {
                // When keyboard is dismissed, we want to stay where we are
            } else {
                // When keyboard appears, we want to scroll to bottom
                scrollAtBottom = true
            }
        }
    }

    private func sendMessage() {
        if chatManager.isTyping {
            print("Stop request (not implemented in ChatManager yet)")
            return
        }

        let messageToSend = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageToSend.isEmpty else { return }

        // Capture text before clearing
        let textToSend = messageText

        // Clear input
        messageText = ""

        // CRITICAL: Set scroll to bottom when sending
        scrollAtBottom = true

        // Send the message
        chatManager.sendUserMessageToAI(text: textToSend)

        // Dismiss keyboard
        isInputFocused = false
    }
}

// Keep the existing ChatBubble, ChatBubbleShape, and TypingIndicator implementations