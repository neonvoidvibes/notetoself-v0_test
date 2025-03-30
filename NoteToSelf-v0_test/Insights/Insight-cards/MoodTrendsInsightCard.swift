import SwiftUI
import Charts // Keep Charts import if needed for potential future visualization

struct MoodTrendsInsightCard: View {
    // Input: Stored insight result and generation date
    let trendResult: MoodTrendResult?
    let generatedDate: Date? // Keep track of when it was generated

    @State private var isExpanded: Bool = false
    private let styles = UIStyles.shared

    // Helper to get color based on mood name string
    private func moodColor(forName moodName: String?) -> Color {
        guard let name = moodName else { return styles.colors.textSecondary }
        // Attempt to find matching Mood enum case
        if let moodEnum = Mood.allCases.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return moodEnum.color
        }
        // Fallback for general terms
        switch name.lowercased() {
        case "positive", "improving": return styles.colors.moodHappy
        case "negative", "declining": return styles.colors.moodSad
        case "neutral", "stable", "mixed": return styles.colors.moodNeutral
        default: return styles.colors.textSecondary
        }
    }

    // Helper to get icon based on trend string
    private func trendIcon(forName trendName: String?) -> String {
         guard let name = trendName else { return "arrow.right.circle.fill" }
         switch name.lowercased() {
         case "improving": return "arrow.up.circle.fill"
         case "declining": return "arrow.down.circle.fill"
         case "stable": return "equal.circle.fill"
         case "fluctuating": return "arrow.up.arrow.down.circle.fill"
         default: return "arrow.right.circle.fill"
         }
     }


    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            content: {
                // Preview content based on stored trendResult
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Mood Analysis")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        Spacer()
                    }

                    if let result = trendResult {
                        HStack(spacing: styles.layout.spacingL) {
                            // Overall Trend Icon & Text
                            VStack(spacing: 8) {
                                Image(systemName: trendIcon(forName: result.overallTrend))
                                    .font(.system(size: 32))
                                    .foregroundColor(moodColor(forName: result.overallTrend)) // Color based on trend
                                Text(result.overallTrend)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.text)
                                Text("Overall Trend")
                                     .font(styles.typography.caption)
                                     .foregroundColor(styles.colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)

                            // Dominant Mood Icon & Text
                            VStack(spacing: 8) {
                                // Try to get specific mood icon, fallback to generic
                                let moodEnum = Mood.allCases.first { $0.name.lowercased() == result.dominantMood.lowercased() }
                                Image(systemName: moodEnum?.systemIconName ?? "questionmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(moodColor(forName: result.dominantMood))
                                Text(result.dominantMood)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.text)
                                 Text("Dominant Mood")
                                     .font(styles.typography.caption)
                                     .foregroundColor(styles.colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, styles.layout.spacingS)

                        // Analysis Text Preview
                        Text(result.analysis)
                            .font(styles.typography.bodySmall)
                            .foregroundColor(styles.colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, styles.layout.spacingS)
                            .lineLimit(2)

                    } else {
                        Text("Mood trend analysis is being generated or not available yet.")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .center) // Placeholder height
                    }
                }
            },
            detailContent: {
                // Expanded detail content
                if let result = trendResult {
                    VStack(spacing: styles.layout.spacingL) {
                        // Detailed Analysis
                        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                            Text("Detailed Analysis")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)

                            Text(result.analysis)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Mood Shifts
                        if !result.moodShifts.isEmpty {
                            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                Text("Notable Mood Shifts")
                                    .font(styles.typography.title3)
                                    .foregroundColor(styles.colors.text)

                                ForEach(result.moodShifts, id: \.self) { shift in
                                    HStack(alignment: .top, spacing: styles.layout.spacingS) {
                                        Image(systemName: "arrow.right.arrow.left.circle.fill")
                                            .foregroundColor(styles.colors.accent)
                                            .padding(.top, 2)
                                        Text(shift)
                                            .font(styles.typography.bodyFont)
                                            .foregroundColor(styles.colors.textSecondary)
                                    }
                                }
                            }
                        }

                         // Dominant Mood Info
                         VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                             Text("Dominant Mood: \(result.dominantMood)")
                                 .font(styles.typography.title3)
                                 .foregroundColor(styles.colors.text)

                             Text("Understanding your most frequent mood can highlight your baseline emotional state or recurring feelings.")
                                 .font(styles.typography.bodyFont)
                                 .foregroundColor(styles.colors.textSecondary)
                         }

                         // Overall Trend Info
                         VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                             Text("Overall Trend: \(result.overallTrend)")
                                 .font(styles.typography.title3)
                                 .foregroundColor(styles.colors.text)

                             Text("Tracking the general direction of your mood helps identify broader patterns over time.")
                                 .font(styles.typography.bodyFont)
                                 .foregroundColor(styles.colors.textSecondary)
                         }


                        // Generation Date
                        if let date = generatedDate {
                            Text("Generated on \(date.formatted(date: .long, time: .short))")
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top)
                        }
                    }
                } else {
                    Text("Mood trend details are not available.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        )
    }
}


// Helper view for mood stats (can be removed if not used)
/*
struct MoodStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    private let styles = UIStyles.shared

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(styles.typography.caption)
                .foregroundColor(styles.colors.textSecondary)

            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 24))

            Text(value)
                .font(styles.typography.bodyLarge)
                .foregroundColor(styles.colors.text)
        }
        .frame(maxWidth: .infinity)
    }
}
*/