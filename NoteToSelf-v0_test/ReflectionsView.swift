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
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background - using standard black background for the view itself
            styles.colors.appBackground.ignoresSafeArea()
            
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
                    
                    // Menu button on left and clear button on right
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
                        
                        // Clear conversation button on right
                        Button {
                            // Clear conversation logic
                            appState.chatMessages = []
                        } label: {
                            Image(systemName: "clock.arrow.trianglepath")
                                .font(.system(size: 24))
                                .foregroundColor(styles.colors.text)
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
                            ForEach(appState.chatMessages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
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
                    .onChange(of: appState.chatMessages.count) { _, _ in
                        scrollToBottom(proxy: scrollView)
                    }
                    .onChange(of: isTyping) { _, _ in
                        scrollToBottom(proxy: scrollView)
                    }
                    .onAppear {
                        scrollToBottom(proxy: scrollView)
                    }
                    // Tap gesture to dismiss keyboard
                    .onTapGesture {
                        isInputFocused = false
                    }
                }
                
                // Message input container - only shown when bottom sheet is closed
                if !bottomSheetExpanded {
                    HStack(spacing: styles.layout.spacingM) {
                        ZStack(alignment: .leading) {
                            if messageText.isEmpty && !isTyping {
                                Text("Ask a question...")
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.placeholderText)
                                    .padding(.leading, 4)
                            }
                            
                            TextEditor(text: isTyping ? .constant("") : $messageText)
                                .padding(4)
                                .background(Color.clear) // Transparent background
                                .foregroundColor(isTyping ? styles.colors.textDisabled : styles.colors.text)
                                .frame(height: min(60, max(40, textEditorHeight(text: messageText))))
                                .colorScheme(.dark)
                                .disabled(isTyping)
                                .scrollContentBackground(.hidden) // Hide the default background
                                .focused($isInputFocused) // Track focus state
                                .onChange(of: messageText) { _, _ in
                                    // Force layout update when text changes
                                    withAnimation(.easeInOut(duration: 0.1)) {}
                                }
                        }
                        .padding(styles.layout.paddingS)
                        .background(styles.colors.reflectionsNavBackground) // Use the same gray as outer container
                        
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
                    .background(
                        styles.colors.reflectionsNavBackground
                            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight])) // Top rounded corners only
                    )
                }
            }
        }
        // Tap gesture to dismiss keyboard when tapping anywhere in the view
        .onTapGesture {
            isInputFocused = false
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
        
        // Add message without animation
        appState.chatMessages.append(userMessage)
        
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
            
            // Add message without animation
            appState.chatMessages.append(aiMessage)
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

    private func textEditorHeight(text: String) -> CGFloat {
        let lineHeight: CGFloat = 20 // Approximate line height
        let maxLines: Int = 2
        
        // Count newlines and estimate height
        let lines = text.components(separatedBy: "\n").count
        let estimatedLines = min(maxLines, max(1, lines))
        
        return CGFloat(estimatedLines) * lineHeight
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    @State private var showingOptions: Bool = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                Text(message.text)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.userBubbleText)
                    .padding(styles.layout.paddingM)
                    .background(styles.colors.userBubbleColor)
                    .clipShape(ChatBubbleShape(isUser: true))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(message.text)
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.assistantBubbleText)
                        .padding(.vertical, styles.layout.paddingM)
                        .background(styles.colors.assistantBubbleColor)
                        .clipShape(ChatBubbleShape(isUser: false))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showingOptions.toggle()
                            }
                        }
                    
                    if showingOptions {
                        HStack(spacing: styles.layout.spacingM) {
                            Text("Save to Journal")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.accent)
                            
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(styles.colors.accent)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .padding(.leading, styles.layout.paddingM)
                        .transition(.opacity.combined(with: .move(edge: .top)))
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

