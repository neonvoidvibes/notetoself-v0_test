import SwiftUI

struct JournalView: View {
    // Environment Objects
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    // Environment Variables
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled

    // View State
    @State private var showingNewEntrySheet = false // Reinstated local state
    @State private var editingEntry: JournalEntry? = nil
    @State private var fullscreenEntry: JournalEntry? = nil

    // Tab Bar State (Bindings)
    @Binding var tabBarOffset: CGFloat
    @Binding var lastScrollPosition: CGFloat
    @Binding var tabBarVisible: Bool

    // Filter State
    @State private var showingFilterPanel = false
    @State private var searchText = ""
    @State private var searchTags: [String] = []
    @State private var selectedMoods: Set<Mood> = []
    @State private var dateFilterType: DateFilterType = .all
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()

    // Header animation state
    @State private var headerAppeared = false

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    // Computed property to filter the journal entries
    private var filteredEntries: [JournalEntry] {
        // Rely on appState.journalEntries being sorted descending by date
        return appState.journalEntries.filtered(
            by: searchTags,
            moods: selectedMoods,
            dateFilter: dateFilterType,
            customStartDate: customStartDate,
            customEndDate: customEndDate
        )
    }

    // Grouped entries for list display
    private var groupedEntries: [(String, [JournalEntry])] {
        JournalDateGrouping.groupEntriesByTimePeriod(filteredEntries)
    }


    // Function to clear filters
    private func clearFilters(closePanel: Bool = false) {
        searchText = ""
        searchTags = []
        selectedMoods = []
        dateFilterType = .all

        if closePanel {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingFilterPanel = false
            }
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                filterPanelView
                 // Remove ScrollViewReader and related logic
                 journalContent() // Call without proxy
                 // onChange for scrolling removed as proxy is gone
            }

            floatingAddButton // Extracted floating button (action now sets AppState flag)

