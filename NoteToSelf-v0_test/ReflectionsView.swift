import SwiftUI

struct ReflectionsView: View {
    @EnvironmentObject var appState: AppState // Use environment object
    // ChatManager is now passed down via environment from MainTabViewContainer
    @EnvironmentObject var chatManager: ChatManager
    // DatabaseService might not be needed directly if ChatManager handles all DB interaction
    // @EnvironmentObject var databaseService: DatabaseService

    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled
    @Environment(\.bottomSheetExpanded) private var bottomSheetExpanded
    @State private var messageText: String = ""
    // isTyping state is now managed by ChatManager
    // @State private var isTyping: Bool = false
    @State private var showingSubscriptionPrompt: Bool = false // Keep for local alert trigger
    @Binding var tabBarOffset: CGFloat // Keep bindings for tab bar animation
    @Binding var lastScrollPosition: CGFloat // Keep bindings for tab bar animation
    @Binding var tabBarVisible: Bool // Keep bindings for tab bar animation
    @FocusState private var isInputFocused: Bool
    @State private var textEditorHeight: CGFloat = 30
    @State private var expandedMessageId: UUID? = nil

    // Function to show chat history (passed from parent)
    var showChatHistory: () -> Void

    // Access to shared styles
    private let styles = UIStyles.shared

