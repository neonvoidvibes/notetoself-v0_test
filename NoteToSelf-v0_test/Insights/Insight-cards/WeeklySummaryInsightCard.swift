import SwiftUI

struct WeeklySummaryInsightCard: View {
    // Input: Raw JSON string, generation date, and subscription status
    let jsonString: String?
    let generatedDate: Date?
    let isFresh: Bool
    let subscriptionTier: SubscriptionTier

    // Local state for decoded result
    @State private var decodedSummary: WeeklySummaryResult? = nil
    @State private var decodingError: Bool = false

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    private let styles = UIStyles.shared

    // Computed properties based on the DECODED result
    private var summaryPeriod: String {
        let calendar = Calendar.current
        let endDate = generatedDate ?? Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
    }

    private var dominantMood: String? {
        guard let result = decodedSummary, !result.moodTrend.isEmpty, result.moodTrend != "N/A" else { return nil }
        let trendLower = result.moodTrend.lowercased()
        if let range = trendLower.range(of: "predominantly ") {
            return String(trendLower[range.upperBound...]).capitalized
        }
        return result.moodTrend.contains("positive") || result.moodTrend.contains("Improving") ? "Positive" :
               result.moodTrend.contains("negative") || result.moodTrend.contains("Declining") ? "Negative" :
               result.moodTrend == "Stable" ? "Stable" : nil
    }

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

    // Placeholder message logic remains similar, but based on jsonString presence
    private var placeholderMessage: String {
        if jsonString == nil {
            return "Keep journaling this week to generate your first summary!"
        } else if decodedSummary == nil && !decodingError {
             return "Loading summary..." // Indicates decoding is happening or pending
        } else if decodingError {
            return "Could not load summary. Please try again later."
        } else {
            // Should have decodedSummary if no error and jsonString exists
            return "Weekly summary is not available yet."
        }
    }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            isPrimary: isFresh && subscriptionTier == .premium, // Only highlight if premium and fresh
            scrollProxy: scrollProxy, // Pass proxy
            cardId: cardId,           // Pass ID
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Weekly Summary")
                            .font(styles.typography.title3).foregroundColor(styles.colors.text)
                        if isFresh && subscriptionTier == .premium {
                            Text("NEW").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(styles.colors.accent).cornerRadius(4)
                        }
                        Spacer()
                        if subscriptionTier == .free {
                             Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                        }
                    }

                    // Conditional display
                    if subscriptionTier == .premium {
                        Text(summaryPeriod)
                            .font(styles.typography.insightCaption).foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Use decodedSummary for display
                        if let result = decodedSummary {
                            Text(result.mainSummary)
                                .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                .multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(3)

                            if !result.keyThemes.isEmpty {
                                HStack(spacing: 8) {
                                    ForEach(result.keyThemes.prefix(3), id: \.self) { theme in
                                        Text(theme).font(styles.typography.caption)
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(styles.colors.tertiaryBackground).cornerRadius(styles.layout.radiusM)
                                            .foregroundColor(styles.colors.textSecondary)
                                    }
                                    Spacer()
                                }.padding(.top, 4)
                            }
                        } else {
                            // Premium user, but no decoded data yet or error
                             Text(placeholderMessage)
                                 .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                 .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                                 .multilineTextAlignment(.center)
                                 // Optionally show ProgressView if jsonString exists but decoded is nil
                                 if jsonString != nil && decodedSummary == nil && !decodingError {
                                     ProgressView().tint(styles.colors.accent).padding(.top, 4)
                                 }
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
                // Expanded detail content (Only show if premium and data exists)
                if subscriptionTier == .premium, let result = decodedSummary {
                    VStack(spacing: styles.layout.spacingL) {
                         // ... (Detailed content using 'result' - unchanged from previous version) ...
                         VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                             Text("Summary")
                                 .font(styles.typography.title3).foregroundColor(styles.colors.text)
                             Text(result.mainSummary)
                                 .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                 .fixedSize(horizontal: false, vertical: true)
                         }

                         if !result.keyThemes.isEmpty {
                             VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                 Text("Key Themes")
                                     .font(styles.typography.title3).foregroundColor(styles.colors.text)
                                 FlowLayout(spacing: 10) {
                                      ForEach(result.keyThemes, id: \.self) { theme in
                                          Text(theme)
                                              .font(styles.typography.bodySmall)
                                              .padding(.horizontal, 10).padding(.vertical, 6)
                                              .background(styles.colors.secondaryBackground).cornerRadius(styles.layout.radiusM)
                                              .foregroundColor(styles.colors.text)
                                      }
                                 }
                             }
                         }

                         VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                             Text("Mood Trend")
                                 .font(styles.typography.title3).foregroundColor(styles.colors.text)
                             HStack {
                                  let color = moodColor(forName: dominantMood)
                                  Circle().fill(color).frame(width: 12, height: 12)
                                 Text(result.moodTrend)
                                     .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                             }
                         }

                         if !result.notableQuote.isEmpty {
                              VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                  Text("Notable Quote")
                                      .font(styles.typography.title3).foregroundColor(styles.colors.text)
                                  Text("\"\(result.notableQuote)\"")
                                      .font(styles.typography.bodyFont.italic()).foregroundColor(styles.colors.accent)
                              }
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
                          Text("Unlock detailed weekly summaries and insights with Premium.")
                               .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary).multilineTextAlignment(.center)
                          // Optional Upgrade Button
                      }
                 } else {
                    // Premium, but no data
                    Text("Weekly summary details are not available yet.")
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
            // If input JSON is nil or empty, clear the decoded state
            if decodedSummary != nil { decodedSummary = nil }
            decodingError = false // Not an error, just no data
            return
        }

        // Reset error state before attempting decode
        decodingError = false

        guard let data = json.data(using: .utf8) else {
            print("⚠️ [WeeklySummaryCard] Failed to convert JSON string to Data.")
            if decodedSummary != nil { decodedSummary = nil }
            decodingError = true
            return
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(WeeklySummaryResult.self, from: data)
            // Update state only if decoded data is different to avoid unnecessary view updates
            if result != decodedSummary {
                 decodedSummary = result
                 print("[WeeklySummaryCard] Successfully decoded new summary.")
            }
        } catch {
            print("‼️ [WeeklySummaryCard] Failed to decode WeeklySummaryResult: \(error). JSON: \(json)")
            if decodedSummary != nil { decodedSummary = nil } // Clear previous result on error
            decodingError = true
        }
    }
}