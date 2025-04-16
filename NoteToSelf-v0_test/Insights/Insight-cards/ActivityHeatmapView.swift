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
        colorScheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.19) : Color(red: 0.96, green: 0.96, blue: 0.97) // Subtle gray
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Use spacing 0 for precise control

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

            // Expand/Collapse Button (aligned to center)
            HStack {
                Spacer()
                Button {
                    viewModel.toggleExpansion()
                } label: {
                    Image(systemName: viewModel.isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(styles.colors.accent)
                        .padding(8)
                }
                Spacer()
            }
            .padding(.top, styles.layout.spacingS) // Space above button

        }
        .padding(styles.layout.paddingM) // Padding inside the card
        .background(cardBackgroundColor) // Apply subtle gray background
        .cornerRadius(styles.layout.radiusL) // Rounded corners for the card
    }
}

#Preview {
    // Create a mock AppState for previewing
    let mockAppState = AppState()
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

    // Instantiate the ViewModel with the mock AppState
    let previewViewModel = ActivityHeatmapViewModel(appState: mockAppState)

    return ActivityHeatmapView(viewModel: previewViewModel) { entry in
        print("Preview: Tapped entry from \(entry.date)")
    }
    .padding()
    .background(Color.black.opacity(0.9))
    .environmentObject(mockAppState)
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.dark)
}