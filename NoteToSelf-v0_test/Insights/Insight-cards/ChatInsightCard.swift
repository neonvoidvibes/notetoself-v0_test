import SwiftUI

struct ChatInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    @State private var isHovering: Bool = false
    @State private var animateGradient: Bool = false
    
    private let styles = UIStyles.shared

    // This would ideally come from an AI model analyzing journal entries
    // For now, we'll use a simple algorithm to generate an insight
    private var insightMessage: String {
        let calendar = Calendar.current
        let recentEntries = appState.journalEntries
            .filter { calendar.isDateInToday($0.date) || calendar.isDateInYesterday($0.date) }
    
        if let mostRecent = recentEntries.first {
            // Generate insight based on most recent entry
            let moodPhrase: String
            switch mostRecent.mood {
            case .happy, .excited, .content, .relaxed, .calm:
                moodPhrase = "I notice you've been feeling \(mostRecent.mood.name.lowercased()) lately. That's wonderful! What's contributing to this positive state?"
            case .sad, .depressed, .anxious, .stressed:
                moodPhrase = "I see you've been feeling \(mostRecent.mood.name.lowercased()). I'm here to listen if you'd like to explore what might be affecting you."
            case .angry:
                moodPhrase = "I notice you expressed some frustration recently. Sometimes talking through what triggered this can help provide clarity."
            case .bored:
                moodPhrase = "You mentioned feeling bored. Would exploring some new activities or perspectives help energize you?"
            default:
                moodPhrase = "I noticed your recent journal entry. Let's reflect on what's been on your mind."
            }
        
            return moodPhrase
        } else {
            // No recent entries
            return "How are you feeling today? Taking a moment to check in with yourself can provide valuable insights."
        }
    }
    
    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Preview content with enhanced styling
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("AI Reflection")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                            .shadow(color: styles.colors.accent.opacity(0.3), radius: 1, x: 0, y: 0)
                    
                        Spacer()
                        
                        // Animated AI indicator
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        styles.colors.accent,
                                        styles.colors.accent.opacity(0.7)
                                    ]),
                                    startPoint: animateGradient ? .leading : .trailing,
                                    endPoint: animateGradient ? .trailing : .leading
                                )
                            )
                            .frame(width: 8, height: 8)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                    animateGradient.toggle()
                                }
                            }
                    }
                    
                    // AI Assistant message with enhanced styling
                    HStack(alignment: .top, spacing: styles.layout.spacingM) {
                        // Assistant avatar with animated gradient
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            styles.colors.accent,
                                            styles.colors.accent.opacity(0.7)
                                        ]),
                                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .shadow(color: styles.colors.accent.opacity(0.3), radius: 3, x: 0, y: 2)
                        
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                                .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 0)
                        }
                    
                        // Message bubble with enhanced styling
                        Text(insightMessage)
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.text)
                            .padding(styles.layout.paddingM)
                            .background(
                                RoundedRectangle(cornerRadius: styles.layout.radiusL)
                                    .fill(styles.colors.secondaryBackground)
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: styles.layout.radiusL)
                                            .strokeBorder(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        styles.colors.accent.opacity(0.7),
                                                        styles.colors.accent.opacity(0.3)
                                                    ]),
                                                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                                                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(3)
                    }
                }
            },
            detailContent: {
                // Expanded detail content with enhanced styling
                VStack(spacing: styles.layout.spacingL) {
                    // Full message with enhanced styling
                    Text(insightMessage)
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.text)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                .fill(styles.colors.secondaryBackground.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            styles.colors.accent.opacity(0.3),
                                            styles.colors.accent.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                
                    // Reflection prompts with enhanced styling
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Reflection Questions")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                            .shadow(color: styles.colors.accent.opacity(0.3), radius: 1, x: 0, y: 0)
                    
                        ForEach(generateReflectionPrompts(), id: \.self) { prompt in
                            HStack(alignment: .top, spacing: 12) {
                                // Styled bullet point
                                ZStack {
                                    Circle()
                                        .fill(styles.colors.accent.opacity(0.2))
                                        .frame(width: 22, height: 22)
                                    
                                    Circle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 8, height: 8)
                                }
                                .padding(.top, 4)
                            
                                Text(prompt)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                    .fill(styles.colors.secondaryBackground.opacity(isHovering ? 0.5 : 0.0))
                                    .animation(.easeInOut(duration: 0.2), value: isHovering)
                            )
                            .onHover { hovering in
                                isHovering = hovering
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: styles.layout.radiusM)
                            .fill(styles.colors.secondaryBackground.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: styles.layout.radiusM)
                            .strokeBorder(styles.colors.tertiaryBackground, lineWidth: 1)
                    )
                
                    // Call-to-action button with enhanced styling
                    Button(action: {
                        // Switch to the Reflections tab
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SwitchToTab"),
                            object: nil,
                            userInfo: ["tabIndex": 2]
                        )
                    }) {
                        HStack {
                            Text("Continue This Conversation")
                                .font(styles.typography.bodyFont.weight(.medium))
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    styles.colors.accent,
                                    styles.colors.accent.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: styles.layout.radiusM))
                        .shadow(color: styles.colors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .white.opacity(0.3),
                                            .clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    }
                    .scaleEffect(isHovering ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
                    .onHover { hovering in
                        isHovering = hovering
                    }
                }
            }
        )
    }
    
    // Helper method to generate reflection prompts based on recent entries
    private func generateReflectionPrompts() -> [String] {
        let calendar = Calendar.current
        let recentEntries = appState.journalEntries
            .filter { calendar.isDateInToday($0.date) || calendar.isDateInYesterday($0.date) }
        
        if let mostRecent = recentEntries.first {
            // Generate prompts based on most recent entry mood
            switch mostRecent.mood {
            case .happy, .excited, .content, .relaxed, .calm:
                return [
                    "What specific events or factors contributed to your positive mood?",
                    "How might you intentionally create more moments like this in the future?",
                    "What strengths or resources are you drawing on during this positive period?"
                ]
            case .sad, .depressed:
                return [
                    "What thoughts or situations might be contributing to these feelings?",
                    "What has helped you navigate similar feelings in the past?",
                    "What small step could you take today to support your well-being?"
                ]
            case .anxious, .stressed:
                return [
                    "What specific concerns or uncertainties are you facing right now?",
                    "What aspects of the situation are within your control, and which aren't?",
                    "What coping strategies have been effective for you in the past?"
                ]
            case .angry:
                return [
                    "What underlying needs or values might this frustration be pointing to?",
                    "How might you address this situation in a way that aligns with your values?",
                    "What perspective might help you view this situation differently?"
                ]
            case .bored:
                return [
                    "What activities have engaged you deeply in the past?",
                    "What new skill or interest have you been curious about exploring?",
                    "How might this feeling of boredom be guiding you toward something important?"
                ]
            default:
                return [
                    "What patterns have you noticed in your thoughts or feelings lately?",
                    "What would be most supportive for you right now?",
                    "What insights from past experiences might be relevant to your current situation?"
                ]
            }
        } else {
            // General prompts if no recent entries
            return [
                "What's been on your mind lately that might be worth exploring?",
                "What patterns have you noticed in your mood or energy levels?",
                "What would you like to focus on or prioritize in the coming days?"
            ]
        }
    }
}

