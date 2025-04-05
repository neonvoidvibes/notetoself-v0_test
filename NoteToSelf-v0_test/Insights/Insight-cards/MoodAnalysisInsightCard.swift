import SwiftUI
import Charts // Keep Charts import for expanded view

// Renamed from MoodTrendsInsightCard to MoodAnalysisInsightCard
struct MoodAnalysisInsightCard: View { // Ensure struct name matches file name
    // Input: Raw JSON string, generation date, and subscription status
    let jsonString: String?
    let generatedDate: Date?
    let subscriptionTier: SubscriptionTier

    // Local state for decoded result
    @State private var decodedTrend: MoodTrendResult? = nil
    @State private var decodingError: Bool = false
    @State private var isLoading: Bool = false

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var showingFullScreen = false // State for full screen presentation
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject
    @EnvironmentObject var appState: AppState // Needed for full entry data in detail view
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService

    // Helper to get color from Mood enum
    private func moodColor(forName moodName: String?) -> Color {
        guard let name = moodName, let mood = Mood.allCases.first(where: { $0.name.lowercased() == name.lowercased() }) else {
            return styles.colors.textSecondary // Default color
        }
        return mood.color
    }

    // Helper to get icon name from Mood enum
    private func moodIcon(forName moodName: String?) -> String {
        guard let name = moodName, let mood = Mood.allCases.first(where: { $0.name.lowercased() == name.lowercased() }) else {
            return "questionmark.circle.fill" // Default icon
        }
        return mood.systemIconName
    }

    // Helper for trend icon
    private func trendIcon(forName trendName: String?) -> String {
        guard let name = trendName else { return "arrow.right.circle.fill" }
        switch name.lowercased() {
        case "improving": return "arrow.up.trendline.chart.hi" // More visual trend icon
        case "declining": return "arrow.down.trendline.chart.hi"
        case "stable": return "chart.dots.scatter"
        case "fluctuating": return "waveform.path.ecg"
        default: return "chart.line.flattrend.xyaxis"
        }
    }

    // Placeholder message logic
    private var placeholderMessage: String {
        if jsonString == nil {
            return "Keep journaling regularly (at least 3 entries needed) to analyze your mood trends!"
        } else if decodedTrend == nil && !decodingError && isLoading {
            return "Loading mood analysis..."
        } else if decodingError {
            return "Could not load mood analysis. Please try again later."
        } else if decodedTrend == nil && !isLoading {
             return "Mood trend analysis is not available yet."
        } else {
            return "" // Should have data if no other condition met
        }
    }


