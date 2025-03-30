import SwiftUI

struct WeeklySummaryInsightCard: View {
    // Input: Stored insight result and generation date
    let summaryResult: WeeklySummaryResult?
    let generatedDate: Date?
    let isFresh: Bool // Determined by InsightsView

    @State private var isExpanded: Bool = false
    private let styles = UIStyles.shared

    // Computed properties based on the stored result
    private var summaryPeriod: String {
        // Calculate based on generatedDate or fallback
        let calendar = Calendar.current
        let endDate = generatedDate ?? Date() // Use generation date as end date
        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)! // Assume 7-day period ending on generation date

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
    }

    private var dominantMood: String? {
        guard let result = summaryResult, !result.moodTrend.isEmpty, result.moodTrend != "N/A" else { return nil }
        // Extract mood name if possible (e.g., from "Predominantly Happy")
        let trendLower = result.moodTrend.lowercased()
        if let range = trendLower.range(of: "predominantly ") {
            return String(trendLower[range.upperBound...]).capitalized
        }
        // Fallback or if trend is just "Improving", "Stable" etc.
        return result.moodTrend.contains("positive") || result.moodTrend.contains("Improving") ? "Positive" :
               result.moodTrend.contains("negative") || result.moodTrend.contains("Declining") ? "Negative" :
               result.moodTrend == "Stable" ? "Stable" : nil
    }

     // Helper to get a color for the dominant mood string
     private func moodColor(forName moodName: String?) -> Color {
         guard let name = moodName else { return styles.colors.textSecondary }
         // Simple mapping based on expected names
         switch name.lowercased() {
         case "happy", "excited", "content", "relaxed", "calm", "positive", "improving": return styles.colors.moodHappy
         case "sad", "depressed", "anxious", "stressed", "angry", "negative", "declining": return styles.colors.moodSad
         case "neutral", "stable", "mixed": return styles.colors.moodNeutral
         default: return styles.colors.textSecondary
         }
     }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            isPrimary: isFresh, // Highlight if fresh
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    // Header with badge for fresh summaries
                    HStack {
                        Text("Weekly Summary")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)

                        if isFresh {
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(styles.colors.accent)
                                .cornerRadius(4)
                        }

                        Spacer()
                    }

                    // Period
                    Text(summaryPeriod)
                        .font(styles.typography.insightCaption)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Display summary if available, otherwise show placeholder
                    if let result = summaryResult {
                        // Summary text
                        Text(result.mainSummary)
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(3) // Limit lines in preview

                        // Key themes preview
                        if !result.keyThemes.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(result.keyThemes.prefix(3), id: \.self) { theme in
                                    Text(theme)
                                        .font(styles.typography.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(styles.colors.tertiaryBackground)
                                        .cornerRadius(styles.layout.radiusM)
                                        .foregroundColor(styles.colors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.top, 4)
                        }

                    } else {
                        Text("Weekly summary is being generated or not available yet.")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading) // Placeholder height
                    }
                }
            },
            detailContent: {
                // Expanded detail content
                if let result = summaryResult {
                    VStack(spacing: styles.layout.spacingL) {
                        // Detailed summary text
                        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                            Text("Summary")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)

                            Text(result.mainSummary)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Key Themes
                        if !result.keyThemes.isEmpty {
                            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                Text("Key Themes")
                                    .font(styles.typography.title3)
                                    .foregroundColor(styles.colors.text)

                                FlowLayout(spacing: 10) {
                                     ForEach(result.keyThemes, id: \.self) { theme in
                                         Text(theme)
                                             .font(styles.typography.bodySmall)
                                             .padding(.horizontal, 10)
                                             .padding(.vertical, 6)
                                             .background(styles.colors.secondaryBackground)
                                             .cornerRadius(styles.layout.radiusM)
                                             .foregroundColor(styles.colors.text)
                                     }
                                }
                            }
                        }

                        // Mood Trend
                        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                            Text("Mood Trend")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)

                            HStack {
                                 // Simple indicator based on mood string
                                 let moodColor = moodColor(forName: dominantMood)
                                 Circle().fill(moodColor).frame(width: 12, height: 12)

                                Text(result.moodTrend)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                            }
                        }

                        // Notable Quote
                        if !result.notableQuote.isEmpty {
                             VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                 Text("Notable Quote")
                                     .font(styles.typography.title3)
                                     .foregroundColor(styles.colors.text)

                                 Text("\"\(result.notableQuote)\"")
                                     .font(styles.typography.bodyFont.italic())
                                     .foregroundColor(styles.colors.accent)
                             }
                        }

                        // Generation Date
                        if let date = generatedDate {
                            Text("Generated on \(date.formatted(date: .long, time: .shortened))") // Corrected: .shortened
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top)
                        }
                    }
                } else {
                    // Fallback if result is nil even when expanded (shouldn't happen ideally)
                    Text("Weekly summary details are not available.")
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        )
    }
}