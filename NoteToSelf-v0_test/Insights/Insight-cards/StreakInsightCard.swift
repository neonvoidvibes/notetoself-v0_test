import SwiftUI

struct StreakInsightCard: View {
    let streak: Int
    @State private var isExpanded: Bool = false
    @EnvironmentObject var appState: AppState
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        Button(action: {
            isExpanded = true
        }) {
            styles.enhancedCard(
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Current Streak")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                        
                        Image(systemName: "flame.fill")
                            .foregroundColor(styles.colors.accent)
                            .font(.system(size: styles.layout.iconSizeL))
                    }
                    
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
                .padding(styles.layout.cardInnerPadding),
                isPrimary: true
            )
            .transition(.scale.combined(with: .opacity))
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isExpanded) {
            InsightDetailView(
                insight: InsightDetail(
                    type: .streak,
                    title: "Streak Details",
                    data: streak
                ),
                entries: appState.journalEntries
            )
        }
    }

    // Add this computed property for more personalized streak messages
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

