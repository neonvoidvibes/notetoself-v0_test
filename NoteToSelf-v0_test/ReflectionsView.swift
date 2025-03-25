import SwiftUI

struct ReflectionsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled: Bool
    @State private var messageText: String = ""
    @State private var isTyping: Bool = false
    @State private var showingSubscriptionPrompt: Bool = false
    @Binding var tabBarOffset: CGFloat
    @Binding var lastScrollPosition: CGFloat
    @Binding var tabBarVisible: Bool
    // Add environment property to access bottom sheet state
    @Environment(\.bottomSheetExpanded) private var bottomSheetExpanded: Bool
    @FocusState private var isInputFocused: Bool
    @State private var textEditorHeight: CGFloat = 30
    @State private var expandedMessageId: UUID? = nil
    
    // Chat manager for handling chat history
    @ObservedObject var chatManager: ChatManager
    
    // Function to show chat history from MainTabView
    var showChatHistory: () -> Void
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background - using standard black background for the view itself
            styles.colors.appBackground
                .ignoresSafeArea()
            
            // Add a tap gesture to the entire view to dismiss keyboard
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    isInputFocused = false
                }
            
            VStack(spacing: 0) {
                // Header
                ZStack(alignment: .center) {
                    // Title truly centered
                    VStack(spacing: 8) {
                        Text("Reflect")
                            .font(styles.typography.title1)
                            .foregroundColor(styles.colors.text)
                        
                        Rectangle()
                            .fill(styles.colors.accent)
                            .frame(width: 20, height: 3)
                    }
                    
                    // Menu button on left and filter/history buttons on right
                    HStack {
                        Button(action: {
                            NotificationCenter.default.post(name: NSNotification.Name("ToggleSettings"), object: nil)
                        }) {
                            VStack(spacing: 6) { // Increased spacing between bars
                                HStack {
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 28, height: 2) // Top bar - slightly longer
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
                        
                        Spacer()
                        
                        // Chat history button
                        Menu {
                            Button(action: {
                                // Start a new chat
                                chatManager.startNewChat()
                            }) {
                                Label("New Chat", systemImage: "square.and.pencil")
                            }
                            
                            Button(action: {
                                // Show chat history via MainTabView
                                showChatHistory()
                            }) {
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
                .padding(.top, 8) // Further reduced top padding
                .padding(.bottom, 8)
                
                // Chat messages
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: styles.layout.spacingL) {
                            ForEach(filteredMessages) { message in
                                ChatBubble(
                                    message: message,
                                    isExpanded: expandedMessageId == message.id,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if expandedMessageId == message.id {
                                                expandedMessageId = nil
                                            } else {
                                                expandedMessageId = message.id
                                            }
                                        }
                                    }
                                )
                                .id(message.id)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        chatManager.deleteMessage(message)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            
                            if isTyping {
                                TypingIndicator()
                            }
                            
                            // Invisible anchor to scroll to
                            Color.clear
                                .frame(height: 1)
                                .id("BottomAnchor")
                        }
                        .padding(.horizontal, styles.layout.paddingL)
                        .padding(.vertical, styles.layout.paddingL)
                        .padding(.bottom, 20) // Reduced spacing at the bottom
                    }
                    .onChange(of: chatManager.currentChat.messages.count) { _, _ in
                        scrollToBottom(proxy: scrollView)
                    }
                    .onChange(of: isTyping) { _, _ in
                        scrollToBottom(proxy: scrollView)
                    }
                    .onAppear {
                        scrollToBottom(proxy: scrollView)
                    }
                    // Add a clear background with content shape and tap gesture
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isInputFocused = false
                            }
                    )
                    // Add a drag gesture to detect scrolling
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { _ in
                                isInputFocused = false
                            }
                    )
                }
                
                // Message input container - only shown when bottom sheet is closed
                if !bottomSheetExpanded {
                    VStack(spacing: 0) {
                        HStack(alignment: .bottom, spacing: styles.layout.spacingM) {
                            // Input field with dynamic height
                            ZStack(alignment: .topLeading) {
                                if messageText.isEmpty && !isTyping {
                                    Text("Ask anything")
                                        .font(styles.typography.bodyFont)
                                        .foregroundColor(styles.colors.placeholderText)
                                        .padding(.leading, 8)
                                        .padding(.top, 8)
                                }
                                
                                GeometryReader { geometry in
                                    TextEditor(text: isTyping ? .constant("") : $messageText)
                                        .font(styles.typography.bodyFont)
                                        .padding(4)
                                        .background(Color.clear)
                                        .foregroundColor(isTyping ? styles.colors.textDisabled : styles.colors.text)
                                        .frame(height: textEditorHeight)
                                        .colorScheme(.dark)
                                        .disabled(isTyping)
                                        .scrollContentBackground(.hidden)
                                        .focused($isInputFocused)
                                        .onChange(of: messageText) { _, newValue in
                                            // Calculate if text would wrap based on available width
                                            let availableWidth = geometry.size.width - 16 // Subtract padding
                                            let font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
                                            let attributes = [NSAttributedString.Key.font: font]
                                            let size = (newValue as NSString).size(withAttributes: attributes)
                                            
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                if size.width > availableWidth || newValue.contains("\n") {
                                                    textEditorHeight = 60 // Expand to two rows
                                                } else {
                                                    textEditorHeight = 30 // Single row
                                                }
                                            }
                                        }
                                }
                                .frame(height: textEditorHeight)
                            }
                            .padding(8)
                            .background(styles.colors.reflectionsNavBackground)
                            .cornerRadius(20)
                            
                            // Send button - fixed position
                            Button(action: sendMessage) {
                                if isTyping {
                                    // Stop button
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(styles.colors.appBackground)
                                } else {
                                    // Send button
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(styles.colors.appBackground)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .background(styles.colors.accent)
                            .clipShape(Circle())
                            .disabled(messageText.isEmpty && !isTyping)
                            .opacity((messageText.isEmpty && !isTyping) ? 0.5 : 1.0)
                        }
                        .padding(.vertical, styles.layout.paddingM)
                        .padding(.horizontal, styles.layout.paddingL)
                                                    
                            // Add padding at the bottom to ensure content doesn't get cut off
                            Spacer().frame(height: 40)
                    }
                    .background(
                        styles.colors.reflectionsNavBackground
                            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                    )
                }
            }
        }
        .alert(isPresented: $showingSubscriptionPrompt) {
            Alert(
                title: Text("Daily Limit Reached"),
                message: Text("You've used all your free reflections for today. Upgrade to premium for unlimited reflections."),
                primaryButton: .default(Text("Upgrade")) {
                    // Show subscription options
                },
                secondaryButton: .cancel(Text("Maybe Later"))
            )
        }
    }
    
    private var filteredMessages: [ChatMessage] {
        chatManager.currentChat.messages
    }
    
    // Simplified scrolling function
    private func scrollToBottom(proxy: ScrollViewProxy) {
        proxy.scrollTo("BottomAnchor")
    }

    private func sendMessage() {
        if isTyping {
            // Stop the assistant from typing
            isTyping = false
            return
        }
        
        guard !messageText.isEmpty else { return }
        
        // Check if user can send more messages
        if !appState.canUseReflections {
            showingSubscriptionPrompt = true
            return
        }
        
        // Dismiss keyboard when sending message
        isInputFocused = false
        
        // Add user message
        let userMessage = ChatMessage(text: messageText, isUser: true)
        let messageToSend = messageText
        messageText = "" // Clear input field immediately
        
        // Add message to chat manager
        chatManager.addMessage(userMessage)
        
        // Reset text editor height
        withAnimation(.easeInOut(duration: 0.1)) {
            textEditorHeight = 30
        }
        
        // Increment usage counter for free tier
        if appState.subscriptionTier == .free {
            appState.dailyReflectionsUsed += 1
        }
        
        // Simulate AI typing
        isTyping = true
        
        // Simulate AI response after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTyping = false
            
            // Generate a response based on the user's message
            let responseText = generateResponse(to: messageToSend)
            let aiMessage = ChatMessage(text: responseText, isUser: false)
            
            // Add AI message to chat manager
            chatManager.addMessage(aiMessage)
        }
    }
    
    private func generateResponse(to message: String) -> String {
        // In a real app, this would call an AI service
        // For now, we'll return a simple canned response
        
        if message.lowercased().contains("stress") || message.lowercased().contains("anxious") || message.lowercased().contains("worried") {
            return "It sounds like you're feeling stressed. Remember that it's okay to take breaks and practice self-care. Try some deep breathing exercises or a short walk to clear your mind. What specific situations are causing you stress right now?"
        } else if message.lowercased().contains("happy") || message.lowercased().contains("good") || message.lowercased().contains("great") {
            return "I'm glad to hear you're feeling positive! What's contributing to your good mood today? Recognizing these positive influences can help you cultivate more happiness in your life."
        } else if message.lowercased().contains("sad") || message.lowercased().contains("depressed") || message.lowercased().contains("down") {
            return "I'm sorry to hear you're feeling down. Remember that all emotions are temporary and it's okay to not be okay sometimes. Would it help to talk about what's causing these feelings? Or perhaps engaging in an activity you enjoy might lift your spirits."
        } else if message.lowercased().contains("goal") || message.lowercased().contains("achieve") || message.lowercased().contains("accomplish") {
            return "Setting goals is a great way to give yourself direction. What steps have you already taken toward this goal? Breaking it down into smaller, manageable tasks can make it feel less overwhelming."
        } else {
            return "Thank you for sharing that with me. Would you like to explore this topic further? Sometimes writing about our thoughts can help us gain clarity and perspective."
        }
    }
}

