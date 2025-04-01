import SwiftUI

struct TopicAnalysisInsightCard: View {
    let entries: [JournalEntry]
    let subscriptionTier: SubscriptionTier
    @State private var isExpanded: Bool = false

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    // Simulated topics for demonstration
    private let topics = [
        ("Work", 42),
        ("Relationships", 35),
        ("Health", 28),
        ("Hobbies", 22)
    ]
    
    var body: some View {
        Button(action: {
            if subscriptionTier == .premium {
                isExpanded = true
            }
        }) {
            styles.card(
                ZStack {
                    VStack(spacing: styles.layout.spacingM) {
                        HStack {
                            Text("Topic Analysis")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)
                            
                            Spacer()
                            
                            Image(systemName: "text.magnifyingglass")
                                .foregroundColor(styles.colors.accent)
                                .font(.system(size: styles.layout.iconSizeL))
                        }
                        
                        // Topic list
                        VStack(spacing: styles.layout.spacingS) {
                            ForEach(topics, id: \.0) { topic in
                                HStack {
                                    Text(topic.0)
                                        .font(styles.typography.bodyFont)
                                        .foregroundColor(styles.colors.text)
                                    
                                    Spacer()
                                    
                                    Text("\(topic.1) mentions")
                                        .font(styles.typography.caption)
                                        .foregroundColor(styles.colors.textSecondary)
                                }
                            }
                        }
                        
                        Text("Discover the topics you write about most frequently to gain insights into what matters to you.")
                            .font(styles.typography.bodySmall)
                            .foregroundColor(styles.colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, styles.layout.spacingS)
                    }
                    .padding(styles.layout.paddingL)
                    .blur(radius: subscriptionTier == .premium ? 0 : 3)
                    
                    if subscriptionTier != .premium {
                        VStack(spacing: styles.layout.spacingM) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32))
                                .foregroundColor(styles.colors.accent)
                            
                            Text("Premium Feature")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)
                            
                            Button("Upgrade") {
                                // Show subscription options
                            }
                            .buttonStyle(UIStyles.PrimaryButtonStyle()) // No arguments needed
                            .frame(width: 150)
                        }
                        .padding(styles.layout.paddingL)
                        .background(
                            RoundedRectangle(cornerRadius: styles.layout.radiusL)
                                .fill(styles.colors.menuBackground.opacity(0.9)) // Use menuBackground instead of surface
                                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                    }
                }
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isExpanded) {
            InsightDetailView(
                insight: InsightDetail(
                    type: .topicAnalysis,
                    title: "Topic Analysis",
                    data: entries
                ),
                entries: entries
            )
        }
    }
}
