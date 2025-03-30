import SwiftUI
import Charts // Keep Charts import if needed for potential future visualization

struct MoodTrendsInsightCard: View {
    // Input: Raw JSON string, generation date, and subscription status
    let jsonString: String?
    let generatedDate: Date?
    let subscriptionTier: SubscriptionTier

    // Local state for decoded result
    @State private var decodedTrend: MoodTrendResult? = nil
    @State private var decodingError: Bool = false

    @State private var isExpanded: Bool = false
    private let styles = UIStyles.shared

    private func moodColor(forName moodName: String?) -> Color {
        guard let name = moodName else { return styles.colors.textSecondary }
        if let moodEnum = Mood.allCases.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return moodEnum.color
        }
        switch name.lowercased() {
        case "positive", "improving": return styles.colors.moodHappy
        case "negative", "declining": return styles.colors.moodSad
        case "neutral", "stable", "mixed": return styles.colors.moodNeutral
        default: return styles.colors.textSecondary
        }
    }

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

     private var placeholderMessage: String {
         if jsonString == nil {
             return "Keep journaling regularly (at least 3 entries needed) to analyze your mood trends!"
         } else if decodedTrend == nil && !decodingError {
             return "Loading mood analysis..."
         } else if decodingError {
             return "Could not load mood analysis. Please try again later."
         } else {
             return "Mood trend analysis is not available yet."
         }
     }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            content: {
                // Preview content based on decodedTrend
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Mood Analysis")
                            .font(styles.typography.title3).foregroundColor(styles.colors.text)
                        Spacer()
                        if subscriptionTier == .free {
                             Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                        }
                    }

                    if subscriptionTier == .premium {
                        // Use decodedTrend for display
                        if let result = decodedTrend {
                            HStack(spacing: styles.layout.spacingL) {
                                // Overall Trend
                                VStack(spacing: 8) {
                                    Image(systemName: trendIcon(forName: result.overallTrend))
                                        .font(.system(size: 32)).foregroundColor(moodColor(forName: result.overallTrend))
                                    Text(result.overallTrend).font(styles.typography.bodyFont).foregroundColor(styles.colors.text)
                                    Text("Overall Trend").font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                                }.frame(maxWidth: .infinity)
                                // Dominant Mood
                                VStack(spacing: 8) {
                                    let moodEnum = Mood.allCases.first { $0.name.lowercased() == result.dominantMood.lowercased() }
                                    Image(systemName: moodEnum?.systemIconName ?? "questionmark.circle.fill")
                                        .font(.system(size: 32)).foregroundColor(moodColor(forName: result.dominantMood))
                                    Text(result.dominantMood).font(styles.typography.bodyFont).foregroundColor(styles.colors.text)
                                    Text("Dominant Mood").font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                                }.frame(maxWidth: .infinity)
                            }.padding(.vertical, styles.layout.spacingS)

                            // Analysis Text Preview
                            Text(result.analysis)
                                .font(styles.typography.bodySmall).foregroundColor(styles.colors.textSecondary)
                                .multilineTextAlignment(.center).padding(.top, styles.layout.spacingS).lineLimit(2)

                        } else {
                            // Premium user, but no decoded data yet or error
                             Text(placeholderMessage)
                                 .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                 .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
                                 .multilineTextAlignment(.center)
                                 if jsonString != nil && decodedTrend == nil && !decodingError {
                                     ProgressView().tint(styles.colors.accent).padding(.top, 4)
                                 }
                        }
                    } else {
                         // Free tier locked state
                         Text("Unlock mood trend analysis and insights with Premium.")
                             .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                             .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
                             .multilineTextAlignment(.center)
                    }
                }
            },
            detailContent: {
                // Expanded detail content (Only show if premium and data exists)
                if subscriptionTier == .premium, let result = decodedTrend {
                     VStack(spacing: styles.layout.spacingL) {
                        // ... (Detailed content using 'result' - unchanged from previous version) ...
                        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                            Text("Detailed Analysis")
                                .font(styles.typography.title3).foregroundColor(styles.colors.text)
                            Text(result.analysis)
                                .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !result.moodShifts.isEmpty {
                            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                Text("Notable Mood Shifts")
                                    .font(styles.typography.title3).foregroundColor(styles.colors.text)
                                ForEach(result.moodShifts, id: \.self) { shift in
                                    HStack(alignment: .top, spacing: styles.layout.spacingS) {
                                        Image(systemName: "arrow.right.arrow.left.circle.fill")
                                            .foregroundColor(styles.colors.accent).padding(.top, 2)
                                        Text(shift)
                                            .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                    }
                                }
                            }
                        }

                         VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                             Text("Dominant Mood: \(result.dominantMood)")
                                 .font(styles.typography.title3).foregroundColor(styles.colors.text)
                             Text("Understanding your most frequent mood can highlight your baseline emotional state or recurring feelings.")
                                 .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                         }

                         VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                             Text("Overall Trend: \(result.overallTrend)")
                                 .font(styles.typography.title3).foregroundColor(styles.colors.text)
                             Text("Tracking the general direction of your mood helps identify broader patterns over time.")
                                 .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                         }

                        if let date = generatedDate {
                            Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                                .font(styles.typography.caption).foregroundColor(styles.colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center).padding(.top)
                        }
                    } // End VStack for detail content
                } else if subscriptionTier == .free {
                     // Free tier expanded state
                      VStack(spacing: styles.layout.spacingL) {
                          Image(systemName: "lock.fill").font(.system(size: 40)).foregroundColor(styles.colors.accent)
                          Text("Upgrade for Details").font(styles.typography.title3).foregroundColor(styles.colors.text)
                          Text("Unlock detailed mood analysis and insights with Premium.")
                               .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary).multilineTextAlignment(.center)
                          // Optional Upgrade Button
                      }
                 } else {
                    // Premium, but no data
                    Text("Mood trend details are not available yet.")
                        .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } // End detailContent
        ) // End expandableCard
        // Add the onChange modifier to decode the JSON string
        .onChange(of: jsonString) { oldValue, newValue in
            decodeJSON(json: newValue)
        }
        // Decode initially as well
        .onAppear {
            decodeJSON(json: jsonString)
        }
    } // End body

    // Decoding function
    private func decodeJSON(json: String?) {
        guard let json = json, !json.isEmpty else {
            if decodedTrend != nil { decodedTrend = nil }
            decodingError = false
            return
        }
        decodingError = false
        guard let data = json.data(using: .utf8) else {
            print("⚠️ [MoodTrendsCard] Failed to convert JSON string to Data.")
            if decodedTrend != nil { decodedTrend = nil }
            decodingError = true
            return
        }
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(MoodTrendResult.self, from: data)
            if result != decodedTrend {
                 decodedTrend = result
                 print("[MoodTrendsCard] Successfully decoded new trend.")
            }
        } catch {
            print("‼️ [MoodTrendsCard] Failed to decode MoodTrendResult: \(error). JSON: \(json)")
            if decodedTrend != nil { decodedTrend = nil }
            decodingError = true
        }
    }
}