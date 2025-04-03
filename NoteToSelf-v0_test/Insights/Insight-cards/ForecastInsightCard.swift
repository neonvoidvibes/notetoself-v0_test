import SwiftUI

// New card for Predictive Mood & General Forecast
struct ForecastInsightCard: View {
    // Input: Requires a dedicated ForecastResult Codable struct (to be defined)
    // let forecastResult: ForecastResult? // Placeholder
    let subscriptionTier: SubscriptionTier

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    @ObservedObject private var styles = UIStyles.shared

    // Placeholder data for preview
    private var placeholderForecastLabel: String {
        // TODO: Replace with logic based on actual forecastResult
        "Mood: Upbeat; Reflection: On track"
    }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: Icon, Quick Prediction Label, Helping Text
                HStack(spacing: styles.layout.spacingM) {
                    // Futuristic Icon
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill") // Example icon
                        .font(.system(size: 40))
                        .foregroundColor(styles.colors.accent)

                    // Prediction Label & Helping Text
                    VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                         Text("Future Forecast") // Clearer title
                            .font(styles.typography.smallLabelFont)
                            .foregroundColor(styles.colors.textSecondary)

                        if subscriptionTier == .premium {
                            // Show placeholder label for now
                            Text(placeholderForecastLabel)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)
                                .lineLimit(1)

                            Text("Tap to see your personalized forecast and plan ahead.") // Helping text
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.accent)
                        } else {
                             Text("Unlock predictive insights with Premium.")
                                 .font(styles.typography.bodyFont)
                                 .foregroundColor(styles.colors.textSecondary)
                                 .lineLimit(2)
                        }
                    }
                    Spacer() // Push content left
                }
                 .padding(.vertical, styles.layout.paddingS) // Add vertical padding
            },
            detailContent: {
                // Expanded View: Use ForecastDetailContent
                if subscriptionTier == .premium {
                    // Pass forecastResult when available
                    ForecastDetailContent(/* forecastResult: forecastResult */)
                } else {
                     // Free tier expanded state
                     VStack(spacing: styles.layout.spacingL) {
                         Image(systemName: "lock.fill").font(.system(size: 40)).foregroundColor(styles.colors.accent)
                         Text("Upgrade for Forecasts").font(styles.typography.title3).foregroundColor(styles.colors.text)
                         Text("Unlock predictive mood and trend forecasts with Premium.")
                              .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary).multilineTextAlignment(.center)
                         Button { /* TODO: Trigger upgrade flow */ } label: {
                             Text("Upgrade Now").foregroundColor(styles.colors.primaryButtonText)
                         }.buttonStyle(GlowingButtonStyle())
                          .padding(.top)
                     }.padding()
                 }
            }
        )
    }
}

#Preview {
     ScrollView {
         ForecastInsightCard(subscriptionTier: .premium)
             .padding()
             .environmentObject(UIStyles.shared)
             .environmentObject(ThemeManager.shared)
     }
     .background(Color.gray.opacity(0.1))
}