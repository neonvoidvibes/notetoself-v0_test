import SwiftUI

struct JourneyInsightCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService // Re-inject DatabaseService for narrative loading
    @ObservedObject private var styles = UIStyles.shared

    @State private var isExpanded: Bool = false

    // Use the StreakViewModel to get data
    // ViewModel now depends on AppState, which is an EnvironmentObject
    // We need to initialize it using the environment object.
    // Since @StateObject initialization happens before environment objects are available,
    // we'll pass AppState in the initializer.
    @StateObject private var streakViewModel: StreakViewModel

    // Re-add state for narrative
    @State private var narrativeResult: StreakNarrativeResult? = nil
    @State private var generatedDate: Date? = nil
    @State private var isLoadingNarrative: Bool = false
    @State private var loadNarrativeError: Bool = false
    private let insightTypeIdentifier = "journeyNarrative"

    // Initialize with AppState provided by the parent view (JournalView)
     init(appState: AppState) {
         _streakViewModel = StateObject(wrappedValue: StreakViewModel(appState: appState))
     }

    // Re-add computed property for display text, handling loading/error states
    private var narrativeDisplayText: String {
         if isLoadingNarrative { return "Loading narrative..." }
         if loadNarrativeError { return "Could not load narrative." }
         guard let result = narrativeResult, !result.narrativeText.isEmpty else {
             return streakViewModel.currentStreak > 0 ? "Analyzing your recent journey..." : "Your journey's story will appear here."
         }
         return result.narrativeText
    }

     // Re-add Narrative Snippet for collapsed view - WITH TRUNCATION & loading/error state
     private var narrativeSnippetDisplay: String {
         if isLoadingNarrative { return "Loading..." }
         if loadNarrativeError { return "Narrative unavailable" }
         guard let result = narrativeResult else {
             return "Your journey unfolds..." // Default when no result
         }
         // Use storySnippet if result exists, otherwise fallback
         let snippet = result.storySnippet.isEmpty ? "Your journey unfolds..." : result.storySnippet
         let maxLength = 100 // Slightly shorter max length for collapsed view
         if snippet.count > maxLength {
             return String(snippet.prefix(maxLength)) + "..."
         } else {
             return snippet
         }
     }

     // REMOVED: streakSubHeadline computed property (moved to JournalView)

    var body: some View {
        // Outer VStack for the entire card content + divider
        VStack(spacing: 0) {
            // Main Content Area (Header + Optional Expanded View)
            VStack(spacing: 0) { // Use spacing 0 here, manage space internally
                // --- Collapsed/Header View ---
                // REMOVED: "Keep showing up." title was moved to JournalView
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) { // Increased spacing

                        // --- Conditionally Show Streak Info ---
                        if streakViewModel.currentStreak > 0 {

                            // Re-add Narrative Snippet Display (Now between title and dots)
                            Text(narrativeSnippetDisplay) // Use the property that handles loading/error
                                .font(styles.typography.bodySmall)
                                .foregroundColor(loadNarrativeError ? styles.colors.error : styles.colors.textSecondary) // Use error color if loading failed
                                .lineLimit(5) // Increased line limit to 5
                                // REMOVED: .fixedSize(horizontal: false, vertical: true) - Let layout handle expansion
                                .padding(.bottom, styles.layout.spacingS) // Space below snippet


                            // New StreakDotsView
                            StreakDotsView(appState: appState) // Pass AppState

                        } else {
                             // Placeholder or message when no streak
                             Text("Start a new streak today!")
                                .font(styles.typography.bodyFont.weight(.semibold))
                                .foregroundColor(styles.colors.textSecondary)
                                .padding(.vertical, styles.layout.spacingL) // Add padding to maintain layout roughly
                        }
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

                         // RESTORED: Narrative Text Section
                         VStack(alignment: .leading) {
                             Text("Highlights")
                                 .font(styles.typography.bodyLarge.weight(.semibold))
                                 .foregroundColor(styles.colors.text)
                                 .padding(.bottom, styles.layout.spacingXS)

                              // Use the narrativeDisplayText property
                              Text(narrativeDisplayText)
                                 .font(styles.typography.bodyFont)
                                 // Use error color if loading failed
                                 .foregroundColor(loadNarrativeError ? styles.colors.error : styles.colors.textSecondary)
                                 .frame(maxWidth: .infinity, alignment: .leading)
                                 .fixedSize(horizontal: false, vertical: true)

                         }
                         .padding(.vertical, styles.layout.spacingS)
                         // --- End Restored Narrative Text ---

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
                                    accentColor: styles.colors.accent, // Corrected: styles.colors
                                    defaultStrokeColor: styles.colors.tertiaryAccent // Corrected: styles.colors
                                )
                                 MilestoneView(
                                     label: "30 Days",
                                     icon: "star.fill",
                                     isAchieved: streakViewModel.currentStreak >= 30,
                                     accentColor: styles.colors.accent, // Corrected: styles.colors
                                     defaultStrokeColor: styles.colors.tertiaryAccent // Corrected: styles.colors
                                 )
                                 MilestoneView(
                                     label: "100 Days",
                                     icon: "star.fill",
                                     isAchieved: streakViewModel.currentStreak >= 100,
                                     accentColor: styles.colors.accent, // Corrected: styles.colors
                                     defaultStrokeColor: styles.colors.tertiaryAccent // Corrected: styles.colors
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

                // Container for "Show more" / "Close" text and chevron button
                VStack(spacing: styles.layout.spacingXS) { // Use spacingXS between text and button
                    Text(isExpanded ? "Close" : "Show more of my journey") // Conditional text
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
        .background(styles.colors.cardBackground) // Corrected: styles.colors
        .cornerRadius(styles.layout.radiusL) // Apply corner radius to outer VStack
        // Re-add triggers for loading narrative
        .onAppear(perform: loadNarrative)
        .onReceive(NotificationCenter.default.publisher(for: .insightsDidUpdate)) { _ in
             print("[JourneyCard] Received insightsDidUpdate notification.")
             loadNarrative()
        }
    } // End body

     // Re-add function to load and decode the insight
     private func loadNarrative() {
         guard !isLoadingNarrative else { return }
         isLoadingNarrative = true
         loadNarrativeError = false
         narrativeResult = nil // Clear previous result
         print("[JourneyCard] Loading narrative insight...")
         Task {
             var loadedDate: Date? = nil
             var decodeError: Error? = nil
             var finalResult: StreakNarrativeResult? = nil
             do {
                 // Use injected databaseService
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
             // Update state on main thread
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

// Preview Struct - Updated to pass AppState
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

    // Inject DatabaseService for narrative loading in preview
    let previewDbService = DatabaseService()
    // Optionally pre-populate narrative for preview if needed
    // Task { try? await previewDbService.saveGeneratedInsight(...) }

    return ScrollView {
        // Pass the AppState instance during initialization
        JourneyInsightCard(appState: previewAppState)
            .padding()
    }
    .environmentObject(previewAppState) // Still provide AppState for other potential dependencies
    .environmentObject(previewDbService) // Provide DatabaseService
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}