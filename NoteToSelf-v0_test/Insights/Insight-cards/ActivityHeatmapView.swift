import SwiftUI

struct ActivityHeatmapView: View {
    // Use @ObservedObject because the ViewModel is created and owned by the parent view (JournalView)
    @ObservedObject var viewModel: ActivityHeatmapViewModel
    let onSelectEntry: (JournalEntry) -> Void // Callback when a cell with an entry is tapped

    @ObservedObject private var styles = UIStyles.shared
    @Environment(\.colorScheme) private var colorScheme // Needed for background color

    // Define columns for the grid (always 7 days)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7) // Increased spacing slightly

    // Weekday symbols helper
    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        // Use shortWeekdaySymbols ("Mon", "Tue", etc.) and take first 2 chars
        let symbols = calendar.shortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1 // 0-based index

        guard symbols.count == 7 else { return ["Mo","Tu","We","Th","Fr","Sa","Su"] } // Fallback

        let reorderedSymbols = Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
        // Shorten to 2 characters ("Mo", "Tu", etc.)
        return reorderedSymbols.map { String($0.prefix(2)) }
    }

    // Background color definition based on theme/mode
    private var cardBackgroundColor: Color {
        // Make light mode slightly darker gray
        colorScheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.19) : Color(red: 0.93, green: 0.93, blue: 0.94)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Main container for card content + button below

            // Card Content VStack
            VStack(alignment: .leading, spacing: 0) {

                // REMOVED: Narrative Snippet display from inside the card

                // Weekday Header
                HStack(spacing: 6) { // Match grid spacing
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4) // Padding to align header text with cells
                .padding(.bottom, styles.layout.spacingS) // Space between header and grid

                // Heatmap Grid
                LazyVGrid(columns: columns, spacing: 6) { // Match header spacing
                    // Use the viewModel's `visibleHeatmapData` which respects the expansion state
                    ForEach(viewModel.visibleHeatmapData) { dayInfo in
                        // Wrap cell in a Button for tap handling
                        Button {
                            if let entry = dayInfo.entry {
                                onSelectEntry(entry)
                            }
                        } label: {
                            HeatmapDayCell(dayInfo: dayInfo)
                                .id(dayInfo.date) // Use date for stable ID if needed
                        }
                        .buttonStyle(.plain) // Use plain style to allow cell's appearance
                    }
                }

                // Spacer to push button down if content is short
                 if !viewModel.isExpanded && viewModel.visibleHeatmapData.count < viewModel.totalDaysToShow {
                      Spacer(minLength: 0)
                 }

                 // REMOVED: Expand/Collapse Button HStack from here

                // --- Expanded Content ---
                if viewModel.isExpanded {
                    expandedContentView
                        .transition(.opacity.combined(with: .move(edge: .top))) // Animate appearance
                }

            }
            .padding(styles.layout.paddingM) // Padding inside the card
            .background(cardBackgroundColor) // Apply subtle gray background
            .cornerRadius(styles.layout.radiusL) // Rounded corners for the card

            // Expand/Collapse Button & Text (Outside the card background)
            VStack(spacing: styles.layout.spacingXS) {
                // Updated Text
                Text(viewModel.isExpanded ? "Close" : "Show full activity")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(styles.colors.accent)

                 Button(action: {
                     viewModel.toggleExpansion()
                 }) {
                     // Use double chevrons system names
                     Image(systemName: viewModel.isExpanded ? "chevrons.up" : "chevrons.down")
                         .font(.system(size: 18, weight: .bold)) // Keep size
                         .foregroundColor(styles.colors.accent)
                 }
                .frame(maxWidth: .infinity) // Allow button to take width for centering text above
            }
            .padding(.top, styles.layout.spacingS) // Space between card and button
            .padding(.bottom, styles.layout.paddingS) // Space below button

        } // End outer VStack
    }

    // Extracted view for the expanded content
    private var expandedContentView: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingL) { // Consistent spacing
            Divider().background(styles.colors.divider.opacity(0.5))

            // Explainer Text
            Text("Consistency is key to building lasting habits and unlocking deeper insights. Celebrate your progress, one day at a time!")
                .font(styles.typography.bodySmall)
                .foregroundColor(styles.colors.accent)
                .padding(.vertical, styles.layout.spacingS)

             // Narrative Text Section
             VStack(alignment: .leading) {
                 Text("Highlights")
                     .font(styles.typography.bodyLarge.weight(.semibold))
                     .foregroundColor(styles.colors.text)
                     .padding(.bottom, styles.layout.spacingXS)

                  Text(viewModel.narrativeDisplayText) // Use ViewModel's computed property
                     .font(styles.typography.bodyFont)
                     .foregroundColor(viewModel.loadNarrativeError ? styles.colors.error : styles.colors.textSecondary)
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .fixedSize(horizontal: false, vertical: true)
             }
             .padding(.vertical, styles.layout.spacingS)

            // Streak Milestones
            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                Text("Milestones")
                    .font(styles.typography.bodyLarge.weight(.semibold))
                    .foregroundColor(styles.colors.text)

                HStack(spacing: styles.layout.spacingL) {
                    // Use viewModel.currentStreak
                    MilestoneView(
                        label: "7 Days",
                        icon: "star.fill",
                        isAchieved: viewModel.currentStreak >= 7,
                        accentColor: styles.colors.accent,
                        defaultStrokeColor: styles.colors.tertiaryAccent
                    )
                    MilestoneView(
                        label: "30 Days",
                        icon: "star.fill",
                        isAchieved: viewModel.currentStreak >= 30,
                        accentColor: styles.colors.accent,
                        defaultStrokeColor: styles.colors.tertiaryAccent
                    )
                    MilestoneView(
                        label: "100 Days",
                        icon: "star.fill",
                        isAchieved: viewModel.currentStreak >= 100,
                        accentColor: styles.colors.accent,
                        defaultStrokeColor: styles.colors.tertiaryAccent
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, styles.layout.spacingS)

        }
        .padding(.top, styles.layout.spacingM) // Add padding above the expanded content
    }
}

#Preview {
    // Create a mock AppState for previewing
    let mockAppState = AppState()
    let mockDbService = DatabaseService() // Need DB service for view model
    let calendar = Calendar.current
    let today = Date()
    // Add some mock entries for preview
    mockAppState._journalEntries = (0..<25).compactMap { i -> JournalEntry? in
        guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
        // Make every third day have an entry for visual variety
        if i % 3 == 0 {
            return JournalEntry(text: "Entry \(i)", mood: Mood.allCases.randomElement() ?? .neutral, date: date)
        }
        return nil
    } + [JournalEntry(text: "Today", mood: .happy, date: today)] // Ensure today has an entry

    // Instantiate the ViewModel with the mock AppState and DBService
    let previewViewModel = ActivityHeatmapViewModel(appState: mockAppState, databaseService: mockDbService)

    return ActivityHeatmapView(viewModel: previewViewModel) { entry in
        print("Preview: Tapped entry from \(entry.date)")
    }
    .padding()
    .background(Color.black.opacity(0.9))
    .environmentObject(mockAppState)
    .environmentObject(mockDbService) // Provide DB service
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.dark)
}