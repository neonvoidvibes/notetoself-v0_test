import SwiftUI

struct JournalView: View {
    // Environment Objects
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService // <-- Inject DatabaseService

    // Environment Variables
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled

    // View State
    @State private var showingNewEntrySheet = false
    @State private var expandedEntryId: UUID? = nil
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

    // Access to shared styles
    private let styles = UIStyles.shared

    // Computed property to filter the journal entries (remains the same)
    private var filteredEntries: [JournalEntry] {
        // For now, this still filters the in-memory AppState array.
        // Later, this could be replaced by a database query if AppState stops holding all entries.
        appState.journalEntries.filtered(
            by: searchTags,
            moods: selectedMoods,
            dateFilter: dateFilterType,
            customStartDate: customStartDate,
            customEndDate: customEndDate
        )
    }

    // Function to clear filters (remains the same)
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
                // Header (remains the same)
                ZStack(alignment: .center) {
                    // Title truly centered
                    VStack(spacing: 8) {
                        Text("Journal")
                            .font(styles.typography.title1)
                            .foregroundColor(styles.colors.text)

                        Rectangle()
                            .fill(styles.colors.accent)
                            .frame(width: 20, height: 3)
                    }

                    // Menu button on left and filter button on right
                    HStack {
                        Button(action: {
                            NotificationCenter.default.post(name: NSNotification.Name("ToggleSettings"), object: nil)
                        }) {
                            VStack(spacing: 6) { // Increased spacing between bars
                                HStack {
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 28, height: 2) // Top bar - slightly longer
                                    Spacer()
                                }
                                HStack {
                                    Rectangle()
                                        .fill(styles.colors.accent)
                                        .frame(width: 20, height: 2) // Bottom bar (shorter)
                                    Spacer()
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

                // Filter panel (remains the same)
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

                // Journal entries list (remains mostly the same, uses filteredEntries)
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        // ScrollView content (Inspiring prompt, No Matching Entries, LazyVStack)
                        // ... (existing code for ScrollView content) ...
                        // This part doesn't change significantly yet, as it still reads from AppState
                         GeometryReader { geometry in
                             Color.clear.preference(
                                 key: ScrollOffsetPreferenceKey.self,
                                 value: geometry.frame(in: .named("scrollView")).minY
                             )
                         }
                         .frame(height: 0)

                         // Inspiring prompt - only show when there are filtered entries and filter panel is closed
                         if !appState.journalEntries.isEmpty && !filteredEntries.isEmpty && !showingFilterPanel {
                             VStack(alignment: .center, spacing: styles.layout.spacingL) {
                                 Text("My Journal")
                                     .font(styles.typography.headingFont)
                                     .foregroundColor(styles.colors.text)
                                     .padding(.bottom, 4)
                                 Text("Capture your thoughts, reflect on your journey.")
                                     .font(styles.typography.bodyLarge)
                                     .foregroundColor(styles.colors.accent)
                                     .multilineTextAlignment(.center)
                             }
                             .padding(.horizontal, styles.layout.paddingXL)
                             .padding(.vertical, styles.layout.spacingXL * 1.5)
                             .padding(.top, 80)
                             .padding(.bottom, 40)
                             .frame(maxWidth: .infinity)
                             .background(
                                 LinearGradient(
                                     gradient: Gradient(colors: [
                                         styles.colors.appBackground,
                                         styles.colors.appBackground.opacity(0.9)
                                     ]),
                                     startPoint: .top,
                                     endPoint: .bottom
                                 )
                             )
                         }

                         if filteredEntries.isEmpty {
                           VStack(alignment: .center, spacing: 16) {
                               if !searchTags.isEmpty || !selectedMoods.isEmpty || dateFilterType != .all {
                                   Text("No Matching Entries") // ... existing no results view
                                        .font(styles.typography.bodyFont)
                                        .foregroundColor(styles.colors.text)
                                        .padding(.top, 60)

                                   Text("Try adjusting your filters")
                                       .font(styles.typography.bodySmall)
                                       .foregroundColor(styles.colors.textSecondary)

                                   Button("Clear Filters") {
                                       clearFilters(closePanel: true)
                                   }
                                   .font(styles.typography.bodyFont)
                                   .foregroundColor(styles.colors.accent)
                                   .padding(.top, 8)
                               } else {
                                   Text("No journal entries yet.") // ... existing empty state view
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
                         } else {
                             LazyVStack(spacing: styles.layout.radiusM) {
                                 let groupedEntries = JournalDateGrouping.groupEntriesByTimePeriod(filteredEntries)

                                 ForEach(groupedEntries, id: \.0) { section, entries in
                                     DateGroupSectionHeader(title: section)
                                         .id("header-\(section)")

                                     ForEach(entries) { entry in
                                         JournalEntryCard(
                                             entry: entry,
                                             isExpanded: expandedEntryId == entry.id,
                                             onTap: {
                                                 withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                     expandedEntryId = expandedEntryId == entry.id ? nil : entry.id
                                                 }
                                             },
                                             onExpand: {
                                                 fullscreenEntry = entry
                                             }
                                         )
                                         .transition(.opacity.combined(with: .move(edge: .top)))
                                     }
                                 }
                             }
                             .padding(.horizontal, 20)
                             .padding(.bottom, 100)
                         }
                    } // End ScrollView
                    .coordinateSpace(name: "scrollView")
                    .disabled(mainScrollingDisabled)
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        let scrollingDown = value < lastScrollPosition
                        if abs(value - lastScrollPosition) > 10 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if scrollingDown {
                                    tabBarOffset = 100
                                    tabBarVisible = false
                                } else {
                                    tabBarOffset = 0
                                    tabBarVisible = true
                                }
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
            } // End VStack

            // Floating add button (remains the same)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingNewEntrySheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(styles.colors.appBackground)
                            .frame(width: 60, height: 60)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(styles.colors.accent)

                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .padding(2)
                                }
                            )
                            .shadow(color: styles.colors.accent.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                    .offset(y: tabBarOffset * 0.7)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tabBarOffset)
                }
            }
        } // End ZStack
        .fullScreenCover(isPresented: $showingNewEntrySheet) {
            // *** MODIFIED onSave for NEW entries ***
            EditableFullscreenEntryView(
                initialMood: .neutral,
                onSave: { text, mood, intensity in
                    // 1. Create the new entry object
                    let newEntry = JournalEntry(text: text, mood: mood, date: Date(), intensity: intensity)

                    // 2. Generate embedding asynchronously & Save to Database
                    Task {
                        print("[JournalView] Generating embedding for new entry...")
                        let embeddingVector = await generateEmbedding(for: newEntry.text)

                        // 3. Save to Database (handle errors)
                        do {
                            try databaseService.saveJournalEntry(newEntry, embedding: embeddingVector)
                            print("✅ Successfully saved new journal entry \(newEntry.id) to DB.")

                            // 4. *Only if DB save succeeds*, update AppState UI
                            await MainActor.run { // Ensure UI updates are on main actor
                                 withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                     // Prepend to keep newest first
                                     appState.journalEntries.insert(newEntry, at: 0)
                                     expandedEntryId = newEntry.id // Auto-expand
                                 }
                            }
                        } catch {
                            print("‼️ Error saving new journal entry \(newEntry.id) to DB: \(error)")
                            // Optionally show an error alert to the user here
                        }
                    } // End Task for embedding/saving
                },
                autoFocusText: true
            )
        }
        .fullScreenCover(item: $fullscreenEntry) { entry in
            // View existing entry (no changes needed here)
            FullscreenEntryView(
                entry: entry,
                onEdit: {
                    fullscreenEntry = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        editingEntry = entry
                    }
                },
                onDelete: {
                    deleteEntry(entry) // Needs DB delete logic later
                }
            )
        }
        .fullScreenCover(item: $editingEntry) { entryToEdit in
             // *** MODIFIED onSave for EDITING entries ***
            EditableFullscreenEntryView(
                entry: entryToEdit,
                onSave: { updatedText, updatedMood, updatedIntensity in
                    // 1. Create the updated entry object
                    // Keep original ID and Date
                     let updatedEntry = JournalEntry(
                         id: entryToEdit.id,
                         text: updatedText,
                         mood: updatedMood,
                         date: entryToEdit.date, // Keep original date
                         intensity: updatedIntensity
                     )

                    // 2. Generate embedding asynchronously & Save updated entry to Database
                    Task {
                         print("[JournalView] Generating embedding for updated entry...")
                         let embeddingVector = await generateEmbedding(for: updatedEntry.text)

                        // 3. Save updated entry to Database (handle errors)
                        do {
                            try databaseService.saveJournalEntry(updatedEntry, embedding: embeddingVector)
                            print("✅ Successfully updated journal entry \(updatedEntry.id) in DB.")

                            // 4. *Only if DB save succeeds*, update AppState UI
                            await MainActor.run { // Ensure UI updates are on main actor
                                updateEntryInAppState(updatedEntry) // Use helper to update AppState
                            }
                        } catch {
                            print("‼️ Error updating journal entry \(updatedEntry.id) in DB: \(error)")
                             // Optionally show an error alert
                        }
                    } // End Task for embedding/saving
                },
                onDelete: {
                    deleteEntry(entryToEdit) // Needs DB delete logic later
                },
                autoFocusText: true
            )
        }
        .onAppear {
             // Load initial data from DB? (Deferred for now)
            // The existing logic only expands the first in-memory entry
            if expandedEntryId == nil, let firstEntry = appState.journalEntries.first {
                expandedEntryId = firstEntry.id
            }
        }
    } // End Body

    // MARK: - Helper Functions (Modify these later for DB operations)

    // Helper function to update entry in AppState (used by editing save)
    // Ensure this is called on the main actor
    @MainActor
    private func updateEntryInAppState(_ updatedEntry: JournalEntry) {
        if let index = appState.journalEntries.firstIndex(where: { $0.id == updatedEntry.id }) {
            withAnimation {
                appState.journalEntries[index] = updatedEntry
            }
            // Update fullscreen/editing state if necessary
            if fullscreenEntry?.id == updatedEntry.id {
                fullscreenEntry = updatedEntry
            }
            // We assume editingEntry is dismissed automatically by the sheet closing
        } else {
             print("Warning: Tried to update entry \(updatedEntry.id) in AppState, but not found.")
             // Maybe append it if somehow missing? Or reload from DB?
        }
    }

    // TODO: Modify deleteEntry to also delete from DatabaseService
    private func deleteEntry(_ entry: JournalEntry) {
        // --- Current AppState Deletion (needs to be on main actor) ---
        Task { @MainActor in // Ensure UI updates run on main actor
            if let index = appState.journalEntries.firstIndex(where: { $0.id == entry.id }) {
                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    appState.journalEntries.remove(at: index)
                }
            }
             // Clear UI state
            if fullscreenEntry?.id == entry.id { fullscreenEntry = nil }
            if editingEntry?.id == entry.id { editingEntry = nil }
        }

        // --- Delete from Database ---
        Task.detached(priority: .background) { // Run DB delete in the background
            do {
                try databaseService.deleteJournalEntry(id: entry.id) // Call the DB service method
                print("✅ Successfully deleted journal entry \(entry.id) from DB.")
            } catch {
                print("‼️ Error deleting journal entry \(entry.id) from DB: \(error)")
                // --- Error Handling Strategy ---
                // If DB delete fails, the UI already removed the item.
                // Option 1: Do nothing (UI and DB are out of sync). Not ideal.
                // Option 2: Show an error alert to the user (needs main actor).
                // Option 3 (Complex): Try to re-insert the item into AppState to match DB.
                // For now, just log the error. Consider adding user feedback later.
                // await MainActor.run { /* Show alert */ }
            }
        }
    }

    // TODO: Modify updateEntry to call saveJournalEntry via DatabaseService (Done inside the .fullScreenCover modifier now)
    // Remove the old updateEntry function as the logic is now in the onSave closure.
    // private func updateEntry(_ entry: JournalEntry, newText: String, newMood: Mood, intensity: Int) { ... }

} // End JournalView

