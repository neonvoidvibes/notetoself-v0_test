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
            styles.card(
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
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(styles.colors.text)
                        
                        Text(streak == 1 ? "day" : "days")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                    }
                    
                    Text("Keep up the good work! Consistency is key to building a journaling habit.")
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, styles.layout.spacingS)
                }
                .padding(styles.layout.paddingL)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
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
}

