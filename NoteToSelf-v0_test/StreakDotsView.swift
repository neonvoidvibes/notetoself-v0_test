import SwiftUI

struct StreakDotsView: View {
    @StateObject private var viewModel: StreakViewModel // Use StateObject for owned view model
    @ObservedObject private var styles = UIStyles.shared // Observe UIStyles
    private let dotSize: CGFloat = 28 // Size of each dot
    private let dotSpacing: CGFloat = 8 // Spacing between dots

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: StreakViewModel(appState: appState))
    }

    private var weekdayLabels: [String] {
        let calendar = Calendar.current
        // Use veryShortWeekdaySymbols which are locale-aware ("S", "M", "T" etc.)
        // Reorder based on firstDayOfWeek
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekdayIndex = viewModel.firstDayOfWeek - 1 // 0-based index
        let reorderedSymbols = Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
        return reorderedSymbols
    }

    var body: some View {
        VStack(spacing: styles.layout.spacingS) { // Space between labels and bar/dots
            // Weekday Labels
            HStack(spacing: dotSpacing) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(styles.typography.caption) // Small caption font
                        .foregroundColor(styles.styles.colors.textSecondary)
                        .frame(width: dotSize, height: 15, alignment: .center) // Align labels with dots
                }
            }

            // Background Bar + Dots
            ZStack {
                // Background Bar
                RoundedRectangle(cornerRadius: dotSize / 2) // Make ends perfectly round
                    .fill(styles.styles.colors.streakBarBackground) // Use theme color
                    .frame(height: dotSize) // Height matches dot size

                // Dots
                HStack(spacing: dotSpacing) {
                    ForEach(viewModel.streakDays) { dayData in
                        DotView(
                            isFilled: dayData.isFilled,
                            isToday: dayData.isToday,
                            showGlow: dayData.isWithin24Hours // Control glow based on viewModel data
                        )
                        .frame(width: dotSize, height: dotSize) // Ensure consistent size
                    }
                }
            }
            .frame(height: dotSize) // Constrain ZStack height
        }
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
            .fill(isFilled ? styles.styles.colors.accent : Color.clear) // Fill if filled, clear otherwise
            .overlay(
                // Show border ONLY if NOT filled
                Circle()
                    .strokeBorder(styles.styles.colors.divider, lineWidth: isFilled ? 0 : 1.5) // Thicker border for empty
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