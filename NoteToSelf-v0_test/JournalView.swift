import SwiftUI

struct JournalView: View {
    // Environment Objects
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService

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

    // Computed property to filter the journal entries
    private var filteredEntries: [JournalEntry] {
        appState.journalEntries.filtered(
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
                // Header
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

                // Filter panel
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

                // Journal entries list
                ScrollViewReader { scrollProxy in
                    ScrollView {
                         GeometryReader { geometry in
                             Color.clear.preference(
                                 key: ScrollOffsetPreferenceKey.self,
                                 value: geometry.frame(in: .named("scrollView")).minY
                             )
                         }
                         .frame(height: 0)

                         // Inspiring prompt
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
                                     gradient: Gradient(colors: [styles.colors.appBackground, styles.colors.appBackground.opacity(0.9)]),
                                     startPoint: .top,
                                     endPoint: .bottom
                                 )
                             )
                         }

                         // Entry List / Empty State
                         if filteredEntries.isEmpty {
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
                                             onExpand: { fullscreenEntry = entry }
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
            } // End VStack

            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingNewEntrySheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(styles.colors.appBackground)
                            .frame(width: 60, height: 60)
                            .background(
                                ZStack {
                                    Circle().fill(styles.colors.accent)
                                    Circle().fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]), startPoint: .topLeading, endPoint: .bottomTrailing)).padding(2)
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
                                     expandedEntryId = newEntry.id
                                 }
                            }
                            // Call global trigger function
                            await triggerAllInsightGenerations(llmService: LLMService.shared, databaseService: databaseService, subscriptionTier: appState.subscriptionTier)
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
                     let updatedEntry = JournalEntry(id: entryToEdit.id, text: updatedText, mood: updatedMood, date: entryToEdit.date, intensity: updatedIntensity)
                    Task {
                         let embeddingVector = await generateEmbedding(for: updatedEntry.text)
                        do {
                            try databaseService.saveJournalEntry(updatedEntry, embedding: embeddingVector)
                            await MainActor.run { updateEntryInAppState(updatedEntry) }
                            // Call global trigger function
                            await triggerAllInsightGenerations(llmService: LLMService.shared, databaseService: databaseService, subscriptionTier: appState.subscriptionTier)
                        } catch {
                            print("‼️ Error updating journal entry \(updatedEntry.id) in DB: \(error)")
                        }
                    }
                },
                onDelete: { deleteEntry(entryToEdit) },
                autoFocusText: true
            )
        }
        .onAppear {
            if expandedEntryId == nil, let firstEntry = appState.journalEntries.first {
                expandedEntryId = firstEntry.id
            }
        }
    } // End Body

    // MARK: - Helper Functions

    @MainActor
    private func updateEntryInAppState(_ updatedEntry: JournalEntry) {
        if let index = appState.journalEntries.firstIndex(where: { $0.id == updatedEntry.id }) {
            withAnimation { appState.journalEntries[index] = updatedEntry }
            if fullscreenEntry?.id == updatedEntry.id { fullscreenEntry = updatedEntry }
        } else {
             print("Warning: Tried to update entry \(updatedEntry.id) in AppState, but not found.")
        }
    }

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
                try databaseService.deleteJournalEntry(id: entry.id)
                print("✅ Successfully deleted journal entry \(entry.id) from DB.")
            } catch {
                print("‼️ Error deleting journal entry \(entry.id) from DB: \(error)")
            }
        }
    }

} // End JournalView

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