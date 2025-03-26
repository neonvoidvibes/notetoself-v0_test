import SwiftUI

struct RecommendationsDetailContent: View {
    let recommendations: [Recommendation]
    private let styles = UIStyles.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: styles.layout.spacingXL) {
                // Introduction
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Personalized Recommendations")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    Text("Based on your journal entries, we've created these personalized recommendations to help support your well-being. These suggestions are grounded in behavioral science and positive psychology principles.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                }
                
                // Recommendations
                VStack(spacing: styles.layout.spacingL) {
                    ForEach(recommendations) { recommendation in
                        RecommendationDetailCard(recommendation: recommendation)
                    }
                }
                
                // Additional resources
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Additional Resources")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)
                    
                    ResourceLink(
                        title: "Mindfulness Practices",
                        description: "Simple mindfulness exercises to reduce stress and increase present-moment awareness.",
                        icon: "brain.head.profile"
                    )
                    
                    ResourceLink(
                        title: "Sleep Hygiene Guide",
                        description: "Evidence-based tips for improving your sleep quality and duration.",
                        icon: "bed.double.fill"
                    )
                    
                    ResourceLink(
                        title: "Mood-Boosting Activities",
                        description: "A curated list of activities scientifically shown to improve mood and well-being.",
                        icon: "heart.fill"
                    )
                }
            }
            .padding(styles.layout.paddingXL)
        }
    }
}

struct RecommendationDetailCard: View {
    let recommendation: Recommendation
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            // Header
            HStack(spacing: styles.layout.spacingM) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    styles.colors.accent,
                                    styles.colors.accent.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: recommendation.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }
                
                Text(recommendation.title)
                    .font(styles.typography.title3)
                    .foregroundColor(styles.colors.text)
            }
            
            // Description
            Text(recommendation.description)
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Why it works
            VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                Text("Why It Works")
                    .font(styles.typography.bodyLarge)
                    .foregroundColor(styles.colors.text)
                
                Text(generateWhyItWorks(for: recommendation))
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
            }
            .padding(.top, styles.layout.spacingS)
            
            // How to implement
            VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                Text("How to Implement")
                    .font(styles.typography.bodyLarge)
                    .foregroundColor(styles.colors.text)
                
                VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                    ForEach(generateImplementationSteps(for: recommendation), id: \.self) { step in
                        HStack(alignment: .top, spacing: styles.layout.spacingS) {
                            Text("•")
                                .foregroundColor(styles.colors.accent)
                            
                            Text(step)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                        }
                    }
                }
            }
            .padding(.top, styles.layout.spacingS)
        }
        .padding(styles.layout.paddingL)
        .background(
            RoundedRectangle(cornerRadius: styles.layout.radiusL)
                .fill(styles.colors.secondaryBackground)
        )
    }
    
    private func generateWhyItWorks(for recommendation: Recommendation) -> String {
        // In a real app, this would be part of the recommendation data
        // For now, we'll generate based on the title
        
        if recommendation.title.contains("Mood") {
            return "Research shows that intentional activities designed to boost mood can have a significant impact on overall well-being. These activities help activate the brain's reward centers and release neurotransmitters like dopamine and serotonin."
        } else if recommendation.title.contains("Stress") {
            return "Controlled breathing techniques help activate your parasympathetic nervous system, which counteracts the stress response. This reduces cortisol levels and helps your body return to a state of calm."
        } else if recommendation.title.contains("Social") {
            return "Humans are inherently social creatures. Positive social connections are consistently linked to better mental health, increased longevity, and greater resilience to stress."
        } else if recommendation.title.contains("Consistency") {
            return "Habit formation research shows that consistency is key to establishing new behaviors. Regular journaling creates neural pathways that make the practice increasingly automatic over time."
        } else if recommendation.title.contains("Emotion") {
            return "Taking a pause before reacting gives your prefrontal cortex (responsible for rational thinking) time to engage before your amygdala (emotional center) takes over, leading to more measured responses."
        } else if recommendation.title.contains("Engagement") {
            return "Novel and challenging activities increase dopamine production and create a state of 'flow' where you're fully engaged, which is strongly associated with increased happiness and satisfaction."
        } else if recommendation.title.contains("Well-being") {
            return "Gratitude practices have been extensively studied and shown to increase positive emotions, reduce depression, improve sleep quality, and enhance overall life satisfaction."
        } else {
            return "This recommendation is based on established principles from positive psychology and behavioral science research, designed to support your specific patterns and needs."
        }
    }
    
    private func generateImplementationSteps(for recommendation: Recommendation) -> [String] {
        // In a real app, this would be part of the recommendation data
        // For now, we'll generate based on the title
        
        if recommendation.title.contains("Mood") {
            return [
                "Set aside 10-15 minutes each day for a mood-boosting activity",
                "Choose activities that you genuinely enjoy, not what you think you should enjoy",
                "Track how different activities affect your mood to identify what works best for you",
                "Try to incorporate at least one mood-boosting activity on days you typically feel lower"
            ]
        } else if recommendation.title.contains("Stress") {
            return [
                "Practice the breathing technique for 2-3 minutes, 3 times daily",
                "Set reminders on your phone to ensure consistency",
                "Use the technique whenever you notice stress symptoms arising",
                "Gradually increase duration as you become more comfortable with the practice"
            ]
        } else if recommendation.title.contains("Social") {
            return [
                "Identify one person you feel supported by and reach out this week",
                "Schedule the interaction in advance so it doesn't get postponed",
                "Be present during the conversation, putting away distractions",
                "Reflect afterward on how the connection affected your mood"
            ]
        } else if recommendation.title.contains("Consistency") {
            return [
                "Set a specific time each day for journaling",
                "Start with just 5 minutes to make the habit more achievable",
                "Place visual reminders in your environment",
                "Track your consistency and celebrate small wins"
            ]
        } else if recommendation.title.contains("Emotion") {
            return [
                "Practice recognizing your emotional triggers",
                "When triggered, pause and take three deep breaths",
                "Ask yourself: 'What am I feeling right now?'",
                "Consider your options before responding"
            ]
        } else if recommendation.title.contains("Engagement") {
            return [
                "Make a list of activities you've enjoyed in the past",
                "Choose one activity to try this week",
                "Schedule a specific time for this activity",
                "Afterward, reflect on how it affected your mood and energy"
            ]
        } else if recommendation.title.contains("Well-being") {
            return [
                "Keep a small notebook by your bed",
                "Each night, write down three specific things you're grateful for",
                "Include why each thing matters to you",
                "Review your gratitude entries weekly to notice patterns"
            ]
        } else {
            return [
                "Start small with a manageable version of this recommendation",
                "Schedule specific times to implement this practice",
                "Track your progress and how it affects your mood",
                "Adjust as needed based on what works best for you"
            ]
        }
    }
}

struct ResourceLink: View {
    let title: String
    let description: String
    let icon: String
    private let styles = UIStyles.shared
    
    var body: some View {
        Button(action: {
            // In a real app, this would open the resource
        }) {
            HStack(alignment: .top, spacing: styles.layout.spacingM) {
                // Icon
                Image(systemName: icon)
                    .foregroundColor(styles.colors.accent)
                    .font(.system(size: 20))
                    .frame(width: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(styles.typography.bodyLarge)
                        .foregroundColor(styles.colors.text)
                    
                    Text(description)
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(styles.colors.accent)
                    .font(.system(size: 14))
            }
            .padding(styles.layout.paddingM)
            .background(
                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                    .fill(styles.colors.tertiaryBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

