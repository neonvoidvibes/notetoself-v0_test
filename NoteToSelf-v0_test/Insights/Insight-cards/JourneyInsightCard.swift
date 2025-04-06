import SwiftUI
import Charts // For potential future chart library use, basic shapes for now

struct JourneyInsightCard: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var styles = UIStyles.shared

    @State private var isExpanded: Bool = false

    // Data for the 7-day habit chart
    private var habitData: [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Ensure comparison includes today
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        let recentEntries = appState.journalEntries.filter { $0.date >= sevenDaysAgo }
        let entryDates = Set(recentEntries.map { calendar.startOfDay(for: $0.date) })

        return (0..<7).map { index -> Bool in
            let dateToCheck = calendar.date(byAdding: .day, value: -index, to: today)!
            return entryDates.contains(dateToCheck)
        }.reversed() // Reverse so today is last
    }


    // Short weekday labels for the chart
    private var weekdayLabels: [String] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).map { index -> String in
            let date = calendar.date(byAdding: .day, value: -index, to: today)!
            let formatter = DateFormatter()
            formatter.dateFormat = "EE" // Short weekday name (e.g., "Mon")
            return formatter.string(from: date)
        }.reversed()
    }

    var body: some View {
        VStack(spacing: 0) {
            // --- Collapsed/Header View ---
            HStack {
                VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                    Text("Journey")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.accentContrastText) // Use contrast text
                    Text("\(appState.currentStreak) Day Streak")
                        .font(styles.typography.bodyFont.weight(.bold)) // Make streak bold
                        .foregroundColor(styles.colors.secondaryAccent) // Use NEW secondary accent (yellow)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(styles.colors.accentContrastText.opacity(0.7)) // Use contrast text (slightly dimmed)
                    .rotationEffect(Angle(degrees: isExpanded ? 180 : 0))
            }
            .padding(.horizontal, styles.layout.paddingL)
            .padding(.vertical, styles.layout.paddingM)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }

            // --- Expanded Content ---
            if isExpanded {
                VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     // Use contrast divider on accent background
                    Divider().background(styles.colors.accentContrastText.opacity(0.3))

                    // Habit Chart
                    VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                        Text("Recent Activity")
                            .font(styles.typography.bodyLarge.weight(.semibold))
                            .foregroundColor(styles.colors.accentContrastText) // Use contrast text
                            .padding(.bottom, styles.layout.spacingXS)

                        HStack(spacing: styles.layout.spacingS) {
                            ForEach(0..<7) { index in
                                VStack(spacing: 4) {
                                    // Day Indicator (Circle)
                                    Circle()
                                         // Active: secondary accent (yellow), Inactive: dim contrast text
                                        .fill(habitData[index] ? styles.colors.secondaryAccent : styles.colors.accentContrastText.opacity(0.3))
                                        .frame(width: 25, height: 25)
                                        .overlay(
                                            // Border using contrast text (dim)
                                            Circle().stroke(styles.colors.accentContrastText.opacity(0.5), lineWidth: 1)
                                        )

                                    // Weekday Label
                                    Text(weekdayLabels[index])
                                        .font(styles.typography.caption)
                                        .foregroundColor(styles.colors.accentContrastText.opacity(0.7)) // Use contrast text (dim)
                                }
                                .frame(maxWidth: .infinity) // Distribute space
                            }
                        }
                    }
                    .padding(.top, styles.layout.paddingS)

                    // Explainer Text
                    Text("Consistency is key to building lasting habits. Celebrate your progress, one day at a time!")
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.accentContrastText.opacity(0.8)) // Use contrast text (slightly dimmed)
                        .padding(.top, styles.layout.spacingS)

                }
                .padding(.horizontal, styles.layout.paddingL)
                .padding(.bottom, styles.layout.paddingM)
                .transition(.opacity.combined(with: .move(edge: .top))) // Smooth transition
            }
        }
        .background(styles.colors.accent) // Use ACCENT color for background
        .cornerRadius(styles.layout.radiusL)
        // Apply thick border using SECONDARY accent
        .overlay(
            RoundedRectangle(cornerRadius: styles.layout.radiusL)
                .stroke(styles.colors.secondaryAccent, lineWidth: 2) // Use NEW secondary accent (yellow) for border
        )
        // No shadow
    }
}

#Preview {
    // Create mock AppState with some entries for preview
    let mockAppState = AppState()
    let calendar = Calendar.current
    let today = Date()
    mockAppState.journalEntries = [
        JournalEntry(text: "Today entry", mood: .happy, date: today),
        JournalEntry(text: "Yesterday entry", mood: .neutral, date: calendar.date(byAdding: .day, value: -1, to: today)!),
        JournalEntry(text: "3 days ago entry", mood: .sad, date: calendar.date(byAdding: .day, value: -3, to: today)!),
        JournalEntry(text: "5 days ago entry", mood: .content, date: calendar.date(byAdding: .day, value: -5, to: today)!)
    ]

    return ScrollView {
        JourneyInsightCard()
            .padding()
            .environmentObject(mockAppState)
            .environmentObject(UIStyles.shared)
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
}