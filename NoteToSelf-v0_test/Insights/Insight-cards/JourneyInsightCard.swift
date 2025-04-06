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
    private let insightTypeIdentifier = "streakNarrative" // Matches generator

    // Data for the 7-day habit chart (used in expanded view)
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
        if isLoading { return "Loading narrative..."}
        if loadError { return "Could not load narrative."}
        return narrativeResult?.narrativeText ?? (appState.currentStreak > 0 ? "Analyzing your recent journey..." : "Your journey's story will appear here.")
    }

    var body: some View {
        VStack(spacing: 0) {
            // --- Collapsed/Header View ---
            HStack {
                VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                    Text("Journey")
                        .font(styles.typography.title3)
                        .foregroundColor(styles.colors.text) // Standard text color
                    Text("\(appState.currentStreak) Day Streak")
                        .font(styles.typography.bodyFont.weight(.bold)) // Make streak bold
                         // Conditional color: Accent in light, SecondaryAccent (yellow) in dark
                        .foregroundColor(colorScheme == .light ? styles.colors.accent : styles.colors.secondaryAccent)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(styles.colors.tertiaryAccent) // Use gray tertiary accent
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
                VStack(alignment: .leading, spacing: styles.layout.spacingL) { // Increased spacing
                    Divider().background(styles.colors.divider.opacity(0.5))

                    // Habit Chart (Restored)
                    VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                        Text("Recent Activity")
                            .font(styles.typography.bodyLarge.weight(.semibold))
                            .foregroundColor(styles.colors.text) // Standard text
                            .padding(.bottom, styles.layout.spacingXS)

                        HStack(spacing: styles.layout.spacingS) {
                            ForEach(0..<7) { index in
                                VStack(spacing: 4) {
                                    Circle()
                                         // Accent for active, secondary bg for inactive
                                        .fill(habitData[index] ? styles.colors.accent : styles.colors.secondaryBackground)
                                        .frame(width: 25, height: 25)
                                        .overlay(
                                            Circle().stroke(styles.colors.divider.opacity(0.5), lineWidth: 1)
                                        )
                                    Text(weekdayLabels[index])
                                        .font(styles.typography.caption)
                                        .foregroundColor(styles.colors.textSecondary) // Standard secondary text
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.top, styles.layout.paddingS)

                    // Explainer Text (Restored)
                    Text("Consistency is key to building lasting habits. Celebrate your progress, one day at a time!")
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.textSecondary) // Standard secondary text
                        .padding(.vertical, styles.layout.spacingS) // Padding around explainer

                    // Narrative Text
                     VStack(alignment: .leading) {
                         Text("Highlights")
                             .font(styles.typography.bodyLarge.weight(.semibold))
                             .foregroundColor(styles.colors.text) // Standard text
                             .padding(.bottom, styles.layout.spacingXS)

                         if isLoading {
                             ProgressView()
                                 .tint(styles.colors.accent) // Standard accent tint
                                 .frame(maxWidth: .infinity, alignment: .center)
                         } else {
                             Text(narrativeDisplayText)
                                 .font(styles.typography.bodyFont)
                                  // Standard secondary text
                                 .foregroundColor(loadError ? styles.colors.error : styles.colors.textSecondary)
                                 .frame(maxWidth: .infinity, alignment: .leading)
                                 .fixedSize(horizontal: false, vertical: true) // Allow wrapping
                         }
                     }
                     .padding(.vertical, styles.layout.spacingS) // Add padding around text/loader

                    // Streak Milestones using new MilestoneView
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Milestones")
                            .font(styles.typography.bodyLarge.weight(.semibold))
                            .foregroundColor(styles.colors.text) // Standard text

                        HStack(spacing: styles.layout.spacingL) {
                            // Use the new MilestoneView, pass standard theme colors
                            MilestoneView(
                                label: "7 Days",
                                icon: "star.fill",
                                isAchieved: appState.currentStreak >= 7,
                                accentColor: styles.colors.accent, // Achieved uses accent
                                defaultStrokeColor: styles.colors.tertiaryAccent // Default uses gray
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
                        .frame(maxWidth: .infinity, alignment: .center) // Center milestones
                    }
                    .padding(.top, styles.layout.spacingS)

                }
                .padding(.horizontal, styles.layout.paddingL)
                .padding(.bottom, styles.layout.paddingM)
                .transition(.opacity.combined(with: .move(edge: .top))) // Smooth transition
            }
        }
        .background(styles.colors.cardBackground) // Use STANDARD card background
        .cornerRadius(styles.layout.radiusL)
        // Apply thick border using ACCENT color
        .overlay(
            RoundedRectangle(cornerRadius: styles.layout.radiusL)
                .stroke(styles.colors.accent, lineWidth: 2) // Use accent color for border
        )
        // No shadow
        .onAppear { loadInsight() }
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[JourneyCard] Received insightsDidUpdate notification.")
             loadInsight()
        }
    }

    // Function to load and decode the insight
    private func loadInsight() {
        // Avoid concurrent loads
        guard !isLoading else { return }
        isLoading = true
        loadError = false
        print("[JourneyCard] Loading narrative insight...")

        Task {
            do {
                 // Fetch latest insight synchronously (as DatabaseService method is currently sync)
                if let (json, date) = try databaseService.loadLatestInsight(type: insightTypeIdentifier) { // Capture date
                    if let data = json.data(using: .utf8) {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(StreakNarrativeResult.self, from: data)
                        await MainActor.run {
                            narrativeResult = result
                            generatedDate = date // Store date
                            isLoading = false
                             print("[JourneyCard] Narrative insight loaded and decoded.")
                        }
                    } else {
                        throw NSError(domain: "JourneyCard", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to Data"])
                    }
                } else {
                    // No insight found in DB
                     await MainActor.run {
                         narrativeResult = nil // Ensure it's nil if not found
                         generatedDate = nil // Clear date
                         isLoading = false
                         print("[JourneyCard] No stored narrative insight found.")
                     }
                }
            } catch {
                 await MainActor.run {
                     print("‼️ [JourneyCard] Failed to load/decode narrative insight: \(error)")
                     narrativeResult = nil // Clear result on error
                     generatedDate = nil // Clear date
                     loadError = true
                     isLoading = false
                 }
            }
        }
    }
}

// Removed fileprivate StreakMilestone struct

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

    let mockUIStyles = UIStyles.shared

    return ScrollView {
        JourneyInsightCard()
            .padding()
            .environmentObject(mockAppState)
            .environmentObject(DatabaseService()) // Add DB Service
            .environmentObject(mockUIStyles) // Use potentially modified styles
            .environmentObject(ThemeManager.shared)
    }
    .background(Color.gray.opacity(0.1))
    // Preview in both light and dark modes
    .preferredColorScheme(.light) // Test light mode specifically
    // .preferredColorScheme(.dark) // Test dark mode specifically
}