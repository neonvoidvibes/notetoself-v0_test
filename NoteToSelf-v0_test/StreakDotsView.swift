import SwiftUI

struct StreakDotsView: View {
    @StateObject private var viewModel: StreakViewModel // Use StateObject for owned view model
    @ObservedObject private var styles = UIStyles.shared // Observe UIStyles
    private let dotSize: CGFloat = 28 // Size of each dot
    // Removed dotSpacing, calculated dynamically now

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: StreakViewModel(appState: appState))
    }

    private func getWeekdayLabels() -> [String] {
         let calendar = Calendar.current
         // Use shortWeekdaySymbols ("Mon", "Tue", etc.)
         let symbols = calendar.shortWeekdaySymbols
         let firstWeekdayIndex = viewModel.firstDayOfWeek - 1 // 0-based index

         // Ensure we have 7 symbols
         guard symbols.count == 7 else { return [] }

         let reorderedSymbols = Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
         // Shorten to 2 characters (e.g., "Mo", "Tu")
         return reorderedSymbols.map { String($0.prefix(2)) }
     }

    var body: some View {
        // Use GeometryReader to determine available width for precise dot placement
        GeometryReader { geometry in
             let totalWidth = geometry.size.width
             let totalSpacing = totalWidth - (7 * dotSize) // Total space available for gaps
             let calculatedSpacing = max(0, totalSpacing / 6) // Space between centers of dots

            VStack(spacing: styles.layout.spacingS) { // Space between labels and bar/dots
                // Weekday Labels - Positioned above dots
                HStack(spacing: calculatedSpacing) { // Use calculated spacing
                    ForEach(getWeekdayLabels(), id: \.self) { label in
                        Text(label)
                            .font(styles.typography.caption) // Small caption font
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(width: dotSize, height: 15, alignment: .center) // Align labels with dots
                    }
                }
                .frame(width: totalWidth) // Ensure labels HStack uses full width

                // Background Bar + Dots
                ZStack {
                    // Background Bar - Spans full width
                    RoundedRectangle(cornerRadius: dotSize / 2) // Make ends perfectly round
                        .fill(styles.colors.streakBarBackground) // Use theme color
                        .frame(height: dotSize) // Height matches dot size

                    // Layer containing Accent Bar and Dots, aligned to the leading edge
                    HStack(spacing: 0) {
                         // Accent Bar (Active Streak) - Positioned using Spacers and HStack
                         if let range = viewModel.activeStreakRangeIndices, range.count >= 1 { // Show even for 1 day (dot highlight)
                             let startDotIndex = range.lowerBound
                             let barWidth = CGFloat(range.count) * dotSize + CGFloat(max(0, range.count - 1)) * calculatedSpacing
                             let leadingSpacerWidth = CGFloat(startDotIndex) * (dotSize + calculatedSpacing)

                             // Spacer to push the accent bar to the correct starting position
                             Spacer(minLength: leadingSpacerWidth)

                             // The accent bar itself
                             RoundedRectangle(cornerRadius: dotSize / 2)
                                 .fill(styles.colors.accent) // Accent color bar
                                 .frame(width: barWidth, height: dotSize)
                                  // Animate width/position changes
                                 .animation(.easeInOut, value: viewModel.activeStreakRangeIndices)

                             // Spacer to fill the remaining space
                             Spacer(minLength: 0)
                         } else {
                              // If no active streak, add a spacer to take up full width
                              Spacer(minLength: 0)
                         }
                    }
                     .frame(width: totalWidth) // Ensure this layer takes full width for spacer calculations

                    // Dots - Positioned precisely (rendered on top of bars)
                    HStack(spacing: calculatedSpacing) { // Use calculated spacing
                        ForEach(viewModel.streakDays) { dayData in
                            DotView(
                                isFilled: dayData.isFilled,
                                isToday: dayData.isToday,
                                showGlow: dayData.isWithin24Hours // Control glow based on viewModel data
                            )
                            .frame(width: dotSize, height: dotSize) // Ensure consistent size
                        }
                    }
                    .frame(width: totalWidth) // Ensure dots HStack uses full width
                }
                .frame(height: dotSize) // Constrain ZStack height
            }
        }
        .frame(height: 15 + styles.layout.spacingS + dotSize) // Calculate total height for GeometryReader
    }
}

// Subview for a single dot
private struct DotView: View {
    let isFilled: Bool
    let isToday: Bool // To potentially highlight the current day differently if needed
    let showGlow: Bool // Whether to show the glow effect
    @ObservedObject private var styles = UIStyles.shared // Observe styles
    private let dotSize: CGFloat = 28 // Consistent size

    var body: some View {
        Circle()
             // Use accent color if filled, otherwise completely transparent
            .fill(isFilled ? styles.colors.accent : Color.clear)
            // Remove border entirely for empty dots
             .overlay(
                  Circle()
                       .strokeBorder(Color.clear, lineWidth: 0) // No border for filled or empty
              )
            .glow(radius: 15, isActive: showGlow) // Apply conditional glow modifier
    }
}

// Preview Provider
#Preview {
    // Create a mock AppState for previewing different scenarios
    let mockAppStateWithStreak = AppState()
    let calendar = Calendar.current
    let today = Date()
    mockAppStateWithStreak._journalEntries = [
        JournalEntry(text: "Entry 1", mood: .happy, date: today),
        JournalEntry(text: "Entry 2", mood: .neutral, date: calendar.date(byAdding: .day, value: -1, to: today)!),
        JournalEntry(text: "Entry 3", mood: .calm, date: calendar.date(byAdding: .day, value: -2, to: today)!)
    ]

    let mockAppStateNoStreak = AppState() // Empty entries

    let mockAppStateSimulated = AppState()
    mockAppStateSimulated.overrideStreakStartDate = true
    mockAppStateSimulated.simulatedStreakStartWeekday = 4 // Simulate streak starting on Wednesday

    return VStack(spacing: 30) {
        Text("Active Streak (3 Days)")
        StreakDotsView(appState: mockAppStateWithStreak)

        Divider()

        Text("No Streak")
        StreakDotsView(appState: mockAppStateNoStreak)

        Divider()

        Text("Simulated Streak (Starts Wednesday)")
        StreakDotsView(appState: mockAppStateSimulated)

    }
    .padding()
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared) // Ensure ThemeManager is provided
    .background(Color.gray.opacity(0.1))
}