    var body: some View {
        ZStack {
            styles.colors.appBackground.ignoresSafeArea()

            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { isInputFocused = false }

            VStack(spacing: 0) {
                // Header (Keep existing header structure)
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
                             Button(action: { chatManager.startNewChat() }) { // Call directly
                                 Label("New Chat", systemImage: "square.and.pencil")
                             }
                             Button(action: showChatHistory) { // Call passed closure
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
                        // Inspiring prompt - only show when chat is empty
                         if chatManager.currentChat.messages.isEmpty { // Use chatManager's data
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
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        // Call deleteMessage directly on chatManager
                                        chatManager.deleteMessage(message)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                // Add context menu for starring
                                .contextMenu {
                                     Button {
                                         chatManager.toggleStarMessage(message)
                                     } label: {
                                         Label(message.isStarred ? "Unstar" : "Star",
                                               systemImage: message.isStarred ? "star.slash.fill" : "star.fill")
                                     }
                                 }
                            }

                            // Observe isTyping directly from ChatManager
                            if chatManager.isTyping {
                                TypingIndicator()
                                    .id("TypingIndicator") // Give it an ID if needed for scrolling
                            }

                            Color.clear
                                .frame(height: 1)
                                .id("BottomAnchor")
                        }
                        .padding(.horizontal, styles.layout.paddingL)
                        .padding(.vertical, styles.layout.paddingL)
                        .padding(.bottom, 20)
                    }
                    .onChange(of: chatManager.currentChat.messages.count) { _, _ in
                        scrollToBottom(proxy: scrollView, anchor: "BottomAnchor")
                    }
                     .onChange(of: chatManager.isTyping) { _, newValue in
                         // Scroll slightly later after typing indicator appears/disappears
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                              let targetAnchor = newValue ? "TypingIndicator" : "BottomAnchor"
                              scrollToBottom(proxy: scrollView, anchor: targetAnchor)
                         }
                     }
                    .onAppear {
                        scrollToBottom(proxy: scrollView, anchor: "BottomAnchor")
                    }
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { isInputFocused = false }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { _ in isInputFocused = false }
                    )
                } // End ScrollViewReader

                // Message input container
                if !bottomSheetExpanded {
                     VStack(spacing: 0) {
                         HStack(alignment: .bottom, spacing: styles.layout.spacingM) {
                             ZStack(alignment: .topLeading) {
                                 // Use chatManager.isTyping for disabled state
                                 if messageText.isEmpty && !chatManager.isTyping {
                                     Text("Ask anything...") // Corrected placeholder text
                                         .font(styles.typography.bodyFont)
                                         .foregroundColor(styles.colors.placeholderText)
                                         .padding(.leading, 8 + 5) // Match TextEditor padding
                                         .padding(.top, 8 + 8)    // Match TextEditor padding
                                         .allowsHitTesting(false) // Let taps pass through
                                 }

                                 GeometryReader { geometry in
                                     TextEditor(text: chatManager.isTyping ? .constant("") : $messageText)
                                         .font(styles.typography.bodyFont)
                                         .padding(.horizontal, 5) // Standard TextEditor horizontal padding
                                         .padding(.vertical, 8)   // Standard TextEditor vertical padding
                                         .background(Color.clear) // Use clear background
                                         .foregroundColor(chatManager.isTyping ? styles.colors.textDisabled : styles.colors.text)
                                         .frame(height: textEditorHeight)
                                         .colorScheme(.dark) // Ensure dark keyboard appearance
                                         .disabled(chatManager.isTyping)
                                         .scrollContentBackground(.hidden) // Use this for clear background
                                         .focused($isInputFocused)
                                         .onChange(of: messageText) { _, newValue in
                                             // Simplified height calculation
                                             let newHeight = calculateEditorHeight(text: newValue, geometry: geometry)
                                             if abs(newHeight - textEditorHeight) > 1 { // Avoid tiny adjustments
                                                 withAnimation(.easeInOut(duration: 0.1)) {
                                                     textEditorHeight = newHeight
                                                 }
                                             }
                                         }
                                 }
                                 .frame(height: textEditorHeight) // Apply calculated height
                             }
                             .padding(8) // Padding around the ZStack
                             .background(styles.colors.secondaryBackground) // Darker background for input area
                             .cornerRadius(20) // Rounded corners for input area

                             // Send / Stop button
                             Button(action: sendMessage) { // Call local sendMessage function
                                 if chatManager.isTyping {
                                     Image(systemName: "stop.fill")
                                         .font(.system(size: 18, weight: .bold))
                                         .foregroundColor(styles.colors.inputContainerBackground) // Use appropriate color
                                 } else {
                                     Image(systemName: "arrow.up")
                                         .font(.system(size: 24, weight: .bold))
                                         .foregroundColor(styles.colors.inputContainerBackground) // Use appropriate color
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

                         Spacer().frame(height: 40) // Bottom spacer
                     }
                     .background(
                         styles.colors.reflectionsNavBackground // Use specific color for container
                             .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                             .ignoresSafeArea(.container, edges: .bottom) // Extend background to bottom edge
                     )
                     .transition(.move(edge: .bottom).combined(with: .opacity)) // Add transition
                } // End if !bottomSheetExpanded
            } // End VStack
        } // End ZStack
        .alert(isPresented: $showingSubscriptionPrompt) { // Use local state for alert
            Alert(
                title: Text("Daily Limit Reached"),
                message: Text("You've used all your free reflections for today. Upgrade to premium for unlimited reflections."),
                primaryButton: .default(Text("Upgrade")) {
                    // TODO: Show subscription options / navigate to settings?
                },
                secondaryButton: .cancel(Text("Maybe Later"))
            )
        }
         // Listen for potential "limit reached" signals if ChatManager implements them
         /*
         .onReceive(chatManager.limitReachedPublisher) { _ in
             showingSubscriptionPrompt = true
         }
         */
    } // End body

    // Function to calculate TextEditor height dynamically
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


    // Local function to handle sending the message via the chatManager
    private func sendMessage() {
        if chatManager.isTyping {
            // TODO: Implement stop functionality if needed in ChatManager/LLMService
            print("Stop request (not implemented in ChatManager yet)")
            return
        }

        let messageToSend = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageToSend.isEmpty else { return }

        // Check limit locally before sending (ChatManager will check again)
        // This provides immediate UI feedback if possible.
        // Requires access to subscription status and count, potentially via AppState or ChatManager directly.
        // For simplicity now, let ChatManager handle the primary check.

        isInputFocused = false // Dismiss keyboard
        let textToSend = messageText // Capture current text
        messageText = "" // Clear input field immediately
        // Reset height after clearing text
         withAnimation(.easeInOut(duration: 0.1)) {
             textEditorHeight = 30 // Reset to single line height
         }


        // Call the correct method on the observed object instance
        chatManager.sendUserMessageToAI(text: textToSend)

        // Note: Logic to show subscription alert might need refinement.
        // If ChatManager exposes a publisher or state for limit reached, observe it here.
        // For now, the check inside ChatManager prevents the API call but doesn't show alert yet.
    }

    // Simplified scrolling function
    private func scrollToBottom(proxy: ScrollViewProxy, anchor: String) {
         DispatchQueue.main.async { // Ensure scroll happens after UI updates
             withAnimation(.easeOut(duration: 0.3)) { // Add animation
                 proxy.scrollTo(anchor, anchor: .bottom)
             }
         }
    }
}

// --- Keep ChatBubble, ChatBubbleShape, TypingIndicator as they were ---
// (Assuming they are defined correctly elsewhere or below)

