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
                HStack {
                    Text("Reflections")
                        .font(styles.typography.title1)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                    
                    // Clear conversation button - moved to left of settings
                    Button {
                        // Clear conversation logic
                        appState.chatMessages = []
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 24))
                            .foregroundColor(styles.colors.text)
                    }
                    .padding(.trailing, styles.layout.spacingL)
                }
                .padding(styles.headerPadding)
                
                // Chat messages
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: styles.layout.spacingM) {
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
                                    .foregroundColor(styles.colors.placeholderText)
                                    .padding(.leading, 4)
                            }
                            
                            TextEditor(text: isTyping ? .constant("") : $messageText)
                                .padding(4)
                                .background(Color.clear) // Transparent background
                                .foregroundColor(isTyping ? styles.colors.textDisabled : styles.colors.text)
                                .frame(height: styles.layout.inputAreaHeight)
                                .colorScheme(.dark)
                                .disabled(isTyping)
                                .scrollContentBackground(.hidden) // Hide the default background
                                .focused($isInputFocused) // Track focus state
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
                                    .font(.system(size: 26, weight: .bold))
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
}

struct ChatBubble: View {
    let message: ChatMessage
    @State private var showingSaveOption: Bool = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: styles.layout.spacingXS) {
                Text(message.text)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(message.isUser ? styles.colors.userBubbleText : styles.colors.assistantBubbleText)
                    .padding(styles.layout.paddingM)
                    .background(
                        message.isUser 
                        ? styles.colors.userBubbleColor
                        : styles.colors.assistantBubbleColor
                    )
                    .clipShape(ChatBubbleShape(isUser: message.isUser))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                if !message.isUser {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingSaveOption.toggle()
                        }
                    }) {
                        Text("Save to Journal")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.accent)
                            .underline()
                    }
                    .padding(.leading, styles.layout.paddingS)
                    .opacity(showingSaveOption ? 0 : 1)
                    
                    if showingSaveOption {
                        HStack {
                            Text("Save this reflection?")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                            
                            Button(action: {
                                // Save to journal logic would go here
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showingSaveOption = false
                                }
                            }) {
                                Text("Yes")
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(styles.colors.secondaryBackground)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showingSaveOption = false
                                }
                            }) {
                                Text("No")
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(styles.colors.secondaryBackground)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.leading, styles.layout.paddingS)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            if !message.isUser {
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

struct ReflectionsView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.loadSampleData()
        
        return ReflectionsView(
            tabBarOffset: .constant(0),
            lastScrollPosition: .constant(0),
            tabBarVisible: .constant(true)
        )
        .environmentObject(appState)
    }
}

