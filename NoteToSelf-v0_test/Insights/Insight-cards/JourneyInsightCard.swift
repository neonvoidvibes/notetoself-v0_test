import SwiftUI

struct JourneyInsightCard: View {
    @EnvironmentObject var appState: AppState
    // REMOVED: @EnvironmentObject var databaseService: DatabaseService
    @ObservedObject private var styles = UIStyles.shared

    @State private var isExpanded: Bool = false
    // REMOVED: Narrative state, now handled by generator/view model if needed

    // Use the StreakViewModel to get data
    // Note: Initialize here or pass from parent if needed elsewhere
    @StateObject private var streakViewModel: StreakViewModel

    init() {
        // Initialize the ViewModel here, passing the AppState
        _streakViewModel = StateObject(wrappedValue: StreakViewModel(appState: AppState.shared)) // Assuming AppState is accessible like this or via Environment
    }

    // UX-focused streak sub-headline (Using ViewModel's streak)
    private var streakSubHeadline: String {
        let streak = streakViewModel.currentStreak
        let hasTodayEntry = appState.hasEntryToday // Keep using AppState directly for hasEntryToday check

        if streak > 0 {
            if hasTodayEntry {
                return "\(streak) Day Streak!"
            } else {
                // Provide encouraging message if streak exists but no entry today
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
                // --- Collapsed/Header View ---
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) { // Increased spacing
                        Text("Keep showing up.") // Main title
                            .font(styles.typography.largeTitle)
                            .foregroundColor(styles.colors.accent)

                        // --- Conditionally Show Streak Info ---
                        if streakViewModel.currentStreak > 0 {
                            // New StreakDotsView (Replaces MiniActivityDots)
                             StreakDotsView(appState: appState) // Pass AppState if needed by view model
                                 .padding(.bottom, styles.layout.spacingXS)

                            // Streak Headline (Moved Below Dots)
                             Text(streakSubHeadline)
                                 .font(styles.typography.bodyFont.weight(.bold))
                                 .foregroundColor(styles.colors.text)
                                 .padding(.top, styles.layout.spacingS) // Add space above headline

                        } else {
                             // Placeholder or message when no streak
                             Text("Start a new streak today!")
                                .font(styles.typography.bodyFont.weight(.semibold))
                                .foregroundColor(styles.colors.textSecondary)
                                .padding(.vertical, styles.layout.spacingL) // Add padding to maintain layout roughly
                        }
                         // REMOVED: Narrative snippet from collapsed view
                    }
                    Spacer()
                }
                .padding(.horizontal, styles.layout.paddingL)
                .padding(.vertical, styles.layout.paddingM + 4)

                // --- Expanded Content ---
                if isExpanded {
                    VStack(alignment: .leading, spacing: styles.layout.spacingL) {
                        Divider().background(styles.colors.divider.opacity(0.5))

                        // Explainer Text (Now accent color)
                        Text("Consistency is key to building lasting habits and unlocking deeper insights. Celebrate your progress, one day at a time!")
                            .font(styles.typography.bodySmall)
                            .foregroundColor(styles.colors.accent) // USE ACCENT COLOR
                            .padding(.vertical, styles.layout.spacingS)

                         // REMOVED: Large dots/chart section (now handled by StreakDotsView above)
                         // REMOVED: "Recent Activity" header

                        // REMOVED: Narrative Text Section (No longer displayed directly here)

                        // Streak Milestones
                        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                            Text("Milestones")
                                .font(styles.typography.bodyLarge.weight(.semibold))
                                .foregroundColor(styles.colors.text)

                            HStack(spacing: styles.layout.spacingL) {
                                MilestoneView(
                                    label: "7 Days",
                                    icon: "star.fill",
                                    isAchieved: streakViewModel.currentStreak >= 7,
                                    accentColor: styles.styles.colors.accent,
                                    defaultStrokeColor: styles.styles.colors.tertiaryAccent
                                )
                                 MilestoneView(
                                     label: "30 Days",
                                     icon: "star.fill",
                                     isAchieved: streakViewModel.currentStreak >= 30,
                                     accentColor: styles.styles.colors.accent,
                                     defaultStrokeColor: styles.styles.colors.tertiaryAccent
                                 )
                                 MilestoneView(
                                     label: "100 Days",
                                     icon: "star.fill",
                                     isAchieved: streakViewModel.currentStreak >= 100,
                                     accentColor: styles.styles.colors.accent,
                                     defaultStrokeColor: styles.styles.colors.tertiaryAccent
                                 )
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.top, styles.layout.spacingS)

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

        } // End Outer VStack
        .background(styles.styles.colors.cardBackground) // Apply background to outer VStack
        .cornerRadius(styles.layout.radiusL) // Apply corner radius to outer VStack
         // Removed .onAppear / .onReceive for narrative loading
    } // End body
}

// Preview Struct - Needs update to work with ViewModel
#Preview {
    // Provide a shared AppState instance for the ViewModel inside the preview
    let previewAppState = AppState()
    // Add some mock entries for streak calculation
    let calendar = Calendar.current
    let today = Date()
    previewAppState._journalEntries = [
        JournalEntry(text: "Today entry", mood: .happy, date: today),
        JournalEntry(text: "Yesterday entry", mood: .neutral, date: calendar.date(byAdding: .day, value: -1, to: today)!),
    ]

    return ScrollView {
        JourneyInsightCard() // ViewModel initializes itself using AppState.shared (or injected)
            .padding()
    }
    .environmentObject(previewAppState) // Provide the mock AppState
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}