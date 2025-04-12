import SwiftUI
import Charts // For potential future chart library use, basic shapes for now

struct JourneyInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService
    @Environment(\.colorScheme) var colorScheme // Detect light/dark mode
    @ObservedObject private var styles = UIStyles.shared

    @State private var isExpanded: Bool = false
    // State for narrative data
    @State private var narrativeResult: StreakNarrativeResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "journeyNarrative" // Updated identifier

    // Data for the 7-day habit chart (used in collapsed AND expanded view)
     private var habitData: [Bool] {
         let calendar = Calendar.current
         let today = calendar.startOfDay(for: Date())
         let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!
         let recentEntries = appState.journalEntries.filter { $0.date >= sevenDaysAgo }
         let entryDates = Set(recentEntries.map { calendar.startOfDay(for: $0.date) })

         return (0..<7).map { index -> Bool in
             let dateToCheck = calendar.date(byAdding: .day, value: -index, to: today)!
             return entryDates.contains(dateToCheck)
         }.reversed() // Reverse so today is last
     }

     // Short weekday labels for the chart (used in expanded view)
     private var weekdayLabels: [String] {
         let calendar = Calendar.current
         let today = Date()
         return (0..<7).map { index -> String in
             let date = calendar.date(byAdding: .day, value: -index, to: today)!
             let formatter = DateFormatter()
             formatter.dateFormat = "EE"
             return formatter.string(from: date)
         }.reversed()
     }

    // Use narrative text from the result, or a placeholder
    private var narrativeDisplayText: String {
        // Add explicit check for nil narrativeResult before checking snippet
        guard let result = narrativeResult else {
            if isLoading { return "Loading narrative..." }
            if loadError { return "Could not load narrative." }
            return streak > 0 ? "Analyzing your recent journey..." : "Your journey's story will appear here."
        }
        // Use narrativeText if result exists
        return result.narrativeText.isEmpty ? (streak > 0 ? "Analyzing your recent journey..." : "Your journey's story will appear here.") : result.narrativeText
    }

    // Narrative Snippet for collapsed view - WITH TRUNCATION (Reinstated)
    private var narrativeSnippetDisplay: String {
        // Add explicit check for nil narrativeResult before checking snippet
        guard let result = narrativeResult else {
            if isLoading { return "Loading..." }
            if loadError { return "Unavailable" }
            return "Your journey unfolds..." // Default when no result and not loading/error
        }
        // Use storySnippet if result exists, otherwise fallback
        let snippet = result.storySnippet.isEmpty ? "Your journey unfolds..." : result.storySnippet
        let maxLength = 120 // Define max characters for snippet
        if snippet.count > maxLength {
            return String(snippet.prefix(maxLength)) + "..."
        } else {
            return snippet
        }
    }

    // Getter for streak to use in computed properties
    private var streak: Int {
        appState.currentStreak
    }


    // UX-focused streak sub-headline
    private var streakSubHeadline: String {
        let streak = appState.currentStreak
        let hasTodayEntry = appState.hasEntryToday

        if streak > 0 {
            if hasTodayEntry {
                return "\(streak) Day Streak!"
            } else {
                return "Keep your \(streak)-day streak going!"
            }
        } else {
            return "Start a new streak today!"
        }
    }

    var body: some View {
        // Outer VStack for the entire card content + divider
        VStack(spacing: 0) {
            // Main Content Area (Header + Optional Expanded View)
            VStack(spacing: 0) { // Use spacing 0 here, manage space internally
                // --- Collapsed/Header View (Modified) ---
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) { // Increased spacing
                        Text("Keep showing up.") // Changed title text
                            .font(styles.typography.largeTitle) // Use largeTitle font size
                            .foregroundColor(styles.colors.accent) // Title uses accent color

                        // Use standard text color for streak subheadline
                         Text(streakSubHeadline)
                             .font(styles.typography.bodyFont.weight(.bold))
                             .foregroundColor(styles.colors.text) // Standard text color


                        // [3.3] Add Mini Activity Dots
                        MiniActivityDots(habitData: habitData)
                            // Add padding below dots
                            .padding(.bottom, styles.layout.spacingXS)


                        // Display loading/error state or the snippet
                        HStack {
                             if isLoading {
                                 Text("Loading...")
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary)
                                 ProgressView().scaleEffect(0.7).padding(.leading, 2)
                             } else if loadError {
                                 Text("Narrative unavailable")
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.error)
                             } else {
                                 Text(narrativeSnippetDisplay)
                                     .font(styles.typography.bodySmall)
                                     .foregroundColor(styles.colors.textSecondary) // Standard secondary text color
                                     .lineLimit(5) // Increased line limit for snippet
                                     .fixedSize(horizontal: false, vertical: true)
                             }
                             Spacer() // Push text/loader left
                        }
                         .frame(minHeight: 30) // Adjust min height for snippet
                    }
                    Spacer()
                    // REMOVED: Top-right chevron removed
                }
                .padding(.horizontal, styles.layout.paddingL)
                .padding(.vertical, styles.layout.paddingM + 4)

                // --- Expanded Content (remains the same) ---
                if isExpanded {
                    VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                        Divider().background(styles.colors.divider.opacity(0.5))

                        // Habit Chart
                        VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                            Text("Recent Activity")
                                .font(styles.typography.bodyLarge.weight(.semibold))
                                .foregroundColor(styles.colors.text)
                                .padding(.bottom, styles.layout.spacingXS)

                            HStack(spacing: styles.layout.spacingS) {
                                ForEach(0..<7) { index in
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(habitData[index] ? styles.colors.accent : styles.colors.secondaryBackground)
                                            .frame(width: 25, height: 25)
                                            .overlay(
                                                Circle().stroke(styles.colors.divider.opacity(0.5), lineWidth: 1)
                                            )
                                        Text(weekdayLabels[index])
                                            .font(styles.typography.caption)
                                            .foregroundColor(styles.colors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.top, styles.layout.paddingS)

                        // Explainer Text
                        Text("Consistency is key to building lasting habits. Celebrate your progress, one day at a time!")
                            .font(styles.typography.bodySmall)
                            .foregroundColor(styles.colors.textSecondary)
                            .padding(.vertical, styles.layout.spacingS)

                        // Narrative Text
                         VStack(alignment: .leading) {
                             Text("Highlights")
                                 .font(styles.typography.bodyLarge.weight(.semibold))
                                 .foregroundColor(styles.colors.text)
                                 .padding(.bottom, styles.layout.spacingXS)

                             if isLoading {
                                 ProgressView()
                                     .tint(styles.colors.accent)
                                     .frame(maxWidth: .infinity, alignment: .center)
                             } else {
                                 Text(narrativeDisplayText) // Use the property that includes fallbacks
                                     .font(styles.typography.bodyFont)
                                     .foregroundColor(loadError ? styles.colors.error : styles.colors.textSecondary)
                                     .frame(maxWidth: .infinity, alignment: .leading)
                                     .fixedSize(horizontal: false, vertical: true)
                             }
                         }
                         .padding(.vertical, styles.layout.spacingS)

                        // Streak Milestones
                        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                            Text("Milestones")
                                .font(styles.typography.bodyLarge.weight(.semibold))
                                .foregroundColor(styles.colors.text)

                            HStack(spacing: styles.layout.spacingL) {
                                MilestoneView(
                                    label: "7 Days",
                                    icon: "star.fill",
                                    isAchieved: appState.currentStreak >= 7,
                                    accentColor: styles.colors.accent,
                                    defaultStrokeColor: styles.colors.tertiaryAccent
                                )
                                 MilestoneView(
                                     label: "30 Days",
                                     icon: "star.fill",
                                     isAchieved: appState.currentStreak >= 30,
                                     accentColor: styles.colors.accent,
                                     defaultStrokeColor: styles.colors.tertiaryAccent
                                 )
                                 MilestoneView(
                                     label: "100 Days",
                                     icon: "star.fill",
                                     isAchieved: appState.currentStreak >= 100,
                                     accentColor: styles.colors.accent,
                                     defaultStrokeColor: styles.colors.tertiaryAccent
                                 )
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.top, styles.layout.paddingS)

                    }
                    .padding(.horizontal, styles.layout.paddingL)
                    .padding(.bottom, styles.layout.paddingM) // Add bottom padding to expanded content
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            // Container for "Show more" text and chevron button
                VStack(spacing: styles.layout.spacingXS) { // Use spacingXS between text and button
                    Text("Show more of my journey") // Updated text
                        .font(.system(size: 10, weight: .regular, design: .monospaced)) // Match nav style
                        .foregroundColor(styles.colors.accent) // Changed color to accent
                        // Removed bottom padding, rely on VStack spacing
    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 24, weight: .bold)) // Larger size
                            .foregroundColor(styles.colors.accent)
                            .rotationEffect(Angle(degrees: isExpanded ? 180 : 0))
                    }
                    .frame(maxWidth: .infinity) // Center horizontally
                }
                .padding(.top, styles.layout.paddingS) // Padding above the text/button group
                .padding(.bottom, styles.layout.paddingL + styles.layout.paddingL) // Further increased padding below button group
    
            } // End Main Content VStack
    
             // REMOVED Divider Rectangle and its padding
    
            } // End Outer VStack
            .background(styles.colors.cardBackground) // Apply background to outer VStack
        .cornerRadius(styles.layout.radiusL) // Apply corner radius to outer VStack
        .onAppear { loadInsight() }
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[JourneyCard] Received insightsDidUpdate notification.")
             loadInsight()
        }
    } // End body

    // Function to load and decode the insight (remains the same)
    private func loadInsight() {
        guard !isLoading else { return }
        isLoading = true
        loadError = false
        narrativeResult = nil
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
                }
            } catch { decodeError = error }
            await MainActor.run {
                self.narrativeResult = finalResult
                self.generatedDate = loadedDate
                self.loadError = (decodeError != nil)
                self.isLoading = false
            }
        }
    }
}