struct ChatBubble: View {
    let message: ChatMessage // Use the correct model type
    let isExpanded: Bool
    let onTap: () -> Void
    @State private var isCopied: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var chatManager: ChatManager // Needed for starring

    private let styles = UIStyles.shared

    var body: some View {
        HStack(alignment: .top) { // Align tops for icon consistency
            if !message.isUser {
                // Assistant Avatar (Optional)
                 ZStack {
                     Circle().fill(styles.colors.assistantBubbleColor).frame(width: 28, height: 28)
                     Image(systemName: "sparkles").foregroundColor(styles.colors.accent).font(.system(size: 14))
                 }
                 .padding(.trailing, 4)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                 Text(message.text)
                     .textSelection(.enabled) // Allow text selection
                     .padding(.horizontal, styles.layout.paddingM)
                     .padding(.vertical, styles.layout.paddingS + 2) // Slightly more vertical padding
                     .background(message.isUser ? styles.colors.userBubbleColor : styles.colors.assistantBubbleColor)
                     .clipShape(ChatBubbleShape(isUser: message.isUser))
                     .foregroundColor(message.isUser ? styles.colors.userBubbleText : styles.colors.assistantBubbleText)
                     .font(styles.typography.bodyFont)
                     // Apply shadow if needed
                     // .shadow(color: Color.black.opacity(0.1), radius: 3, x: 1, y: 2)
                     .contentShape(Rectangle()) // Ensure tap area covers padding
                     .onTapGesture {
                         UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                         onTap()
                     }

                 // Expanded actions (Copy/Star)
                 if isExpanded {
                     HStack(spacing: 15) {
                         // Copy Button
                         Button {
                             UIPasteboard.general.string = message.text
                             withAnimation { isCopied = true }
                             DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                 withAnimation { isCopied = false }
                             }
                         } label: {
                             Image(systemName: isCopied ? "checkmark" : "doc.on.doc") // Use doc.on.doc for copy
                                 .font(.system(size: 16))
                                 .foregroundColor(isCopied ? styles.colors.accent : styles.colors.textSecondary)
                         }
                         .buttonStyle(PlainButtonStyle()) // Remove button default styling

                         // Star Button
                         Button {
                              chatManager.toggleStarMessage(message)
                         } label: {
                              Image(systemName: message.isStarred ? "star.fill" : "star")
                                 .font(.system(size: 16))
                                 .foregroundColor(message.isStarred ? styles.colors.accent : styles.colors.textSecondary)
                         }
                         .buttonStyle(PlainButtonStyle())

                     }
                     .padding(.horizontal, message.isUser ? 0 : 8) // Adjust padding based on side
                     .padding(.top, 3)
                     .transition(.opacity.combined(with: .offset(y: 5))) // Add slide transition
                 }
            } // End VStack for bubble and actions

            if message.isUser {
                // User Avatar (Optional placeholder)
                // Circle().fill(styles.colors.userBubbleColor).frame(width: 28, height: 28)
                // .padding(.leading, 4)
                 Spacer().frame(width: 32) // Maintain spacing even without avatar
            }

        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .padding(.leading, message.isUser ? 40 : 0) // Indent user messages more
        .padding(.trailing, message.isUser ? 0 : 40) // Indent AI messages more
    }
}


struct ChatBubbleShape: Shape {
    var isUser: Bool
    private let cornerRadius: CGFloat = 16 // Use a consistent radius

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


struct TypingIndicator: View {
    private let styles = UIStyles.shared
    @State private var scale: CGFloat = 0.5 // Start small

    var body: some View {
        HStack(spacing: styles.layout.spacingS / 2) { // Tighter spacing
            ForEach(0..<3) { index in
                Circle()
                    .fill(styles.colors.textSecondary) // Use secondary text color
                    .frame(width: 8, height: 8)
                    .scaleEffect(scale)
                    .animation(
                        Animation.easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15), // Stagger animation
                        value: scale
                    )
            }
        }
        .padding(.horizontal, styles.layout.paddingM)
        .padding(.vertical, styles.layout.paddingS + 4) // Match bubble padding
        .background(styles.colors.assistantBubbleColor)
        .clipShape(ChatBubbleShape(isUser: false))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 40) // Indent like assistant bubble
        .padding(.trailing, 40 + 40) // Ensure it doesn't go full width
        .onAppear {
            scale = 1.0 // Animate to full size
        }
    }
}

// Helper for calculating TextEditor height
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