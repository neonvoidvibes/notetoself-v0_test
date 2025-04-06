import SwiftUI

struct JournalView: View {
    // Environment Objects
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

    // Environment Variables
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled

    // View State
    @State private var showingNewEntrySheet = false
    // @State private var expandedEntryId: UUID? = nil // REMOVED - Moved to AppState
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
                journalContent // Extracted ScrollView content
            }

            floatingAddButton // Extracted floating button
        } // End ZStack
        .onAppear { // Trigger animation when view appears
            // Use DispatchQueue to delay slightly if needed for visual effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                headerAppeared = true
            }
        }
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
                                 withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                     appState.journalEntries.insert(newEntry, at: 0)
                                     appState.journalEntries.sort { $0.date > $1.date } // Keep sorted
                                     appState.journalExpandedEntryId = newEntry.id // Expand new entry by default using AppState
                                 }
                            }
                            // Call global trigger function
                            await triggerAllInsightGenerations(llmService: LLMService.shared, databaseService: databaseService, appState: appState)
                        } catch {
                            print("‼️ Error saving new journal entry \(newEntry.id) to DB: \(error)")
                        }
                    }
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
    } // End Body


    // MARK: - Computed View Properties

    // Restore the headerView definition
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
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleSettings"), object: nil)
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
        .padding(.bottom, 8)
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

    private var journalContent: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                 GeometryReader { geometry in
                     Color.clear.preference(
                         key: ScrollOffsetPreferenceKey.self,
                         value: geometry.frame(in: .named("scrollView")).minY
                     )
                 }
                 .frame(height: 0)

                 // --- Journey Card ---
                 JourneyInsightCard()
                     .padding(.horizontal, styles.layout.paddingL) // Standard horizontal padding
                     .padding(.top, styles.layout.spacingXL)       // Ample top padding
                     .padding(.bottom, styles.layout.spacingL)     // Ample bottom padding

                 // --- Entry List / Empty State ---
                 if filteredEntries.isEmpty {
                    emptyState
                 } else {
                    journalList
                 }
            } // End ScrollView
            .coordinateSpace(name: "scrollView")
            .disabled(mainScrollingDisabled)
            // Add onAppear here to restore scroll position when tab becomes active
            .onAppear {
                // Check if there's a previously expanded entry
                if let entryId = appState.journalExpandedEntryId {
                    // Scroll to that entry without animation
                    // Use a slight delay to ensure the view hierarchy is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                         scrollProxy.scrollTo(entryId, anchor: .top)
                         print("[JournalView.onAppear] Restored scroll to expanded entry: \(entryId)")
                    }
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                let scrollingDown = value < lastScrollPosition
                if abs(value - lastScrollPosition) > 10 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if scrollingDown { tabBarOffset = 100; tabBarVisible = false }
                        else { tabBarOffset = 0; tabBarVisible = true }
                    }
                    lastScrollPosition = value
                }
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                     UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
        } // End ScrollViewReader
    }

    private var journalList: some View {
        LazyVStack(spacing: styles.layout.radiusM, pinnedViews: [.sectionHeaders]) { // Pinned views attempt stickiness
             let groupedEntries = JournalDateGrouping.groupEntriesByTimePeriod(filteredEntries)
             ForEach(groupedEntries, id: \.0) { section, entries in
                 // Use the RENAMED component, passing the correct background
                 Section(header: SharedSectionHeader(title: section, backgroundColor: styles.colors.appBackground)
                                     .id("header-\(section)")
                 ) {
                     ForEach(entries) { entry in
                         JournalEntryCard(
                             entry: entry,
                             isExpanded: appState.journalExpandedEntryId == entry.id, // Use AppState
                             onTap: { // Restore onTap for expansion
                                 withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                     // Update AppState on tap
                                     appState.journalExpandedEntryId = appState.journalExpandedEntryId == entry.id ? nil : entry.id
                                 }
                             },
                             onExpand: { fullscreenEntry = entry }, // Restore onExpand
                             onStar: { toggleStar(entry) } // Keep star action
                         )
                         .padding(.horizontal, styles.layout.paddingL) // Apply padding here
                         .transition(.opacity.combined(with: .move(edge: .top)))
                     }
                 }
             }
         }
         // REMOVED: .padding(.horizontal, 20)
         .padding(.bottom, 100) // Keep bottom padding
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
    }

    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showingNewEntrySheet = true }) {
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
                .offset(y: tabBarOffset * 0.7)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tabBarOffset)
            }
        }
    }


    // MARK: - Helper Functions

    @MainActor
    private func updateEntryInAppState(_ updatedEntry: JournalEntry) {
        if let index = appState.journalEntries.firstIndex(where: { $0.id == updatedEntry.id }) {
            withAnimation { appState.journalEntries[index] = updatedEntry }
            if fullscreenEntry?.id == updatedEntry.id { fullscreenEntry = updatedEntry }
            appState.journalEntries.sort { $0.date > $1.date } // Keep sorted
        } else {
             print("Warning: Tried to update entry \(updatedEntry.id) in AppState, but not found.")
        }
    }

    // Modify the deleteEntry function to show confirmation first
    private func deleteEntry(_ entry: JournalEntry) {
        Task { @MainActor in
            if let index = appState.journalEntries.firstIndex(where: { $0.id == entry.id }) {
                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { appState.journalEntries.remove(at: index) }
            }
            if fullscreenEntry?.id == entry.id { fullscreenEntry = nil }
            if editingEntry?.id == entry.id { editingEntry = nil }
        }
        Task.detached(priority: .background) {
            do {
                // Add await here as deleteJournalEntry might become async later
                try await databaseService.deleteJournalEntry(id: entry.id)
                print("✅ Successfully deleted journal entry \(entry.id) from DB.")
            } catch {
                print("‼️ Error deleting journal entry \(entry.id) from DB: \(error)")
            }
        }
    }

    // Function to toggle star status
    @MainActor
    private func toggleStar(_ entry: JournalEntry) {
        guard let index = appState.journalEntries.firstIndex(where: { $0.id == entry.id }) else {
            print("Error: Could not find entry \(entry.id) to star.")
            return
        }

        appState.journalEntries[index].isStarred.toggle()
        let newStatus = appState.journalEntries[index].isStarred
        print("[JournalView] Toggling star for entry \(entry.id) to \(newStatus)")

        // Update fullscreen/editing views if they are showing this entry
        if fullscreenEntry?.id == entry.id {
            fullscreenEntry?.isStarred = newStatus
        }
        if editingEntry?.id == entry.id {
            editingEntry?.isStarred = newStatus
        }

        // Persist change to DB in background
        Task.detached(priority: .background) { [databaseService] in
            do {
                try databaseService.toggleJournalEntryStarInDB(id: entry.id, isStarred: newStatus)
                print("✅ Successfully toggled star for entry \(entry.id) in DB.")
            } catch {
                print("‼️ Error toggling star for entry \(entry.id) in DB: \(error)")
                // Consider reverting UI state on error?
                // await MainActor.run { appState.journalEntries[index].isStarred.toggle() }
            }
        }
    }

} // End JournalView

// ... (Keep existing ScrollOffsetPreferenceKey) ...

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
                        .foregroundColor(styles.colors.secondaryAccent)

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
                            .foregroundColor(styles.colors.secondaryAccent)
                    }

                    // Expand/collapse chevron with rotation
                    Image(systemName: "chevron.down") // Restored chevron
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(styles.colors.secondaryAccent)
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
                    .padding(.horizontal, 16)

                Text(entry.text) // Show full text when expanded
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.text)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

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