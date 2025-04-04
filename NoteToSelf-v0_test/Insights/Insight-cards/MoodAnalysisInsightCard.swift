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
    @State private var isLoading: Bool = false // Added missing state variable

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
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
            scrollProxy: scrollProxy,
            cardId: cardId,
            content: {
                // Collapsed View: Mood indicator, brief text, helping text
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Mood Landscape") // Updated Title
                            .font(styles.typography.title3).foregroundColor(styles.colors.text)
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
                            // Premium user, but no decoded data yet or error
                            Text(placeholderMessage)
                                .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                                .frame(maxWidth: .infinity, minHeight: 60, alignment: .center) // Adjusted height
                                .multilineTextAlignment(.center)
                            if jsonString != nil && decodedTrend == nil && !decodingError {
                                ProgressView().tint(styles.colors.accent).padding(.top, 4)
                            }
                        }
                    } else {
                        // Free tier locked state
                        Text("Unlock mood trend analysis and insights with Premium.")
                            .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .center) // Adjusted height
                            .multilineTextAlignment(.center)
                    }
                }
            },
            detailContent: {
                // Expanded View: Use MoodAnalysisDetailContent
                if subscriptionTier == .premium {
                    // Pass all entries for detailed chart generation
                    MoodAnalysisDetailContent(entries: appState.journalEntries)
                } else {
                    // Free tier expanded state (same as summary/recs)
                    VStack(spacing: styles.layout.spacingL) {
                        Image(systemName: "lock.fill").font(.system(size: 40)).foregroundColor(styles.colors.accent)
                        Text("Upgrade for Details").font(styles.typography.title3).foregroundColor(styles.colors.text)
                        Text("Unlock detailed mood charts and analysis with Premium.")
                             .font(styles.typography.bodyFont).foregroundColor(styles.colors.textSecondary).multilineTextAlignment(.center)
                        Button { /* TODO: Trigger upgrade flow */ } label: {
                             Text("Upgrade Now").foregroundColor(styles.colors.primaryButtonText)
                        }.buttonStyle(GlowingButtonStyle())
                         .padding(.top)
                    }
                }
            }
        )
        .onAppear(perform: loadInsight) // Added loading logic trigger
        .onChange(of: jsonString) { oldValue, newValue in
            decodeJSON(json: newValue)
        }
        // Reload if entries change (might need debounce later)
         .onChange(of: appState.journalEntries.count) { _, _ in loadInsight() }
         // Add listener for explicit insight updates
         .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[MoodAnalysisCard] Received insightsDidUpdate notification.")
             loadInsight()
         }
    }

    // Function to load and decode the insight
    private func loadInsight() {
        guard !isLoading else { return }
        isLoading = true
        decodingError = false // Reset error state on new load attempt
        print("[MoodAnalysisCard] Loading insight...")
        Task {
            do {
                // Use await as DB call might become async
                if let (json, _) = try await databaseService.loadLatestInsight(type: "moodTrend") { // Use correct identifier
                     decodeJSON(json: json) // Call decode function
                     await MainActor.run { isLoading = false } // Set loading false after decoding attempt
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
            // Don't reset here if it was already nil, just handle empty input
             if decodedTrend != nil {
                 Task { await MainActor.run { decodedTrend = nil } }
             }
            // decodingError = false // Resetting error here might hide loading errors
            return
        }
        // decodingError = false // Reset error before attempting decode

        guard let data = json.data(using: .utf8) else {
            print("⚠️ [MoodAnalysisCard] Failed convert JSON string to Data.");
            Task { await MainActor.run { decodingError = true; decodedTrend = nil } }
            return
        }
        do {
            let result = try JSONDecoder().decode(MoodTrendResult.self, from: data)
            Task { await MainActor.run { // Ensure state update is on main thread
                if result != decodedTrend { decodedTrend = result; print("[MoodAnalysisCard] Decoded new trend.") }
                decodingError = false // Clear error on successful decode
            }}
        } catch {
            print("‼️ [MoodAnalysisCard] Failed decode MoodTrendResult: \(error). JSON: \(json)");
            Task { await MainActor.run { decodingError = true; decodedTrend = nil } }
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