import SwiftUI

struct RecommendationsInsightCard: View {
    let entries: [JournalEntry]
    @State private var isExpanded: Bool = false
    private let styles = UIStyles.shared
    
    private var subscriptionTier: SubscriptionTier {
        // Access app state to get subscription tier
        // For now, we'll assume it's available via environment object
        return .premium // Default to premium for demo
    }
    
    // Generate recommendations based on journal entries
    private var recommendations: [Recommendation] {
        var results: [Recommendation] = []
        
        // Check for mood patterns
        let moodCounts = entries.reduce(into: [Mood: Int]()) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
        
        let dominantMood = moodCounts.max(by: { $0.value < $1.value })?.key
        
        // Add mood-based recommendations
        if let mood = dominantMood {
            switch mood {
            case .sad, .depressed:
                results.append(Recommendation(
                    title: "Mood Elevation",
                    description: "Try a 10-minute walk outside each morning to boost your mood with natural light and movement.",
                    icon: "sun.max.fill"
                ))
                results.append(Recommendation(
                    title: "Social Connection",
                    description: "Schedule a brief call with a friend or family member who makes you feel supported.",
                    icon: "person.2.fill"
                ))
            case .anxious, .stressed:
                results.append(Recommendation(
                    title: "Stress Reduction",
                    description: "Practice the 4-7-8 breathing technique: inhale for 4 seconds, hold for 7, exhale for 8.",
                    icon: "wind"
                ))
                results.append(Recommendation(
                    title: "Worry Management",
                    description: "Set aside a specific 15-minute 'worry time' each day to contain anxious thoughts.",
                    icon: "clock.fill"
                ))
            case .angry:
                results.append(Recommendation(
                    title: "Emotion Regulation",
                    description: "When feeling angry, try counting to 10 before responding to give your rational mind time to engage.",
                    icon: "number.circle.fill"
                ))
            case .bored:
                results.append(Recommendation(
                    title: "Engagement",
                    description: "Create a list of activities that have brought you joy in the past and choose one to try today.",
                    icon: "list.bullet.rectangle.fill"
                ))
            default:
                results.append(Recommendation(
                    title: "Habit Building",
                    description: "Continue your journaling practice at the same time each day to strengthen this positive habit.",
                    icon: "calendar.badge.clock"
                ))
            }
        }
        
        // Check for writing consistency
        let calendar = Calendar.current
        let today = Date()
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let recentEntries = entries.filter { $0.date >= oneWeekAgo }
        
        if recentEntries.count < 3 {
            results.append(Recommendation(
                title: "Consistency",
                description: "Set a daily reminder to journal for just 5 minutes to build a consistent practice.",
                icon: "bell.fill"
            ))
        }
        
        // Add general well-being recommendation
        results.append(Recommendation(
            title: "Well-being Practice",
            description: "End each day by writing down three things you're grateful for, no matter how small.",
            icon: "heart.fill"
        ))
        
        return results
    }
    
    // Update the RecommendationsInsightCard to use the enhanced card style and improved content
    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            content: {
                // Preview content
                ZStack {
                    VStack(spacing: styles.layout.spacingM) {
                        HStack {
                            Text("Recommendations")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)
                            
                            Spacer()
                        }
                        
                        // Show one recommendation for free users, more for premium
                        if let firstRec = recommendations.first {
                            RecommendationRow(recommendation: firstRec)
                        }
                        
                        if subscriptionTier == .premium && recommendations.count > 1 {
                            Divider()
                                .background(styles.colors.tertiaryBackground)
                                .padding(.vertical, 4)
                            
                            RecommendationRow(recommendation: recommendations[1])
                        }
                    }
                    
                    // Blur overlay for free users
                    if subscriptionTier == .free && recommendations.count > 1 {
                        VStack {
                            Spacer()
                            
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        styles.colors.surface.opacity(0),
                                        styles.colors.surface.opacity(0.8)
                                    ]
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 80)
                        }
                        .allowsHitTesting(false)
                    }
                }
            },
            detailContent: {
                // Expanded detail content
                VStack(spacing: styles.layout.spacingL) {
                    // Introduction
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Personalized Recommendations")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Text("Based on your journal entries, here are some suggestions that might support your well-being and personal growth.")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // All recommendations
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        ForEach(recommendations) { recommendation in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: recommendation.icon)
                                        .foregroundColor(styles.colors.accent)
                                        .font(.system(size: 20))
                                        .frame(width: 24, height: 24)
                                    
                                    Text(recommendation.title)
                                        .font(styles.typography.bodyLarge)
                                        .foregroundColor(styles.colors.text)
                                }
                                
                                Text(recommendation.description)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.leading, 32)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(styles.colors.tertiaryBackground.opacity(0.3))
                            .cornerRadius(styles.layout.radiusM)
                        }
                    }
                    
                    // Disclaimer
                    Text("These recommendations are generated based on patterns in your journal entries and are not a substitute for professional advice.")
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
        )
    }
}

struct Recommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
}

// Update the RecommendationRow to be more visually appealing
struct RecommendationRow: View {
    let recommendation: Recommendation
    private let styles = UIStyles.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: styles.layout.spacingM) {
            // Icon
            ZStack {
                Circle()
                    .fill(styles.colors.tertiaryBackground)
                    .frame(width: 40, height: 40)
                
                Image(systemName: recommendation.icon)
                    .foregroundColor(styles.colors.accent)
                    .font(.system(size: 18))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(styles.typography.insightCaption)
                    .foregroundColor(styles.colors.text)
                
                Text(recommendation.description)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
        }
    }
}