// Remove the onStar callback from ChatBubble since we're moving that functionality to chat level
struct ChatBubble: View {
  let message: ChatMessage
  let isExpanded: Bool
  let onTap: () -> Void
  @State private var isCopied: Bool = false
  @Environment(\.colorScheme) private var colorScheme
  
  // Access to shared styles
  private let styles = UIStyles.shared
  
  var body: some View {
      HStack {
          if message.isUser {
              Spacer()
              
              VStack(alignment: .trailing, spacing: 4) {
                  Text(message.text)
                      .font(styles.typography.bodyFont)
                      .foregroundColor(styles.colors.userBubbleText)
                      .padding(styles.layout.paddingM)
                      .background(styles.colors.userBubbleColor)
                      .clipShape(ChatBubbleShape(isUser: true))
                      .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                      .contentShape(Rectangle())
                      .padding(.vertical, 8)
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
          } else {
              VStack(alignment: .leading, spacing: 4) {
                  Text(message.text)
                      .font(styles.typography.bodyFont)
                      .foregroundColor(styles.colors.assistantBubbleText)
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
              
              Spacer()
          }
      }
  }
}

struct ChatBubbleShape: Shape {
    var isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isUser 
                ? [.topLeft, .topRight, .bottomLeft]
                : [.topLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: 12, height: 12)
        )
        return Path(path.cgPath)
    }
}

struct TypingIndicator: View {
    // Access to shared styles
    private let styles = UIStyles.shared
    
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: styles.layout.spacingS) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(styles.colors.offWhite)
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset(for: index))
                }
            }
            .padding(styles.layout.paddingM)
            .background(
                styles.colors.assistantBubbleColor
                    .clipShape(ChatBubbleShape(isUser: false))
            )
            
            Spacer()
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
                animationOffset = 5
            }
        }
    }
    
    private func animationOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.2
        return sin(animationOffset + CGFloat(delay)) * 5
    }
}

