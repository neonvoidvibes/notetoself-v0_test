import SwiftUI

// MARK: - Data Structure for Heatmap
struct HeatmapDayInfo: Identifiable {
    let id = UUID()
    let date: Date
    let entry: JournalEntry? // Store the latest entry for the day
    var moodColor: Color? { entry?.mood.color }
}

// MARK: - Journey Insight Card View
struct JourneyInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService
    @ObservedObject private var styles = UIStyles.shared

    // State for Card Expansion
    @State private var isExpanded: Bool = false

    // State for Pop-up Preview
    @State private var showingPopup: Bool = false
    @State private var selectedEntryForPopup: JournalEntry? = nil
    @State private var fullscreenEntryFromPopup: JournalEntry? = nil // For triggering full screen

    // State for Narrative Loading (Keep As Is)
    @State private var narrativeResult: StreakNarrativeResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoadingNarrative: Bool = false
    @State private var loadNarrativeError: Bool = false
    private let insightTypeIdentifier = "journeyNarrative"

    // State variable to hold prepared heatmap data
    @State private var _heatmapData: [HeatmapDayInfo] = []

    // --- Computed Properties ---

    // Heatmap Data Preparation - Now just returns the state
    private var heatmapData: [HeatmapDayInfo] {
        _heatmapData
    }

    // Narrative Snippet (Keep As Is, handles loading/error)
    private var narrativeSnippetDisplay: String {
         if isLoadingNarrative { return "Loading..." }
         if loadNarrativeError { return "Narrative unavailable" }
         guard let result = narrativeResult else {
             return "Your journey unfolds..." // Default when no result
         }
         let snippet = result.storySnippet.isEmpty ? "Your journey unfolds..." : result.storySnippet
         let maxLength = 100
         if snippet.count > maxLength {
             return String(snippet.prefix(maxLength)) + "..."
         } else {
             return snippet
         }
     }

    // Narrative Display Text for Expanded View (Keep As Is)
    private var narrativeDisplayText: String {
         if isLoadingNarrative { return "Loading narrative..." }
         if loadNarrativeError { return "Could not load narrative." }
         guard let result = narrativeResult, !result.narrativeText.isEmpty else {
             // Use currentStreak from AppState directly for the check
             return appState.currentStreak > 0 ? "Analyzing your recent journey..." : "Your journey's story will appear here."
         }
         return result.narrativeText
    }

    // --- Body ---
    var body: some View {
        ZStack { // ZStack to overlay the popup
            // Main Card Structure
            mainCardContent

            // --- Pop-up Overlay ---
            if showingPopup, let entry = selectedEntryForPopup {
                EntryPreviewPopupView(entry: entry, isPresented: $showingPopup) {
                    // Action for the "Expand" button in the popup
                    showingPopup = false
                    // Use DispatchQueue to ensure state change happens after dismissal animation starts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                         fullscreenEntryFromPopup = entry
                    }
                }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .zIndex(10) // Ensure popup is on top
            }

        } // End ZStack
        .onAppear {
            // Initial data preparation for heatmap
            _heatmapData = JourneyInsightCard.prepareHeatmapData(for: Date(), using: appState.journalEntries)
            // Initial narrative loading
            loadNarrative()
        }
        .onChange(of: appState.journalEntries) { oldValue, newValue in
            // Update heatmap data when entries change
            _heatmapData = JourneyInsightCard.prepareHeatmapData(for: Date(), using: newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[JourneyCard] Received insightsDidUpdate notification.")
             loadNarrative() // Reload narrative on update
        }
        // Add Fullscreen Cover for entry details triggered from popup
        .fullScreenCover(item: $fullscreenEntryFromPopup) { entry in
             FullscreenEntryView(entry: entry) // Assuming this view exists and works
        }
    } // End body

    // --- Helper Views for Body ---

    private var mainCardContent: some View {
        VStack(spacing: 0) {
            // Main Content Area (Header + Optional Expanded View)
            VStack(spacing: 0) { // Use spacing 0 here, manage space internally
                // Collapsed/Header View
                collapsedHeaderView

                // Expanded Content
                if isExpanded {
                    expandedContentView
                }

                // Expand/Collapse Button
                expandCollapseButtonView
            } // End Main Content VStack
        } // End Outer VStack
        .background(styles.colors.cardBackground)
        .cornerRadius(styles.layout.radiusL)
    }

    private var collapsedHeaderView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: styles.layout.spacingM) { // Increased spacing

                // NEW: Replaced Streak Headline
                Text("Recent Activity")
                    .font(styles.typography.bodyLarge.weight(.semibold)) // Style as desired
                    .foregroundColor(styles.colors.text)
                    .padding(.bottom, styles.layout.spacingXS)

                // Narrative Snippet Display (Kept)
                Text(narrativeSnippetDisplay)
                    .font(styles.typography.bodySmall)
                    .foregroundColor(loadNarrativeError ? styles.colors.error : styles.colors.textSecondary)
                    .lineLimit(5)
                    .padding(.bottom, styles.layout.spacingS)

                // NEW: Mini Calendar Heatmap
                // Pass the helper function reference for the tap action
                MiniCalendarHeatmapView(data: heatmapData, onTapDay: handleHeatmapTap)
                // Add some padding below the heatmap
                .padding(.bottom, styles.layout.spacingS)


            } // End Leading VStack
            Spacer()
        } // End Header HStack
        .padding(.horizontal, styles.layout.paddingL)
        .padding(.vertical, styles.layout.paddingM + 4)
    }

    // Helper function to handle heatmap day taps
    private func handleHeatmapTap(entry: JournalEntry) {
        selectedEntryForPopup = entry
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingPopup = true
        }
    }

    private var expandedContentView: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingL) {
            Divider().background(styles.colors.divider.opacity(0.5))

            // Explainer Text (Keep As Is)
            Text("Consistency is key to building lasting habits and unlocking deeper insights. Celebrate your progress, one day at a time!")
                .font(styles.typography.bodySmall)
                .foregroundColor(styles.colors.accent)
                .padding(.vertical, styles.layout.spacingS)

             // Narrative Text Section (Keep As Is)
             VStack(alignment: .leading) {
                 Text("Highlights")
                     .font(styles.typography.bodyLarge.weight(.semibold))
                     .foregroundColor(styles.colors.text)
                     .padding(.bottom, styles.layout.spacingXS)

                  Text(narrativeDisplayText)
                     .font(styles.typography.bodyFont)
                     .foregroundColor(loadNarrativeError ? styles.colors.error : styles.colors.textSecondary)
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .fixedSize(horizontal: false, vertical: true)

             }
             .padding(.vertical, styles.layout.spacingS)

            // Streak Milestones (Keep As Is, using appState.currentStreak)
            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                Text("Milestones")
                    .font(styles.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(styles.colors.text)

                HStack(spacing: styles.layout.spacingL) {

                    // Explicitly declare type
                    let milestone7: MilestoneView = MilestoneView(
                        label: "7 Days",
                        icon: "star.fill",
                        isAchieved: appState.currentStreak >= 7, // Use AppState directly
                        accentColor: styles.colors.accent,
                        defaultStrokeColor: styles.colors.tertiaryAccent
                    )
                    milestone7 // Use the declared variable

                     // Explicitly declare type
                     let milestone30: MilestoneView = MilestoneView(
                         label: "30 Days",
                         icon: "star.fill",
                         isAchieved: appState.currentStreak >= 30, // Use AppState directly
                         accentColor: styles.colors.accent,
                         defaultStrokeColor: styles.colors.tertiaryAccent
                     )
                     milestone30 // Use the declared variable

                     // Explicitly declare type
                     let milestone100: MilestoneView = MilestoneView(
                         label: "100 Days",
                         icon: "star.fill",
                         isAchieved: appState.currentStreak >= 100, // Use AppState directly
                         accentColor: styles.colors.accent,
                         defaultStrokeColor: styles.colors.tertiaryAccent
                     )
                     milestone100 // Use the declared variable

                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            .padding(.top, styles.layout.spacingS)

        }
        .padding(.horizontal, styles.layout.paddingL)
        .padding(.bottom, styles.layout.paddingM)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var expandCollapseButtonView: some View {
        VStack(spacing: styles.layout.spacingXS) {
            Text(isExpanded ? "Close" : "Show more of my journey")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(styles.colors.accent)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(styles.colors.accent)
                    .rotationEffect(Angle(degrees: isExpanded ? 180 : 0))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, styles.layout.paddingS)
        .padding(.bottom, styles.layout.paddingL + styles.layout.paddingL)
    }


    // --- Data Preparation Function (Static) ---
    // Made static to avoid potential issues calling instance methods during initialization
    private static func prepareHeatmapData(for date: Date, using entries: [JournalEntry]) -> [HeatmapDayInfo] {
        let calendar = Calendar.current
        let daysToShow = 35 // 5 rows * 7 days
        guard let endDate = calendar.startOfDay(for: date) as Date?, // Today
              let startDate = calendar.date(byAdding: .day, value: -(daysToShow - 1), to: endDate) else {
            return []
        }

        // Create a dictionary of entries keyed by the start of their day for quick lookup
        let entriesByDay = Dictionary(grouping: entries) { entry -> Date in
            calendar.startOfDay(for: entry.date)
        }

        var heatmapDays: [HeatmapDayInfo] = []
        var currentDate = startDate
        while currentDate <= endDate {
            let dayEntries = entriesByDay[currentDate] ?? []
            // Find the *latest* entry for the day if multiple exist
            let latestEntry = dayEntries.max(by: { $0.date < $1.date })
            heatmapDays.append(HeatmapDayInfo(date: currentDate, entry: latestEntry))
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }

        // Ensure we always have exactly `daysToShow` elements, padding with empty if necessary
        // (This logic might be redundant if the loop correctly generates `daysToShow` days)
        let paddingNeeded = daysToShow - heatmapDays.count
        if paddingNeeded > 0 {
            // This case should ideally not happen with the loop logic, but added for safety
            print("Warning: Heatmap data generation needed padding (\(paddingNeeded) days).")
            // Prepend empty days if needed (adjust logic based on desired alignment)
            // For simplicity, let's assume the loop generates the correct count.
        }

        return Array(heatmapDays.suffix(daysToShow)) // Return the last `daysToShow` days
    }

    // --- Narrative Loading Function (Keep As Is) ---
    private func loadNarrative() {
        guard !isLoadingNarrative else { return }
        isLoadingNarrative = true
        loadNarrativeError = false
        narrativeResult = nil
        print("[JourneyCard] Loading narrative insight...")
        Task {
            var loadedDate: Date? = nil
            var decodeError: Error? = nil
            var finalResult: StreakNarrativeResult? = nil
            do {
                if let (json, date, _) = try databaseService.loadLatestInsight(type: insightTypeIdentifier) {
                    loadedDate = date
                    if let data = json.data(using: .utf8) {
                        let decoder = JSONDecoder()
                        do { finalResult = try decoder.decode(StreakNarrativeResult.self, from: data) }
                        catch { decodeError = error }
                    } else { decodeError = NSError(domain: "JourneyCard", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to Data"]) }
                } else {
                     print("[JourneyCard] No stored narrative found.")
                }
            } catch {
                decodeError = error
                print("‼️ [JourneyCard] Error loading insight: \(error)")
            }
            await MainActor.run {
                self.narrativeResult = finalResult
                self.generatedDate = loadedDate
                self.loadNarrativeError = (decodeError != nil)
                self.isLoadingNarrative = false
                 print("[JourneyCard] Narrative load complete. Error: \(loadNarrativeError)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    // Directly create state objects for the preview
    let previewAppState = AppState()
    let previewDbService = DatabaseService()
    let themeManager = ThemeManager.shared // Use shared instance

    // Add mock data
    let calendar = Calendar.current
    let today = Date()
    previewAppState._journalEntries = (0..<20).map { i -> JournalEntry in
        let date = calendar.date(byAdding: .day, value: -i * 2, to: today)!
        let mood = Mood.allCases.randomElement() ?? .neutral
        return JournalEntry(text: "Entry for day \(i)", mood: mood, date: date)
    } + [JournalEntry(text: "Today's Entry", mood: .happy, date: today)]

    // Return the view with environment objects directly
    return ScrollView {
        JourneyInsightCard()
            .padding()
    }
    .environmentObject(previewAppState)
    .environmentObject(previewDbService)
    .environmentObject(UIStyles.shared) // Provide UIStyles directly
    .environmentObject(themeManager)
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}