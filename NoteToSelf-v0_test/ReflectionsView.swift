import SwiftUI

struct ReflectionsView: View {
    @EnvironmentObject var appState: AppState
    @State private var messageText: String = ""
    @State private var isTyping: Bool = false
    @State private var showingSubscriptionPrompt: Bool = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Reflections")
                    .font(styles.typography.title1)
                    .foregroundColor(styles.colors.text)
                
                Spacer()
            }
            .padding(.horizontal, styles.layout.paddingXL)
            .padding(.top, styles.layout.topSafeAreaPadding)
            .padding(.bottom, styles.layout.paddingM)
            
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
                    }
                    .padding(.horizontal, styles.layout.paddingL)
                    .padding(.vertical, styles.layout.paddingL)
                }
                .onChange(of: appState.chatMessages.count) { newCount in
                    if let lastMessage = appState.chatMessages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isTyping) { newValue in
                    withAnimation {
                        scrollView.scrollTo(appState.chatMessages.last?.id, anchor: .bottom)
                    }
                }
            }
            
            // Message input
            VStack(spacing: 0) {
                Divider()
                    .background(styles.colors.divider)
                
                HStack(spacing: styles.layout.spacingM) {
                    ZStack(alignment: .leading) {
                        if messageText.isEmpty {
                            Text("Ask a question...")
                                .foregroundColor(styles.colors.placeholderText)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $messageText)
                            .padding(4)
                            .background(Color.clear)
                            .foregroundColor(styles.colors.text)
                            .frame(minHeight: 40, maxHeight: 120)
                            .colorScheme(.dark) // Force dark mode for the TextEditor
                    }
                    .padding(styles.layout.paddingS)
                    .background(styles.colors.appBackground) // Changed to match container color
                    .cornerRadius(styles.layout.radiusM)
                    .overlay(
                        RoundedRectangle(cornerRadius: styles.layout.radiusM)
                            .stroke(styles.colors.divider, lineWidth: 1)
                    )
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: styles.layout.iconSizeXL))
                            .foregroundColor(messageText.isEmpty ? styles.colors.textDisabled : styles.colors.accent)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(.horizontal, styles.layout.paddingL)
                .padding(.vertical, styles.layout.paddingM)
            }
            .background(styles.colors.appBackground)
        }
        .background(styles.colors.appBackground.ignoresSafeArea())
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
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Check if user can send more messages
        if !appState.canUseReflections {
            showingSubscriptionPrompt = true
            return
        }
        
        // Add user message
        let userMessage = ChatMessage(text: messageText, isUser: true)
        appState.chatMessages.append(userMessage)
        messageText = ""
        
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
            let responseText = generateResponse(to: userMessage.text)
            let aiMessage = ChatMessage(text: responseText, isUser: false)
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
                    .foregroundColor(message.isUser ? styles.colors.text : styles.colors.text)
                    .padding(styles.layout.paddingM)
                    .background(message.isUser ? styles.colors.accent.opacity(0.2) : styles.colors.chatAIBubble)
                    .cornerRadius(styles.layout.radiusL)
                
                if !message.isUser {
                    Button(action: {
                        showingSaveOption.toggle()
                    }) {
                        Text("Save to Journal")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.accent)
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
                                showingSaveOption = false
                            }) {
                                Text("Yes")
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.accent)
                            }
                            
                            Button(action: {
                                showingSaveOption = false
                            }) {
                                Text("No")
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.textSecondary)
                            }
                        }
                        .padding(.leading, styles.layout.paddingS)
                    }
                }
            }
            
            if !message.isUser {
                Spacer()
            }
        }
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
                        .fill(styles.colors.accent)
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset(for: index))
                }
            }
            .padding(styles.layout.paddingM)
            .background(styles.colors.chatAIBubble)
            .cornerRadius(styles.layout.radiusL)
            
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
        
        return ReflectionsView()
            .environmentObject(appState)
    }
}
