import SwiftUI

struct WeeklySummaryInsightCard: View {
    // Input: Raw JSON string, generation date, and subscription status
    let jsonString: String?
    let generatedDate: Date?
    let isFresh: Bool // Flag for highlighting
    let subscriptionTier: SubscriptionTier

    // Local state for decoded result
    @State private var decodedSummary: WeeklySummaryResult? = nil
    @State private var decodingError: Bool = false
    @State private var isHovering: Bool = false // Keep for button hover effects

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    // Computed properties based on the DECODED result
    private var summaryPeriod: String {
        let calendar = Calendar.current
        let endDate = generatedDate ?? Date()
        // Adjust to calculate the start of the week (Sunday) based on the end date
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: endDate)
        let startOfWeek = calendar.date(from: components)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d" // Keep format concise
        return "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endDate))"
    }

    // Placeholder message logic
    private var placeholderMessage: String {
        if jsonString == nil {
            return "Keep journaling this week to generate your first summary!"
        } else if decodedSummary == nil && !decodingError {
             return "Loading summary..."
        } else if decodingError {
            return "Could not load summary. Please try again later."
        } else {
            return "Weekly summary is not available yet."
        }
    }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            // Highlight only if premium AND fresh
            highlightColor: (isFresh && subscriptionTier == .premium) ? styles.colors.accent : nil,
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: Period, Key Themes Preview, NEW badge
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Weekly Summary")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)

                        if isFresh && subscriptionTier == .premium {
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(styles.colors.accentContrastText) // Contrast text
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(styles.colors.accent.opacity(0.9)) // Use accent directly
                                .clipShape(Capsule())
                                .shadow(color: styles.colors.accent.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        Spacer()
                        if subscriptionTier == .free {
                             Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                         }
                    }

                    if subscriptionTier == .premium {
                        Text(summaryPeriod) // Show period clearly
                            .font(styles.typography.bodyFont.weight(.semibold)) // Slightly bolder
                            .foregroundColor(styles.colors.accent) // Use accent color

                        // Key Themes Preview
                        if let themes = decodedSummary?.keyThemes, !themes.isEmpty {
                            HStack(spacing: styles.layout.spacingS) {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(styles.colors.textSecondary)
                                    .font(.caption)
                                Text(themes.prefix(2).joined(separator: ", ") + (themes.count > 2 ? "..." : ""))
                                    .font(styles.typography.bodySmall) // Main font for themes preview
                                    .foregroundColor(styles.colors.textSecondary)
                                    .lineLimit(1)
                            }
                        } else if jsonString != nil && decodedSummary == nil && !decodingError {
                           ProgressView().tint(styles.colors.accent).padding(.vertical, 4) // Show loading indicator briefly
                        } else if jsonString == nil || decodingError {
                             Text(placeholderMessage) // Show placeholder if no data/error
                                 .font(styles.typography.bodySmall)
                                 .foregroundColor(styles.colors.textSecondary)
                        } else {
                            Text("Key themes will appear here.") // Default text if themes are empty but summary exists
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.textSecondary)
                        }

                    } else {
                        // Free tier locked state
                        Text("Unlock weekly summaries and deeper insights with Premium.")
                            .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                            .multilineTextAlignment(.center)
                    }
                }
            },
            detailContent: {
                // Expanded View: Use WeeklySummaryDetailContent
                if subscriptionTier == .premium, let result = decodedSummary {
                    // Pass the result struct directly
                    WeeklySummaryDetailContentExpanded(summaryResult: result, summaryPeriod: summaryPeriod, generatedDate: generatedDate)
                } else if subscriptionTier == .free {
                    // Free tier expanded state (similar to Recommendations)
                    VStack(spacing: styles.layout.spacingL) {
                        Image(systemName: "lock.fill").font(.system(size: 40)).foregroundColor(styles.colors.accent)
                        Text("Upgrade for Details").font(styles.typography.title3).foregroundColor(styles.colors.text)
                        Text("Unlock detailed weekly summaries and insights with Premium.")
                             .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary).multilineTextAlignment(.center)
                        Button { /* TODO: Trigger upgrade flow */ } label: {
                             Text("Upgrade Now").foregroundColor(styles.colors.primaryButtonText)
                        }.buttonStyle(GlowingButtonStyle())
                         .padding(.top)
                    }.padding()
                } else {
                    // Premium, but no data
                     Text("Weekly summary details are not available yet.")
                         .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                         .frame(maxWidth: .infinity, alignment: .center).padding()
                }
            }
        )
        .onChange(of: jsonString) { oldValue, newValue in
            decodeJSON(json: newValue)
        }
        .onAppear {
            decodeJSON(json: jsonString)
        }
    }

    // Decoding function (remains the same)
    private func decodeJSON(json: String?) {
        guard let json = json, !json.isEmpty else {
            decodedSummary = nil; decodingError = false; return
        }
        decodingError = false
        guard let data = json.data(using: .utf8) else {
            print("⚠️ [WeeklySummaryCard] Failed convert JSON string to Data."); decodingError = true; decodedSummary = nil; return
        }
        do {
            let result = try JSONDecoder().decode(WeeklySummaryResult.self, from: data)
            if result != decodedSummary { decodedSummary = result; print("[WeeklySummaryCard] Decoded new summary.") }
        } catch {
            print("‼️ [WeeklySummaryCard] Failed decode WeeklySummaryResult: \(error). JSON: \(json)"); decodingError = true; decodedSummary = nil
        }
    }
}


