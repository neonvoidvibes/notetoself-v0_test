import SwiftUI

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

    // Calculate if the insight is fresh (generated within last 24 hours)
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
             return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else if let genDate = generatedDate {
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
    }

    // Computed property for snapshot text remains the same
    private var summaryText: String? { insightResult?.summaryText }


    var body: some View {
        styles.expandableCard(
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                    // Header with Date Range and NEW badge
                    HStack {
                        Text("Week in Review") // Card Title
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text) // Standard color

                        Spacer()

                         Text(summaryPeriod) // Date range on the right
                             .font(styles.typography.caption.weight(.medium))
                             .foregroundColor(styles.colors.textSecondary)

                        if isFresh && appState.subscriptionTier == .premium {
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(styles.colors.accentContrastText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(styles.colors.accent.opacity(0.9))
                                .clipShape(Capsule())
                        }
                        if appState.subscriptionTier == .free { // Gating
                            Image(systemName: "lock.fill")
                                .foregroundColor(styles.colors.textSecondary)
                                .padding(.leading, 4) // Space before lock
                        }
                    }

                    // Content Snippet (Summary Text)
                    if appState.subscriptionTier == .premium {
                        if isLoading { // Decoding in progress
                            ProgressView().tint(styles.colors.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(minHeight: 60)
                        } else if decodeError {
                            Text("Could not load weekly review.")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.error)
                                .frame(minHeight: 60)
                        } else if let summary = summaryText, !summary.isEmpty {
                             VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                                 Text(summary)
                                     .font(styles.typography.bodyFont)
                                     .foregroundColor(styles.colors.text)
                                     .lineLimit(3) // Allow more lines for summary
                             }
                              .padding(.bottom, styles.layout.spacingS)

                             // Helping Text
                             Text("Tap for weekly patterns & insights.")
                                 .font(styles.typography.caption)
                                 .foregroundColor(styles.colors.accent)
                                 .frame(maxWidth: .infinity, alignment: .leading)

                        } else {
                             // Handles nil jsonString or empty decoded data
                            Text("Weekly review available after a week of journaling.")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)
                                .frame(minHeight: 60, alignment: .center)
                        }
                    } else {
                         Text("Unlock weekly reviews and pattern analysis with Premium.")
                             .font(styles.typography.bodySmall)
                             .foregroundColor(styles.colors.textSecondary)
                             .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                             .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, styles.layout.paddingL)
            }
        )
        .contentShape(Rectangle())
        .onTapGesture { if appState.subscriptionTier == .premium { showingFullScreen = true } }
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

    // Decode function using the passed-in jsonString
     @MainActor
     private func decodeJSON() {
         guard let json = jsonString, !json.isEmpty else {
             insightResult = nil
             decodeError = false // Not an error if no JSON provided
             isLoading = false
             return
         }

         isLoading = true
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