    var body: some View {
        styles.expandableCard( // Removed isExpanded
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: Mood indicator, brief text, helping text
                VStack(alignment: .leading, spacing: styles.layout.spacingL) { // Increased spacing
                    HStack {
                        Text("Mood Landscape") // Updated Title
                            .font(styles.typography.title3).foregroundColor(styles.colors.text) // Revert to title3
                        Spacer()
                        if subscriptionTier == .free {
                            Image(systemName: "lock.fill").foregroundColor(styles.colors.textSecondary)
                        }
                    }

                    if subscriptionTier == .premium {
                        if let result = decodedTrend {
                            HStack(spacing: styles.layout.spacingM) {
                                // Mood Indicator (Dominant Mood Icon + Trend Arrow)
                                ZStack(alignment: .bottomTrailing) {
                                     Image(systemName: moodIcon(forName: result.dominantMood))
                                         .font(.system(size: 40)) // Larger icon
                                         .foregroundColor(moodColor(forName: result.dominantMood))

                                     Image(systemName: trendIcon(forName: result.overallTrend))
                                         .font(.system(size: 18))
                                         .foregroundColor(styles.colors.accent)
                                         .padding(4)
                                         .background(styles.colors.secondaryBackground.opacity(0.8).clipShape(Circle()))
                                         .offset(x: 8, y: 8) // Offset trend icon
                                }
                                .frame(width: 50) // Fixed width for indicator

                                // Brief Text & Helping Text
                                VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                                    Text("Overall: \(result.overallTrend), Dominant: \(result.dominantMood)")
                                        .font(styles.typography.bodyFont) // Main text
                                        .foregroundColor(styles.colors.text)
                                        .lineLimit(2)

                                    Text("See how your mood has been evolving this week.") // Helping text
                                        .font(styles.typography.caption)
                                        .foregroundColor(styles.colors.accent)
                                }
                                Spacer() // Push content left
                            }
                        } else {
                            // Premium user, loading, error or no data state
                            HStack { // Use HStack to center ProgressView if shown
                                Text(placeholderMessage)
                                    .font(styles.typography.bodyFont).foregroundColor(decodingError ? styles.colors.error : styles.colors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)

                                if isLoading {
                                     ProgressView().tint(styles.colors.accent).padding(.leading, 4)
                                }
                            }
                            .frame(minHeight: 60) // Ensure consistent height

                        }
                    } else {
                        // Free tier locked state
                        Text("Unlock mood trend analysis and insights with Premium.")
                            .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .center) // Adjusted height
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, styles.layout.paddingL) // INCREASED bottom padding
            } // Removed detailContent closure
        )
        .contentShape(Rectangle())
        .onTapGesture { if subscriptionTier == .premium { showingFullScreen = true } } // Only allow open if premium
        .onAppear(perform: loadInsight) // Added loading logic trigger
         // Add listener for explicit insight updates
         .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[MoodAnalysisCard] Received insightsDidUpdate notification.")
             loadInsight()
         }
        .fullScreenCover(isPresented: $showingFullScreen) {
             InsightFullScreenView(title: "Mood Landscape") {
                  // Pass entries needed for detail view's charts/analysis
                  MoodAnalysisDetailContent(
                      entries: appState.journalEntries,
                      generatedDate: generatedDate // Pass date
                  )
              }
              .environmentObject(styles) // Pass styles
              .environmentObject(appState) // Pass appState
         }
    } // End body

    // Function to load and decode the insight
    private func loadInsight() {
        guard !isLoading else { return }
        isLoading = true
        decodingError = false // Reset error state on new load attempt
        print("[MoodAnalysisCard] Loading insight...")
        Task {
            do {
                // Use await as DB call might become async
                 // Load the JSON. The date is passed in via the `generatedDate` let constant.
                if let (json, _) = try await databaseService.loadLatestInsight(type: "moodTrend") {
                     decodeJSON(json: json) // Call decode function
                     await MainActor.run { isLoading = false }
                     print("[MoodAnalysisCard] Insight loaded.")
                } else {
                    await MainActor.run {
                        decodedTrend = nil // Ensure it's nil if not found
                        isLoading = false
                        print("[MoodAnalysisCard] No stored insight found.")
                    }
                }
            } catch {
                 await MainActor.run {
                     print("‼️ [MoodAnalysisCard] Failed to load insight: \(error)")
                     decodedTrend = nil // Clear result on error
                     decodingError = true // Set error state
                     isLoading = false
                 }
            }
        }
    }

    // Decoding function (can be private)
    private func decodeJSON(json: String?) {
        guard let json = json, !json.isEmpty else {
             if decodedTrend != nil {
                 Task { await MainActor.run { decodedTrend = nil } }
             }
             // isLoading = false // Don't set loading false here yet
            return
        }
        // isLoading = true // Set loading true when starting decode
        // decodingError = false // Reset error before trying decode

        guard let data = json.data(using: .utf8) else {
            print("⚠️ [MoodAnalysisCard] Failed convert JSON string to Data.");
            Task { await MainActor.run { decodingError = true; decodedTrend = nil; isLoading = false } } // Stop loading on error
            return
        }
        do {
            let result = try JSONDecoder().decode(MoodTrendResult.self, from: data)
            Task { await MainActor.run { // Ensure state update is on main thread
                if result != decodedTrend { decodedTrend = result; print("[MoodAnalysisCard] Decoded new trend.") }
                decodingError = false // Clear error on successful decode
                // isLoading = false // Stop loading on success - Handled in loadInsight now
            }}
        } catch {
            print("‼️ [MoodAnalysisCard] Failed decode MoodTrendResult: \(error). JSON: \(json)");
            Task { await MainActor.run { decodingError = true; decodedTrend = nil; isLoading = false } } // Stop loading on error
        }
    }
}

// Update Preview Provider name
#Preview {
    ScrollView{
        MoodAnalysisInsightCard(jsonString: MoodTrendResult.empty().toJsonString(), generatedDate: Date(), subscriptionTier: .premium)
            .padding()
            .environmentObject(AppState()) // Provide mock data if needed
            .environmentObject(DatabaseService()) // Provide DatabaseService
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}

// Helper extension for preview (Keep as is)
extension MoodTrendResult {
    func toJsonString() -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self), let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}