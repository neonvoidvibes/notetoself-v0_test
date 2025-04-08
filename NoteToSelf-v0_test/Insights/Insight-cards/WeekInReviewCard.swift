import SwiftUI
import Charts // Import Charts

struct WeekInReviewCard: View {
    @EnvironmentObject var appState: AppState
    // Remove databaseService dependency if loading is handled by parent
    // @EnvironmentObject var databaseService: DatabaseService

    // Accept data from parent
    let jsonString: String?
    let generatedDate: Date?

    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false
    @ObservedObject private var styles = UIStyles.shared

    // State for DECODED result, loading/error status during decode
    @State private var insightResult: WeekInReviewResult? = nil
    @State private var isLoading: Bool = false // Used briefly during decode
    @State private var decodeError: Bool = false

    // [5.1] Use isFresh computed property
    private var isFresh: Bool {
        guard let genDate = generatedDate else { return false }
        return Calendar.current.dateComponents([.hour], from: genDate, to: Date()).hour ?? 25 < 24
    }

    // Format the date range string
    private var summaryPeriod: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // e.g., "Oct 20"

        // Use decoded result's dates if available
        if let start = insightResult?.startDate, let end = insightResult?.endDate {
             // Format to show only Month and Day
             return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else {
            // Fallback if dates are not in the result (should ideally not happen)
             print("⚠️ [WeekInReviewCard] Warning: startDate or endDate missing from insightResult. Using fallback period text.")
             return "Previous Week" // Simple fallback
        }
        /* // Removed fallback logic based on generation date, rely on result dates
         else if let genDate = generatedDate {
            // Fallback: Calculate based on generation date if result dates are nil
             let calendar = Calendar.current
             guard let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: genDate)),
                   let startOfWeek = calendar.date(byAdding: .day, value: -7, to: sunday), // Previous Sunday relative to generation date
                   let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
                 return "Previous Week"
             }
             return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
        } else {
            // Ultimate fallback
            return "Previous Week"
        }
         */
    }

    // Computed property for snapshot text remains the same
    private var summaryText: String? { insightResult?.summaryText }


    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header with Date Range and NEW badge - VERIFIED
                    HStack {
                        Text("Week in Review") // Card Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text) // Standard color

                        Spacer()

                         Text(summaryPeriod) // Date range on the right
                             .font(styles.typography.caption.weight(.medium))
                             .foregroundColor(styles.colors.textSecondary)

                        // [5.1] Use reusable NewBadgeView
                        if isFresh && appState.subscriptionTier == .pro { // CORRECTED: Check .pro
                            NewBadgeView()
                        }
                        if appState.subscriptionTier == .free { // Gating check is correct (.free)
                             HStack(spacing: 4) { // Group badge and lock
                                 ProBadgeView()
                                 Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                             }
                             .padding(.leading, 4) // Keep padding before the group
                        }
                    }

