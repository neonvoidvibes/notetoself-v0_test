import SwiftUI

struct ThinkDetailContent: View {
    let result: ThinkInsightResult
    let generatedDate: Date?
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: styles.layout.spacingXL) {

                // --- Theme Overview Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Theme Overview")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)

                    Text(result.themeOverviewText ?? "Recurring themes will be identified here with more entries.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(styles.colors.secondaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)

                // --- Value Reflection Section ---
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    Text("Value Reflection")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text)

                    Text(result.valueReflectionText ?? "Alignment between values and actions will be analyzed here.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(styles.colors.secondaryBackground.opacity(0.5))
                .cornerRadius(styles.layout.radiusM)

                Spacer(minLength: styles.layout.spacingXL)

                // Generated Date Timestamp
                if let date = generatedDate {
                    HStack {
                        Spacer()
                        Image(systemName: "clock")
                            .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                            .font(.system(size: 12))
                        Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .padding(.bottom, styles.layout.paddingL)
        }
    }
}

#Preview {
    let mockResult = ThinkInsightResult(
        themeOverviewText: "Preview: The theme of managing project deadlines alongside personal well-being appears frequently. This suggests an ongoing balancing act is central to your current experience.",
        valueReflectionText: "Preview: You often mention wanting 'focused work', but descriptions of frequent context switching suggest a potential gap between intention and execution. Recognizing this is key."
    )

    return InsightFullScreenView(title: "Think Insights") {
        ThinkDetailContent(result: mockResult, generatedDate: Date())
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
}