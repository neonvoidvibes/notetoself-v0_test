import SwiftUI
import Charts // For potential future chart library use, basic shapes for now

struct JourneyInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService
    @ObservedObject private var styles = UIStyles.shared

    @State private var isExpanded: Bool = false
    // State for narrative data
    @State private var narrativeResult: StreakNarrativeResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    private let insightTypeIdentifier = "streakNarrative" // Matches generator

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
                        .foregroundColor(styles.colors.journeyCardTextPrimary) // Use inverted primary text
                    Text("\(appState.currentStreak) Day Streak")
                        .font(styles.typography.bodyFont.weight(.bold)) // Make streak bold
                        .foregroundColor(styles.colors.journeyCardTextSecondary) // Use inverted secondary text
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(styles.colors.accentContrastText.opacity(0.7)) // Use contrast text (slightly dimmed for chevron)
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

                    // Narrative Text
                     VStack(alignment: .leading) {
                         if isLoading {
                             ProgressView()
                                 .tint(styles.colors.accentContrastText.opacity(0.8)) // Contrast progress view
                                 .frame(maxWidth: .infinity, alignment: .center)
                         } else {
                             Text(narrativeDisplayText)
                                 .font(styles.typography.bodyFont)
                                  // Use inverted secondary text for narrative
                                 .foregroundColor(loadError ? styles.colors.error : styles.colors.journeyCardTextSecondary)
                                 .frame(maxWidth: .infinity, alignment: .leading)
                                 .fixedSize(horizontal: false, vertical: true) // Allow wrapping
                         }
                     }
                     .padding(.vertical, styles.layout.spacingS) // Add padding around text/loader

                    // Streak Milestones using new MilestoneView
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("Milestones")
                            .font(styles.typography.bodyLarge.weight(.semibold))
                            .foregroundColor(styles.colors.journeyCardTextPrimary) // Use inverted primary text

                        HStack(spacing: styles.layout.spacingL) {
                            // Use the new MilestoneView
                            MilestoneView(
                                label: "7 Days",
                                icon: "star.fill",
                                isAchieved: appState.currentStreak >= 7,
                                achievedColor: styles.colors.journeyCardTextPrimary, // Use inverted primary
                                defaultColor: styles.colors.journeyCardTextSecondary // Use inverted secondary
                            )
                             MilestoneView(
                                 label: "30 Days",
                                 icon: "star.fill",
                                 isAchieved: appState.currentStreak >= 30,
                                 achievedColor: styles.colors.journeyCardTextPrimary,
                                 defaultColor: styles.colors.journeyCardTextSecondary
                             )
                             MilestoneView(
                                 label: "100 Days",
                                 icon: "star.fill",
                                 isAchieved: appState.currentStreak >= 100,
                                 achievedColor: styles.colors.journeyCardTextPrimary,
                                 defaultColor: styles.colors.journeyCardTextSecondary
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
        .background(styles.colors.accent) // Use ACCENT color for background
        .cornerRadius(styles.layout.radiusL)
        // Apply thick border using ACCENT color (same as background)
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

    // Define mock colors for preview if JourneyCardTextPrimary/Secondary are not in Assets yet
    let mockUIStyles = UIStyles.shared
    // If you haven't added the colors to Assets, uncomment and modify these lines for preview:
    // mockUIStyles.currentTheme.colors.journeyCardTextPrimary = Color.black // Example for light mode preview
    // mockUIStyles.currentTheme.colors.journeyCardTextSecondary = Color.gray // Example for light mode preview

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
    // .preferredColorScheme(.light) // Uncomment to test light mode specifically
     .preferredColorScheme(.dark) // Uncomment to test dark mode specifically
}