            // Entry Preview Popup Overlay
            if showingEntryPreview, let entry = entryForPreview {
                 EntryPreviewPopupView(entry: entry, isPresented: $showingEntryPreview) {
                     // Action for the "Expand" button in the popup
                     showingEntryPreview = false
                     // Use DispatchQueue to ensure state change happens after dismissal animation starts
                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                         fullscreenEntry = entry // Trigger fullscreen view
                     }
                 }
                 .transition(.scale(scale: 0.9).combined(with: .opacity))
                 .zIndex(10) // Ensure popup is on top
             }

        } // End ZStack
        .environment(\.isPreviewPopupPresented, showingEntryPreview) // Set environment key
        .onAppear { // Trigger animation when view appears
            // Use DispatchQueue to delay slightly if needed for visual effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                headerAppeared = true
            }
        }
        // Reinstate sheet presentation here
         .fullScreenCover(isPresented: $showingNewEntrySheet) {
              EditableFullscreenEntryView(
                  initialMood: .neutral,
                  onSave: { text, mood, intensity in
                      let newEntry = JournalEntry(text: text, mood: mood, date: Date(), intensity: intensity)
                      Task {
                          let embeddingVector = await generateEmbedding(for: newEntry.text)
                          do {
                              try databaseService.saveJournalEntry(newEntry, embedding: embeddingVector)
                              await MainActor.run {
                                   // Update the underlying storage directly
                                   appState._journalEntries.insert(newEntry, at: 0)
                                   appState._journalEntries.sort { $0.date > $1.date } // Keep sorted
                                   // Update the expanded ID using the computed property accessor (which handles simulation)
                                   withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                       appState.journalExpandedEntryId = newEntry.id // Expand new entry by default using AppState
                                   }
                                   // Manually trigger objectWillChange if needed for immediate UI update when simulating
                                   // if appState.simulateEmptyState { appState.objectWillChange.send() }

                              }
                              // Call global trigger function
                              await triggerAllInsightGenerations(llmService: LLMService.shared, databaseService: databaseService, appState: appState)
                          } catch {
                              print("‼️ Error saving new journal entry \(newEntry.id) to DB: \(error)")
                          }
                      }
                      // Sheet dismisses automatically on completion
                  },
                  onCancel: {
                      print("[JournalView] New entry sheet cancelled.")
                      // No need to switch tabs, already on Journal
                  },
                  autoFocusText: true
              )
         }
        .fullScreenCover(item: $fullscreenEntry) { entry in
            FullscreenEntryView(
                entry: entry,
                onEdit: {
                    fullscreenEntry = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { editingEntry = entry }
                },
                onDelete: { deleteEntry(entry) }
            )
        }
        .fullScreenCover(item: $editingEntry) { entryToEdit in
            EditableFullscreenEntryView(
                entry: entryToEdit,
                onSave: { updatedText, updatedMood, updatedIntensity in
                     // Create a new entry instance with updated values
                     let updatedEntry = JournalEntry(
                        id: entryToEdit.id, // Keep original ID
                        text: updatedText,
                        mood: updatedMood,
                        date: entryToEdit.date, // Keep original date
                        intensity: updatedIntensity,
                        isStarred: entryToEdit.isStarred // Preserve starred status
                     )
                    Task {
                         let embeddingVector = await generateEmbedding(for: updatedEntry.text)
                        do {
                            try databaseService.saveJournalEntry(updatedEntry, embedding: embeddingVector)
                            await MainActor.run { updateEntryInAppState(updatedEntry) }
                            // Call global trigger function
                            await triggerAllInsightGenerations(llmService: LLMService.shared, databaseService: databaseService, appState: appState)
                        } catch {
                            print("‼️ Error updating journal entry \(updatedEntry.id) in DB: \(error)")
                        }
                    }
                },
                onDelete: { deleteEntry(entryToEdit) },
                 onCancel: {
                     print("[JournalView] Edit entry sheet cancelled.")
                 },
                autoFocusText: true
            )
        }
        .onChange(of: appState.journalEntries) { _, newEntries in
             // If nothing is expanded in AppState and entries load, expand the first one.
             if appState.journalExpandedEntryId == nil, let firstEntry = newEntries.first {
                 appState.journalExpandedEntryId = firstEntry.id
                 print("onChange(entries): Set initial appState.journalExpandedEntryId to \(firstEntry.id)")
             }
             // If the currently expanded entry is no longer in the list (e.g., deleted), reset.
             else if let currentId = appState.journalExpandedEntryId, !newEntries.contains(where: { $0.id == currentId }) {
                  appState.journalExpandedEntryId = newEntries.first?.id // Expand the new first one, or nil if empty
                  print("onChange(entries): Previously expanded entry gone. Set appState.journalExpandedEntryId to \(newEntries.first?.id.uuidString ?? "nil").")
             }
        }
        .onChange(of: showingFilterPanel) { _, isShowing in
             if !isShowing { // When filter panel is closed
                 // Re-evaluate default expansion based on current filters
                 if appState.journalExpandedEntryId == nil || (appState.journalExpandedEntryId != nil && !filteredEntries.contains(where: { $0.id == appState.journalExpandedEntryId })) {
                     appState.journalExpandedEntryId = filteredEntries.first?.id
                     print("onChange(showingFilterPanel=false): Set appState.journalExpandedEntryId to \(filteredEntries.first?.id.uuidString ?? "nil").")
                 }
             }
        }
        // Reinstate onChange for triggering sheet presentation
         .onChange(of: appState.presentNewJournalEntrySheet) { _, shouldPresent in
              if shouldPresent {
                  print("[JournalView] Detected presentNewJournalEntrySheet = true") // Debug Print
                  showingNewEntrySheet = true
                  // Reset the flag immediately after triggering the presentation
                  appState.presentNewJournalEntrySheet = false
                  print("[JournalView] Set showingNewEntrySheet = true, reset AppState flag.") // Debug Print
              }
          }
         // Scroll logic moved inside ScrollViewReader in body.
     } // End Body


    // MARK: - Computed View Properties

    private var headerView: some View {
        ZStack(alignment: .center) {
            // Title truly centered
            VStack(spacing: 8) {
                Text("Journal")
                    .font(styles.typography.title1)
                    .foregroundColor(styles.colors.text)

                // Animated accent bar
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                styles.colors.accent.opacity(0.7),
                                styles.colors.accent
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: headerAppeared ? 30 : 0, height: 3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: headerAppeared)
            }

            // Menu button on left and filter button on right
            HStack {
                Button(action: {
                    NotificationCenter.default.post(name: .toggleSettingsNotification, object: nil) // Use standard name
                }) {
                    VStack(spacing: 6) {
                        HStack {
                            Rectangle().fill(styles.colors.accent).frame(width: 28, height: 2); Spacer()
                        }
                        HStack {
                            Rectangle().fill(styles.colors.accent).frame(width: 20, height: 2); Spacer()
                        }
                    }
                    .frame(width: 36, height: 36)
                }

                Spacer()

                // Filter button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingFilterPanel.toggle()
                    }
                }) {
                    Image(systemName: "slider.horizontal.2.square")
                        .font(.system(size: 20))
                        .foregroundColor(showingFilterPanel || !searchTags.isEmpty || !selectedMoods.isEmpty || dateFilterType != .all ? styles.colors.accent : styles.colors.text)
                }
            }
            .padding(.horizontal, styles.layout.paddingXL)
        }
        .padding(.top, 8)
        .padding(.bottom, 8) // Existing bottom padding here is likely fine
    }


    @ViewBuilder // Use ViewBuilder for conditional content
    private var filterPanelView: some View {
        if showingFilterPanel {
            FilterPanel(
                searchText: $searchText,
                searchTags: $searchTags,
                selectedMoods: $selectedMoods,
                dateFilterType: $dateFilterType,
                customStartDate: $customStartDate,
                customEndDate: $customEndDate,
                onClearFilters: {
                    clearFilters()
                }
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // Computed property for the streak headline text
    private var streakHeadlineText: String {
        let streak = appState.currentStreak
        let hasTodayEntry = appState.hasEntryToday

        if streak > 0 {
            return hasTodayEntry ? "\(streak) Day Streak!" : "Keep your \(streak)-day streak going!"
        } else {
            // This case shouldn't be reached if the section is conditional, but good to have
            return "Start a new streak today!" // This property is no longer used but kept for now.
        }
    }

    // ViewModel for the heatmap
    @StateObject private var heatmapViewModel: ActivityHeatmapViewModel

    // State for entry preview popup
    @State private var showingEntryPreview = false
    @State private var entryForPreview: JournalEntry? = nil

    // Initializer to inject AppState and DatabaseService into heatmap ViewModel
    init(tabBarOffset: Binding<CGFloat>, lastScrollPosition: Binding<CGFloat>, tabBarVisible: Binding<Bool>, appState: AppState, databaseService: DatabaseService) {
        self._tabBarOffset = tabBarOffset
        self._lastScrollPosition = lastScrollPosition
        self._tabBarVisible = tabBarVisible
        // Initialize the heatmap ViewModel with appState and databaseService
        self._heatmapViewModel = StateObject(wrappedValue: ActivityHeatmapViewModel(appState: appState, databaseService: databaseService))
    }

    private func journalContent() -> some View {
        // Use LazyVStack directly inside ScrollView for sticky headers
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) { // Use LazyVStack

                // --- Top Page Title (Inside LazyVStack) ---
                Text(Taglines.getTagline(for: .journal))
                    .font(styles.typography.largeTitle)
                    .foregroundColor(styles.colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, styles.layout.paddingL * 2)
                    .padding(.trailing, styles.layout.paddingL)
                    .padding(.top, styles.layout.paddingL * 4)
                    .padding(.bottom, styles.layout.paddingL * 2)

                // --- NEW Activity Heatmap Section ---
                Section {
                    // Instantiate the new heatmap view
                    ActivityHeatmapView(viewModel: heatmapViewModel) { entry in
                        // Action to perform when a cell is tapped
                        self.entryForPreview = entry
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.showingEntryPreview = true
                        }
                    }
                    .padding(.horizontal, styles.layout.paddingL) // Padding for the card
                    .padding(.bottom, styles.layout.paddingL) // Space below heatmap
                    .transition(.opacity.combined(with: .move(edge: .top))) // Animation
                } header: {
                    // Use a simpler title like "Activity"
                    SharedSectionHeader(title: "Activity", backgroundColor: styles.colors.appBackground)
                }
                .id("activity-heatmap-section") // Section ID

                 // Narrative Snippet (Displayed outside card, only when collapsed)
                 if !heatmapViewModel.isExpanded {
                     Text(heatmapViewModel.narrativeSnippetDisplay)
                         .font(styles.typography.bodyFont) // Increased font size
                         .foregroundColor(heatmapViewModel.loadNarrativeError ? styles.colors.error : styles.colors.textSecondary)
                         .lineLimit(5) // Allow up to 5 lines
                         .fixedSize(horizontal: false, vertical: true) // Ensure vertical expansion
                         .padding(.horizontal, styles.layout.paddingL) // Match card horizontal padding
                         .padding(.top, styles.layout.spacingXS) // Small space below header
                         .padding(.bottom, styles.layout.spacingM) // Space above heatmap card
                         .frame(maxWidth: .infinity, alignment: .leading)
                         .transition(.opacity) // Fade in/out
                 }


                // --- Entry List / Empty State ---
                if filteredEntries.isEmpty {
                    // Embed emptyState in a container to allow Spacer to work within LazyVStack
                    VStack {
                        emptyState
                    }
                    .padding(.top, appState.currentStreak > 0 ? 0 : styles.layout.paddingXL) // Add top padding only if streak card isn't shown

                } else {
                   journalListWithCTA // This already returns Sections within the LazyVStack
                }

               // Ensure CTA is placed if "Today" and "Yesterday" were empty
               // (Logic moved inside journalListWithCTA)

               // Bottom padding for FAB
               Spacer(minLength: styles.layout.paddingXL + 80) // Keep space for FAB

           } // End LazyVStack
       } // End ScrollView
        .coordinateSpace(name: "scrollView")
        .disabled(mainScrollingDisabled)
        .simultaneousGesture(
           TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
           }
       )
   }

   // NEW: Combined journal list with integrated CTA placement logic
    @ViewBuilder // <-- IMPORTANT: Make this ViewBuilder to return Sections
    private var journalListWithCTA: some View {
        let entriesGrouped = groupedEntries // Cache for efficiency
        let hasToday = entriesGrouped.contains { $0.0 == "Today" }
        let hasYesterday = entriesGrouped.contains { $0.0 == "Yesterday" }

        // Loop through the grouped entries and create Sections
        ForEach(entriesGrouped.indices, id: \.self) { sectionIndex in
            let (section, entries) = entriesGrouped[sectionIndex]

            Section(header: SharedSectionHeader(title: section, backgroundColor: styles.colors.appBackground)
                                .id("header-\(section)")
            ) {
                // Use regular VStack for cards within the section
                VStack(spacing: styles.layout.radiusM) {
                    ForEach(entries) { entry in
                        JournalEntryCard(
                            entry: entry,
                            isExpanded: appState.journalExpandedEntryId == entry.id,
                            onTap: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { appState.journalExpandedEntryId = appState.journalExpandedEntryId == entry.id ? nil : entry.id } },
                            onExpand: { fullscreenEntry = entry },
                            onStar: { toggleStar(entry) }
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .id(entry.id)
                    }
                }
                .padding(.horizontal, styles.layout.paddingL)
                .padding(.bottom, styles.layout.paddingL) // Add bottom padding to separate from next header/CTA
            }

            // CTA Placement Logic: Place AFTER specific sections if they exist
            if section == "Today" {
                 // Wrap CTA in its own Section for correct spacing in LazyVStack
                 Section {
                     ctaSectionView.padding(.vertical, styles.layout.paddingXL)
                 }
            } else if section == "Yesterday" && !hasToday {
                 Section {
                     ctaSectionView.padding(.vertical, styles.layout.paddingXL)
                 }
            }
        } // End ForEach sections

        // CTA Placement Logic (Fallback): Place at the end if neither Today/Yesterday existed
        if !hasToday && !hasYesterday && !entriesGrouped.isEmpty {
             // Ensure it's only added if there are SOME entries at all
             Section {
                 ctaSectionView.padding(.vertical, styles.layout.paddingXL)
             }
        }
    } // End journalListWithCTA


     // CTA Section View (remains the same)
     private var ctaSectionView: some View {
         VStack(spacing: styles.layout.spacingM) {
             Text("Review your patterns and progress over time.")
                 .font(styles.typography.bodyFont)
                 .foregroundColor(styles.colors.textSecondary)
                 .multilineTextAlignment(.center)

             Button("Go to Insights") {
                  print("[JournalView] Posting switchToTabNotification (index 1)") // Debug Print
                 NotificationCenter.default.post(
                     name: .switchToTabNotification, // Use standard name
                     object: nil,
                     userInfo: ["tabIndex": 1] // Index 1 = Insights
                 )
             }
             .buttonStyle(UIStyles.PrimaryButtonStyle()) // Use primary style
         }
         .padding(.horizontal, styles.layout.paddingXL) // Standard horizontal padding
         // Vertical padding added where it's used
     }


    private var emptyState: some View {
        VStack(alignment: .center, spacing: 16) {
           if !searchTags.isEmpty || !selectedMoods.isEmpty || dateFilterType != .all {
               Text("No Matching Entries")
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.text)
                    .padding(.top, 60)
               Text("Try adjusting your filters")
                   .font(styles.typography.bodySmall)
                   .foregroundColor(styles.colors.textSecondary)
               Button("Clear Filters") { clearFilters(closePanel: true) }
               .font(styles.typography.bodyFont)
               .foregroundColor(styles.colors.accent)
               .padding(.top, 8)
           } else {
               Text("No journal entries yet.")
                   .font(styles.typography.headingFont)
                   .foregroundColor(styles.colors.text)
                   .padding(.top, 60)
               Text("Tap the + button to add your first entry.")
                   .font(styles.typography.bodyFont)
                   .foregroundColor(styles.colors.textSecondary)
           }
           Spacer()
       }
       .frame(maxWidth: .infinity)
       .padding()
       // Don't show the "Go to Insights" CTA when the journal is truly empty
    }

    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    // Set flag directly for JournalView FAB
                    print("[JournalView] FAB Tapped - Setting presentNewJournalEntrySheet = true")
                     appState.objectWillChange.send() // Ensure update is published
                    appState.presentNewJournalEntrySheet = true
                 }) {
                    Image(systemName: "plus")
                        .renderingMode(.template) // Ensure foregroundColor takes effect
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(styles.colors.accentIconForeground) // Use specific icon color
                        .frame(width: 60, height: 60)
                        .background(
                            // Simpler background - just the accent color circle
                            Circle().fill(styles.colors.accent)
                        )
                        .shadow(color: styles.colors.accent.opacity(0.2), radius: 8, x: 0, y: 4) // Keep shadow for depth
                }
                 // REMOVED: .buttonStyle(PlainButtonStyle())
                 .padding(.trailing, 24)
                 .padding(.bottom, 24)
                 // Removed offset modifier
                 // Removed animation modifier related to offset
             }
         }
    }


    // MARK: - Helper Functions

    @MainActor
    private func updateEntryInAppState(_ updatedEntry: JournalEntry) {
        // Update underlying storage directly
         if let index = appState._journalEntries.firstIndex(where: { $0.id == updatedEntry.id }) {
            withAnimation { appState._journalEntries[index] = updatedEntry }
            if fullscreenEntry?.id == updatedEntry.id { fullscreenEntry = updatedEntry }
            appState._journalEntries.sort { $0.date > $1.date } // Keep sorted
             // Manually trigger update if simulating
             // if appState.simulateEmptyState { appState.objectWillChange.send() }
        } else {
             print("Warning: Tried to update entry \(updatedEntry.id) in AppState, but not found.")
        }
    }

    // Modify the deleteEntry function to show confirmation first
    private func deleteEntry(_ entry: JournalEntry) {
        Task { @MainActor in
            // Use underlying storage for deletion
            if let index = appState._journalEntries.firstIndex(where: { $0.id == entry.id }) {
                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { appState._journalEntries.remove(at: index) }
                 // Manually trigger update if simulating
                 // if appState.simulateEmptyState { appState.objectWillChange.send() }
            }
            if fullscreenEntry?.id == entry.id { fullscreenEntry = nil }
            if editingEntry?.id == entry.id { editingEntry = nil }
        }
        Task.detached(priority: .background) {
            do {
                // Assuming deleteJournalEntry is synchronous for now
                try databaseService.deleteJournalEntry(id: entry.id)
                print("✅ Successfully deleted journal entry \(entry.id) from DB.")
            } catch {
                print("‼️ Error deleting journal entry \(entry.id) from DB: \(error)")
            }
        }
    }

    // Function to toggle star status
    @MainActor
    private func toggleStar(_ entry: JournalEntry) {
        // Use underlying storage for modification
        guard let index = appState._journalEntries.firstIndex(where: { $0.id == entry.id }) else {
            print("Error: Could not find entry \(entry.id) to star.")
            return
        }

        appState._journalEntries[index].isStarred.toggle()
        let newStatus = appState._journalEntries[index].isStarred
        print("[JournalView] Toggling star for entry \(entry.id) to \(newStatus)")

        // Update fullscreen/editing views if they are showing this entry
        if fullscreenEntry?.id == entry.id {
            fullscreenEntry?.isStarred = newStatus
        }
        if editingEntry?.id == entry.id {
            editingEntry?.isStarred = newStatus
        }

         // Manually trigger update if simulating
         // if appState.simulateEmptyState { appState.objectWillChange.send() }


        // Persist change to DB in background
        Task.detached(priority: .background) { [databaseService] in
            do {
                try databaseService.toggleJournalEntryStarInDB(id: entry.id, isStarred: newStatus)
                print("✅ Successfully toggled star for entry \(entry.id) in DB.")
            } catch {
                print("‼️ Error toggling star for entry \(entry.id) in DB: \(error)")
                // Consider reverting UI state on error?
                // await MainActor.run { appState._journalEntries[index].isStarred.toggle() }
            }
        }
    }

} // End JournalView

