import SwiftUI

struct SentimentAnalysisInsightCard: View {
    let entries: [JournalEntry]
    let subscriptionTier: SubscriptionTier
    @State private var isExpanded: Bool = false

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    // Simulated sentiment data for demonstration
    private let sentimentData = [
        ("Jan", 0.2),
        ("Feb", 0.4),
        ("Mar", 0.1),
        ("Apr", -0.3)
    ]

    private var averageSentiment: Double {
        let sum = sentimentData.reduce(0.0) { $0 + $1.1 }
        return sum / Double(sentimentData.count)
    }

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
                            Text("Sentiment Analysis")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)

                            Spacer()

                            Image(systemName: "waveform.path")
                                .foregroundColor(styles.colors.accent)
                                .font(.system(size: styles.layout.iconSizeL))
                        }

                        // Sentiment visualization
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(sentimentData, id: \.0) { data in
                                VStack(spacing: 8) {
                                    // Bar
                                    Rectangle()
                                        .fill(data.1 >= 0 ? Mood.happy.color : Mood.sad.color) // Use Mood enum color
                                        .frame(width: 24, height: abs(CGFloat(data.1) * 100))

                                    // Month label
                                    Text(data.0)
                                        .font(styles.typography.caption)
                                        .foregroundColor(styles.colors.textSecondary)
                                }
                            }
                        }
                        .frame(height: 120, alignment: .center)
                        .padding(.vertical, styles.layout.paddingS)

                        Text("Your overall sentiment is \(averageSentiment > 0 ? "positive" : "negative"). Tracking emotional tone in your entries can help identify patterns.")
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
                    type: .sentimentAnalysis,
                    title: "Sentiment Analysis",
                    data: entries
                ),
                entries: entries
            )
        }
    }
}