// New Subview for Expanded Content to keep main struct cleaner
struct WeeklySummaryDetailContentExpanded: View {
    let summaryResult: WeeklySummaryResult
    let summaryPeriod: String
    let generatedDate: Date?
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingL) {
            // Header with Period
            HStack {
                Text("Weekly Summary")
                    .font(styles.typography.title1) // Larger title for expanded
                    .foregroundColor(styles.colors.text)
                Spacer()
                Text(summaryPeriod)
                    .font(styles.typography.caption)
                    .foregroundColor(styles.colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(styles.colors.accent.opacity(0.1).clipShape(Capsule()))
            }

            // Main Summary Text
            Text(summaryResult.mainSummary)
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.textSecondary)
                .padding(.bottom)

            // Key Themes Horizontal Scroll
            if !summaryResult.keyThemes.isEmpty {
                 VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                     Text("Key Themes")
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)
                     ScrollView(.horizontal, showsIndicators: false) {
                         HStack(spacing: 10) {
                             ForEach(summaryResult.keyThemes, id: \.self) { theme in
                                 Text(theme)
                                     .font(styles.typography.bodySmall)
                                     .padding(.horizontal, 12)
                                     .padding(.vertical, 8)
                                     .background(styles.colors.secondaryBackground)
                                     .cornerRadius(styles.layout.radiusM)
                                     .foregroundColor(styles.colors.text)
                             }
                         }
                     }
                 }.padding(.bottom)
            }

            // Mood Trend
            VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                Text("Mood Trend")
                    .font(styles.typography.title3)
                    .foregroundColor(styles.colors.text)
                Text(summaryResult.moodTrend)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
            }.padding(.bottom)


            // Notable Quote
            if !summaryResult.notableQuote.isEmpty {
                VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                     Text("Notable Quote")
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)
                     Text("\"\(summaryResult.notableQuote)\"")
                         .font(styles.typography.bodyFont.italic())
                         .foregroundColor(styles.colors.accent)
                         .padding()
                         .frame(maxWidth: .infinity, alignment: .leading)
                         .background(styles.colors.secondaryBackground.opacity(0.5))
                         .cornerRadius(styles.layout.radiusM)
                 }
            }

            // Generation Date
             if let date = generatedDate {
                 Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                     .font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                     .frame(maxWidth: .infinity, alignment: .center).padding(.top)
             }
        }
    }
}


#Preview {
    // Example Summary for Preview
    let previewSummary = WeeklySummaryResult(
        mainSummary: "This week involved focusing on work projects and finding time for relaxation during the weekend.",
        keyThemes: ["Work Stress", "Weekend Relaxation", "Project Deadline"],
        moodTrend: "Generally positive with a dip mid-week",
        notableQuote: "Felt a real sense of accomplishment today."
    )
    let encoder = JSONEncoder()
    let data = try? encoder.encode(previewSummary)
    let jsonString = String(data: data ?? Data(), encoding: .utf8)

    return ScrollView {
        VStack(spacing: 20) {
            WeeklySummaryInsightCard(jsonString: jsonString, generatedDate: Date(), isFresh: true, subscriptionTier: .premium)
            WeeklySummaryInsightCard(jsonString: jsonString, generatedDate: Date(), isFresh: false, subscriptionTier: .premium)
            WeeklySummaryInsightCard(jsonString: jsonString, generatedDate: Date(), isFresh: true, subscriptionTier: .free)
        }
        .padding()
        .environmentObject(UIStyles.shared)
        .environmentObject(ThemeManager.shared)
    }
     .background(Color.gray.opacity(0.1))

}