// ... (Keep existing ScrollOffsetPreferenceKey) ...

// MARK: - Preview Provider
struct JournalView_Previews: PreviewProvider {
    // Need to create mock AppState and DatabaseService for the preview
    @StateObject static var previewAppState = AppState()
    @StateObject static var previewDbService = DatabaseService()

    static var previews: some View {
        // Simulate some entries for the preview
        let _ = {
             let calendar = Calendar.current
             let today = Date()
             previewAppState._journalEntries = (0..<40).compactMap { i -> JournalEntry? in
                 guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
                 if i % 2 == 0 { // Add entry every other day
                     return JournalEntry(text: "Preview Entry \(i)", mood: Mood.allCases.randomElement() ?? .neutral, date: date)
                 }
                 return nil
             }
         }()

        // Initialize JournalView correctly for the preview
        JournalView(
            tabBarOffset: .constant(0),
            lastScrollPosition: .constant(0),
            tabBarVisible: .constant(true),
            appState: previewAppState, // Pass the mock AppState
            databaseService: previewDbService // Pass the mock DatabaseService
        )
        .environmentObject(previewAppState) // Provide AppState via environment
        .environmentObject(previewDbService) // Provide DatabaseService via environment
        .environmentObject(UIStyles.shared)
        .environmentObject(ThemeManager.shared)
        .background(Color.gray.opacity(0.1))
        .preferredColorScheme(.dark)
    }
}