// --- Preview Struct (remains the same) ---
private struct JourneyCardPreviewWrapper: View {
    @StateObject private var mockAppState: AppState
    @StateObject private var mockAppStateNoToday: AppState
    @StateObject private var mockAppStateNoStreak: AppState
    @StateObject private static var mockUIStyles = UIStyles.shared
    @StateObject private static var mockDatabaseService = DatabaseService()
    @StateObject private static var mockThemeManager = ThemeManager.shared

    init() {
        let state1 = AppState(); let calendar = Calendar.current; let today = Date()
        state1.journalEntries = [
            JournalEntry(text: "Today entry", mood: .happy, date: today),
            JournalEntry(text: "Yesterday entry", mood: .neutral, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            JournalEntry(text: "3 days ago entry", mood: .sad, date: calendar.date(byAdding: .day, value: -3, to: today)!),
            JournalEntry(text: "5 days ago entry", mood: .content, date: calendar.date(byAdding: .day, value: -5, to: today)!)
        ]; _mockAppState = StateObject(wrappedValue: state1)
        let state2 = AppState()
        state2.journalEntries = [
            JournalEntry(text: "Yesterday entry", mood: .neutral, date: calendar.date(byAdding: .day, value: -1, to: today)!),
            JournalEntry(text: "2 days ago", mood: .sad, date: calendar.date(byAdding: .day, value: -2, to: today)!)
        ]; _mockAppStateNoToday = StateObject(wrappedValue: state2)
        let state3 = AppState(); state3.journalEntries = [ JournalEntry(text: "3 days ago", mood: .sad, date: calendar.date(byAdding: .day, value: -3, to: today)!) ]; _mockAppStateNoStreak = StateObject(wrappedValue: state3)
        let mockNarrative = StreakNarrativeResult(storySnippet: "Preview snippet loaded!", narrativeText: "This is the detailed narrative text for the preview."); let encoder = JSONEncoder()
        if let data = try? encoder.encode(mockNarrative), let jsonString = String(data: data, encoding: .utf8) {
            Task { try? await Self.mockDatabaseService.saveGeneratedInsight(type: "journeyNarrative", date: Date(), jsonData: jsonString) }
        }
    }
    var body: some View {
        ScrollView { VStack {
            JourneyInsightCard().padding().environmentObject(mockAppState).environmentObject(Self.mockDatabaseService).environmentObject(Self.mockUIStyles).environmentObject(Self.mockThemeManager)
            JourneyInsightCard().padding().environmentObject(mockAppStateNoToday).environmentObject(Self.mockDatabaseService).environmentObject(Self.mockUIStyles).environmentObject(Self.mockThemeManager)
            JourneyInsightCard().padding().environmentObject(mockAppStateNoStreak).environmentObject(Self.mockDatabaseService).environmentObject(Self.mockUIStyles).environmentObject(Self.mockThemeManager)
        }} .background(Color.gray.opacity(0.1)).preferredColorScheme(.light)
    }
}
#Preview { JourneyCardPreviewWrapper() }