// ScrollOffsetPreferenceKey and JournalEntryCard remain the same for now...

// ... (Keep existing ScrollOffsetPreferenceKey and JournalEntryCard structs) ...

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct JournalEntryCard: View {
    let entry: JournalEntry
    let isExpanded: Bool
    let onTap: () -> Void
    let onExpand: () -> Void

    private let styles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header always visible
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatDate(entry.date))
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

                HStack(spacing: 12) {
                    // Mood icon and formatted text
                    HStack(spacing: 4) {
                        entry.mood.icon
                            .foregroundColor(entry.mood.color)
                            .font(.system(size: 20))
                            .scaleEffect(isExpanded ? 1.1 : 1.0)

                        if isExpanded {
                            Text(formattedMoodText(entry.mood, intensity: entry.intensity))
                                .font(styles.typography.caption)
                                .foregroundColor(entry.mood.color)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)

                    // Lock icon if needed (only when expanded)
                    if isExpanded && entry.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(styles.colors.secondaryAccent)
                    }

                    // Expand/collapse chevron with rotation
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(styles.colors.secondaryAccent)
                        .rotationEffect(Angle(degrees: isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Expanded content
            if isExpanded {
                Divider()
                    .background(Color(hex: "#222222"))
                    .padding(.horizontal, 16)

                Text(entry.text)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.text)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                // Action buttons - only Expand button now
                HStack {
                    Spacer()

                    // Expand button
                    Button(action: onExpand) {
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
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .stroke(Color(hex: "#222222"), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(action: onExpand) {
                Label("View", systemImage: "arrow.up.left.and.arrow.down.right")
            }
        }
    }

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

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formattedMoodText(_ mood: Mood, intensity: Int = 2) -> String {
      switch intensity {
      case 1: return "Slightly \(mood.name)"
      case 3: return "Very \(mood.name)"
      default: return mood.name
      }
  }
}