// Restored JournalEntryCard to original accordion style, removed context menu
struct JournalEntryCard: View {
    let entry: JournalEntry
    let isExpanded: Bool // Restored
    let onTap: () -> Void // For expansion/collapse
    let onExpand: () -> Void // For fullscreen view
    let onStar: () -> Void // Callback for starring

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header always visible
            HStack(alignment: .center) {
                // Date/Time and truncated text (if not expanded)
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatDate(entry.date)) // Restored date format logic
                        .font(styles.typography.smallLabelFont)
                        .foregroundColor(styles.colors.tertiaryAccent) // USE RENAMED tertiaryAccent

                    if !isExpanded {
                        Text(entry.text)
                            .lineLimit(1)
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.text)
                    }
                }

                Spacer()

                // Icons on the right
                HStack(spacing: 12) {
                    // Star icon if starred
                     if entry.isStarred {
                         Image(systemName: "star.fill")
                             .font(.system(size: 14)) // Match chat history star size
                             .foregroundColor(styles.colors.accent)
                             .padding(.trailing, -4) // Adjust spacing slightly
                     }

                    // Mood icon and formatted text (if expanded)
                    HStack(spacing: 4) {
                        entry.mood.icon
                            .foregroundColor(entry.mood.journalColor) // USE JOURNAL COLOR
                            .font(.system(size: 20))
                            .scaleEffect(isExpanded ? 1.1 : 1.0) // Keep scale effect

                        if isExpanded { // Restored conditional mood text
                            Text(formattedMoodText(entry.mood, intensity: entry.intensity))
                                .font(styles.typography.caption)
                                .foregroundColor(entry.mood.journalColor) // USE JOURNAL COLOR
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)

                    // Lock icon if needed (only when expanded)
                    if isExpanded && entry.isLocked { // Restored lock icon logic
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(styles.colors.tertiaryAccent) // USE RENAMED tertiaryAccent
                    }

                    // Expand/collapse chevron with rotation
                    Image(systemName: "chevron.down") // Restored chevron
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(styles.colors.tertiaryAccent) // USE RENAMED tertiaryAccent
                        .rotationEffect(Angle(degrees: isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Expanded content
            if isExpanded { // Restored expanded content section
                Divider()
                    .background(styles.colors.divider) // Use theme color
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)

                // Display full text using larger font size and unlimited lines
                Text(entry.text)
                     .font(styles.typography.bodyLarge) // Make text one size larger
                     .foregroundColor(styles.colors.text)
                     .lineLimit(nil) // Show full text (<5 lines limit automatically handled by content size)
                     .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                     .padding(.horizontal, 20)
                     .padding(.top, 16) // Keep top padding
                     .padding(.bottom, 8) // Reduce bottom padding slightly

                // Action buttons - only Expand button now
                HStack {
                    Spacer()

                    // Expand button (renamed to "View")
                    Button(action: onExpand) { // Restored button
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: styles.layout.iconSizeS))
                            Text("View")
                                .font(styles.typography.smallLabelFont)
                        }
                        .foregroundColor(styles.colors.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(styles.colors.secondaryBackground)
                        .cornerRadius(styles.layout.radiusM)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .fill(styles.colors.cardBackground) // Use theme color
                // REMOVED: .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                // Highlight border if starred, similar to ChatHistoryItem
                .stroke(entry.isStarred ? styles.colors.accent : styles.colors.divider, lineWidth: entry.isStarred ? 2 : 1) // Use divider color
        )
        .contentShape(Rectangle()) // Make whole card tappable
        .onTapGesture {
            onTap() // Handle tap for expansion/collapse
        }
        .onLongPressGesture {
            onStar() // Handle long press for starring
        }
        // Removed context menu entirely
    }

    // Restored original formatDate logic
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today, \(formatTime(date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(formatTime(date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy • h:mm a"
            return formatter.string(from: date)
        }
    }

    // Restored formatTime helper
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    // Restored formattedMoodText helper
    private func formattedMoodText(_ mood: Mood, intensity: Int = 2) -> String {
      switch intensity {
      case 1: return "Slightly \(mood.name)"
      case 3: return "Very \(mood.name)"
      default: return mood.name
      }
  }
}