import SwiftUI

struct StreakDetailContent: View {
    let streak: Int
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingL) {
            // Streak visualization
            HStack(spacing: styles.layout.spacingL) {
                ForEach(0..<min(streak, 7), id: \.self) { index in
                    VStack {
                        Circle()
                            .fill(styles.colors.accent)
                            .frame(width: 30, height: 30)
                        
                        Text("\(index + 1)")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.text)
                    }
                }
                
                if streak > 7 {
                    Text("+ \(streak - 7) more")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                }
            }
            .padding(.vertical, styles.layout.paddingL)
            
            // Streak stats
            VStack(spacing: styles.layout.spacingM) {
                Text("Your current streak is \(streak) days")
                    .font(styles.typography.bodyLarge)
                    .foregroundColor(styles.colors.text)
                    .multilineTextAlignment(.center)
                
                Text("You're building a great journaling habit! Consistency is key to self-reflection and personal growth.")
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Streak milestones
            VStack(spacing: styles.layout.spacingM) {
                Text("Streak Milestones")
                    .font(styles.typography.title3)
                    .foregroundColor(styles.colors.text)
                
                HStack(spacing: styles.layout.spacingL) {
                    StreakMilestone(days: 7, current: streak, icon: "star.fill")
                    StreakMilestone(days: 30, current: streak, icon: "star.fill")
                    StreakMilestone(days: 100, current: streak, icon: "star.fill")
                }
            }
            .padding(.vertical, styles.layout.paddingL)
        }
    }
}

struct StreakMilestone: View {
    let days: Int
    let current: Int
    let icon: String
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(styles.colors.accent.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)
                
                if current >= days {
                    Circle()
                        .fill(styles.colors.accent.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .foregroundColor(styles.colors.accent)
                        .font(.system(size: 24))
                }
            }
            
            Text("\(days) days")
                .font(styles.typography.caption)
                .foregroundColor(current >= days ? styles.colors.accent : styles.colors.textSecondary)
        }
    }
}

