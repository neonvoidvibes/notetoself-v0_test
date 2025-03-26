import SwiftUI

struct StreakInsightCard: View {
    let streak: Int
    @State private var isExpanded: Bool = false
    @EnvironmentObject var appState: AppState
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            isPrimary: true,
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    styles.cardHeader(title: "Current Streak", icon: "flame.fill")
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(streak)")
                            .font(styles.typography.insightValue)
                            .foregroundColor(styles.colors.text)
                        
                        Text(streak == 1 ? "day" : "days")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .padding(.leading, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    
                    // More conversational and personal text
                    Text(streakMessage)
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, styles.layout.spacingS)
                        .lineLimit(2)
                }
            },
            detailContent: {
                // Expanded detail content
                VStack(spacing: styles.layout.spacingL) {
                    Divider()
                        .background(styles.colors.tertiaryBackground)
                        .padding(.vertical, 8)
                    
                    // Streak history visualization
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Streak History")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { index in
                                let isActive = index < min(streak, 7)
                                Circle()
                                    .fill(isActive ? styles.colors.accent : styles.colors.tertiaryBackground)
                                    .frame(height: 12)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                isActive ? styles.colors.accent.opacity(0.3) : styles.colors.tertiaryBackground,
                                                lineWidth: 1
                                            )
                                    )
                            }
                            
                            if streak > 7 {
                                Text("+\(streak - 7)")
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(styles.colors.accent.opacity(0.1))
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Streak benefits
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Benefits of Consistent Journaling")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                            StreakBenefitRow(
                                icon: "brain.head.profile",
                                title: "Self-Awareness",
                                description: "Regular journaling helps you recognize patterns in your thoughts and behaviors."
                            )
                            
                            StreakBenefitRow(
                                icon: "heart.text.square",
                                title: "Emotional Processing",
                                description: "Writing helps process emotions and reduce stress by externalizing thoughts."
                            )
                            
                            StreakBenefitRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Progress Tracking",
                                description: "See your growth over time and celebrate small wins along the way."
                            )
                        }
                    }
                    
                    // Call to action
                    Button(action: {
                        // Navigate to journal entry screen
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SwitchToTab"),
                            object: nil,
                            userInfo: ["tabIndex": 0]
                        )
                    }) {
                        Text("Write Today's Entry")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                    .fill(styles.colors.accent)
                            )
                    }
                }
            }
        )
        .transition(.scale.combined(with: .opacity))
    }

    // Personalized streak messages
    private var streakMessage: String {
        if streak == 0 {
            return "Start your journaling habit today. Even a short entry makes a difference!"
        } else if streak == 1 {
            return "You've started your journey! Keep going to build momentum."
        } else if streak < 5 {
            return "You're building a great habit! Consistency is key to self-reflection."
        } else if streak < 10 {
            return "Impressive dedication! Your consistent journaling is helping you track patterns."
        } else {
            return "Amazing streak! Your commitment to self-reflection is truly remarkable."
        }
    }
}

// Helper view for streak benefits
struct StreakBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    private let styles = UIStyles.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: styles.layout.spacingM) {
            Image(systemName: icon)
                .foregroundColor(styles.colors.accent)
                .font(.system(size: 18))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(styles.typography.bodyLarge)
                    .foregroundColor(styles.colors.text)
                
                Text(description)
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