                    // Content Snippet (Summary Text)
                    if appState.subscriptionTier == .pro { // CORRECTED: Check .pro
                        if isLoading { // Decoding in progress
                            ProgressView().tint(styles.colors.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 100) // Increase height for chart placeholder
                        } else if decodeError {
                            // [4.2] Improved Error Message
                            Text("Couldn't load weekly review.\nPlease try again later.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.error)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 100) // Increase height
                        } else if let result = insightResult {
                             VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                                 if let summary = summaryText, !summary.isEmpty {
                                     Text(summary)
                                         .font(styles.typography.bodyFont) // Ensure bodyFont
                                         .foregroundColor(styles.colors.text) // Ensure primary text color
                                         .lineLimit(2) // Limit summary text to 2 lines
                                 } else {
                                     Text("Weekly summary analysis pending.")
                                         .font(styles.typography.bodyFont)
                                         .foregroundColor(styles.colors.text)
                                         .lineLimit(2)
                                 }
                             }
                             .padding(.bottom, styles.layout.spacingS) // Space between text and chart

                            // [3.2] Mini Bar Chart
                             if #available(iOS 16.0, *) {
                                  let barChartData = transformToBarChartData(result.moodTrendChartData)
                                  if !barChartData.isEmpty {
                                      MiniWeeklyBarChart(
                                          data: barChartData,
                                          color: styles.colors.accent
                                      )
                                      .padding(.vertical, styles.layout.spacingXS) // Padding around chart
                                  } else {
                                     // Optional: Placeholder if chart data is missing but insight exists
                                     Rectangle()
                                          .fill(styles.colors.secondaryBackground.opacity(0.5))
                                          .frame(height: 50)
                                          .cornerRadius(styles.layout.radiusM)
                                          .overlay(Text("Chart data unavailable").font(.caption).foregroundColor(styles.colors.textSecondary))
                                          .padding(.vertical, styles.layout.spacingXS)
                                  }
                             }

                             // Helping Text
                             Text("Tap for weekly patterns & insights.")
                                 .font(styles.typography.caption)
                                 .foregroundColor(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .leading)
                                 .padding(.top, styles.layout.spacingXS) // Space above helping text

                        } else {
                             // Handles nil jsonString or empty decoded data
                            Text("Weekly review available after a week of journaling.")
                                .font(styles.typography.bodyFont) // Ensure bodyFont
                                .foregroundColor(styles.colors.text) // Ensure primary text color
                                .frame(minHeight: 100, alignment: .center) // Increase height
                        }
                    } else {
                         // Use LockedContentView with updated text
                         LockedContentView(message: "Unlock weekly reviews and pattern analysis with Pro.")
                             .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, styles.layout.paddingL)
            }
        )
        .contentShape(Rectangle())
        // [8.2] Updated tap gesture to handle locked state
        .onTapGesture {
            if appState.subscriptionTier == .pro {
                // Pro users can open if content is decoded (or even if loading/error to see status)
                showingFullScreen = true
            } else {
                // Free user tapped locked card
                print("[WeekInReviewCard] Locked card tapped. Triggering upgrade flow...")
                // TODO: [8.2] Implement presentation of upgrade/paywall screen for 'Week in Review'.
            }
        }
        .opacity(appState.subscriptionTier == .free ? 0.7 : 1.0) // [8.1] Dim card slightly when locked
        .onAppear { decodeJSON() } // Decode initial JSON
        .onChange(of: jsonString) { // Re-decode if JSON string changes
            oldValue, newValue in
            decodeJSON()
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Week in Review") {
                  WeekInReviewDetailContent(
                      result: insightResult ?? .empty(), // Use decoded result
                      generatedDate: generatedDate // Pass date
                  )
              }
              .environmentObject(styles)
              .environmentObject(appState)
        }
    }

    // [3.2] Helper to transform MoodTrendPoint data to WeeklyBarChartDataPoint
    private func transformToBarChartData(_ trendData: [MoodTrendPoint]?) -> [WeeklyBarChartDataPoint] {
        guard let trendData = trendData, trendData.count == 7 else { return [] } // Ensure exactly 7 days

        let calendar = Calendar.current
        // Ensure shortWeekdaySymbols respects locale by using calendar instance
        let shortWeekdaySymbols = calendar.shortWeekdaySymbols
        guard shortWeekdaySymbols.count == 7 else { return [] } // Safety check

        // Sort data by date just in case it's not already sorted
        let sortedData = trendData.sorted { $0.date < $1.date }

        // Create a dictionary to map weekday index (1=Sun..7=Sat) to value
        var valuesByWeekday: [Int: Double] = [:]
        for point in sortedData {
            let weekdayIndex = calendar.component(.weekday, from: point.date)
            valuesByWeekday[weekdayIndex] = point.moodValue
        }

        // Ensure all 7 days are present, defaulting to 0 if missing
         // Map weekday index (1..7) to the correct symbol index (0..6)
         return (1...7).map { weekdayIndex in
             // Adjust for firstWeekday (e.g., Sunday=1 vs Monday=2)
              // Example: If firstWeekday is 2 (Mon), Sunday (1) should map to index 6.
              // (weekdayIndex - calendar.firstWeekday + 7) % 7
             let symbolIndex = (weekdayIndex - calendar.firstWeekday + 7) % 7
             let dayString = shortWeekdaySymbols[symbolIndex]
             let value = valuesByWeekday[weekdayIndex] ?? 0.0 // Default to 0 if no data for the day
             return WeeklyBarChartDataPoint(day: dayString, value: value)
         }
    }


    // Decode function using the passed-in jsonString
     @MainActor
     private func decodeJSON() {
         guard let json = jsonString, !json.isEmpty else {
             insightResult = nil
             decodeError = false // Not an error if no JSON provided
             isLoading = false
             return
         }

         if !isLoading { isLoading = true } // Set loading only if not already loading
         decodeError = false
         print("[WeekInReviewCard] Decoding JSON...")

         if let data = json.data(using: .utf8) {
             do {
                  let decoder = JSONDecoder()
                  decoder.dateDecodingStrategy = .iso8601 // Match encoding strategy
                 let result = try decoder.decode(WeekInReviewResult.self, from: data)
                 self.insightResult = result
                 self.decodeError = false
                 print("[WeekInReviewCard] Decode success.")
             } catch {
                 print("‼️ [WeekInReviewCard] Failed to decode WeekInReviewResult: \(error). JSON: \(json)")
                 self.insightResult = nil
                 self.decodeError = true
             }
         } else {
             print("‼️ [WeekInReviewCard] Failed to convert JSON string to Data.")
             self.insightResult = nil
             self.decodeError = true
         }
         self.isLoading = false
     }
}

#Preview {
     // Pass nil for preview as InsightsView now handles loading
    ScrollView {
        WeekInReviewCard(jsonString: nil, generatedDate: nil)
            .padding()
            .environmentObject(AppState())
            .environmentObject(DatabaseService()) // Keep DB if detail view needs it
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}