import SwiftUI

struct JournalView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled
    @State private var showingNewEntrySheet = false
    @State private var expandedEntryId: UUID? = nil
    @State private var editingEntry: JournalEntry? = nil
    @Binding var tabBarOffset: CGFloat
    @Binding var lastScrollPosition: CGFloat
    @Binding var tabBarVisible: Bool
    
    // Filter state variables
    @State private var showingFilterPanel = false
    @State private var searchText = ""
    @State private var searchTags: [String] = []
    @State private var selectedMoods: Set<Mood> = []
    @State private var dateFilterType: DateFilterType = .all
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    
    // Add this state variable after the other @State variables in JournalView:
    @State private var fullscreenEntry: JournalEntry? = nil
    
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
    
    // Function to clear all filters and optionally close the filter panel
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
                .padding(.top, 8) // Further reduced top padding
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
                
                // Journal entries
                ScrollViewReader { scrollProxy in
                    ScrollView {
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
                                // Inspiring header with larger font
                                Text("Your Journal")
                                    .font(styles.typography.headingFont)
                                    .foregroundColor(styles.colors.text)
                                    .padding(.bottom, 4)
                                
                                // Inspiring quote with larger font
                                Text("Capture your thoughts, reflect on your journey.")
                                    .font(styles.typography.bodyLarge)
                                    .foregroundColor(styles.colors.accent)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, styles.layout.paddingXL)
                            .padding(.vertical, styles.layout.spacingXL * 1.5)
                            .padding(.top, 40) // Extra top padding for spaciousness
                            .padding(.bottom, 20) // Extra bottom padding
                            .frame(maxWidth: .infinity)
                            .background(
                                // Subtle gradient background for the inspiring section
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
                                  Text("No Matching Entries")
                                      .font(styles.typography.bodyFont)
                                      .foregroundColor(styles.colors.text)
                                      .padding(.top, 60) // Ample top padding
                              
                                  Text("Try adjusting your filters")
                                      .font(styles.typography.bodySmall)
                                      .foregroundColor(styles.colors.textSecondary)
                              
                                  Button("Clear Filters") {
                                      clearFilters(closePanel: true) // Close panel when clearing filters
                                  }
                                  .font(styles.typography.bodyFont)
                                  .foregroundColor(styles.colors.accent)
                                  .padding(.top, 8)
                              } else {
                                  Text("No journal entries yet.")
                                      .font(styles.typography.headingFont)
                                      .foregroundColor(styles.colors.text)
                                      .padding(.top, 60) // Ample top padding
                              
                                  Text("Tap the + button to add your first entry.")
                                      .font(styles.typography.bodyFont)
                                      .foregroundColor(styles.colors.textSecondary)
                              }
                              
                              Spacer() // Push content to the top
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
                            .padding(.bottom, 100) // Extra padding for floating button
                        }
                    }
                    .coordinateSpace(name: "scrollView")
                    .disabled(mainScrollingDisabled)
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // Calculate scroll direction and update tab bar visibility
                        let scrollingDown = value < lastScrollPosition
                        
                        // Only update when scrolling more than a threshold to avoid jitter
                        if abs(value - lastScrollPosition) > 10 {
                            if scrollingDown {
                                tabBarOffset = 100 // Hide tab bar
                                tabBarVisible = false
                            } else {
                                tabBarOffset = 0 // Show tab bar
                                tabBarVisible = true
                            }
                            lastScrollPosition = value
                        }
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    )
                }
            }
            
            // Floating add button
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
                                    
                                    // Add subtle gradient overlay for depth
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
                    .offset(y: tabBarOffset * 0.7) // Move with tab bar but not as much
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tabBarOffset)
                }
            }
        }
        .fullScreenCover(isPresented: $showingNewEntrySheet) {
            // Use the same EditableFullscreenEntryView for new entries
            EditableFullscreenEntryView(
                initialMood: .neutral, 
                onSave: { text, mood, intensity in
                    let newEntry = JournalEntry(text: text, mood: mood, date: Date(), intensity: intensity)

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        appState.journalEntries.insert(newEntry, at: 0)
                        expandedEntryId = newEntry.id // Auto-expand new entry
                    }
                },
                autoFocusText: true // Auto-focus for immediate typing
            )
        }
        .fullScreenCover(item: $fullscreenEntry) { entry in
            FullscreenEntryView(
                entry: entry,
                onEdit: {
                    // Dismiss the fullscreen view first, then set the editing entry
                    fullscreenEntry = nil
                    // Small delay to ensure smooth transition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        editingEntry = entry
                    }
                },
                onDelete: {
                    deleteEntry(entry)
                }
            )
        }
        .fullScreenCover(item: $editingEntry) { entry in
            EditableFullscreenEntryView(
                entry: entry,
                onSave: { updatedText, updatedMood, updatedIntensity in
                    updateEntry(entry, newText: updatedText, newMood: updatedMood, intensity: updatedIntensity)
                },
                onDelete: {
                    deleteEntry(entry)
                },
                autoFocusText: true // Auto-focus for immediate editing with cursor at end
            )
        }
        .onAppear {
            if expandedEntryId == nil, let firstEntry = appState.journalEntries.first {
                expandedEntryId = firstEntry.id
            }
        }
    }
    
    private func deleteEntry(_ entry: JournalEntry) {
        if let index = appState.journalEntries.firstIndex(where: { $0.id == entry.id }) {
            _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appState.journalEntries.remove(at: index)
            }
        }
        
        // Clear the fullscreen entry if it's the one being deleted
        if fullscreenEntry?.id == entry.id {
            fullscreenEntry = nil
        }
        
        // Clear the editing entry if it's the one being deleted
        if editingEntry?.id == entry.id {
            editingEntry = nil
        }
    }
    
    private func updateEntry(_ entry: JournalEntry, newText: String, newMood: Mood, intensity: Int) {
        if let index = appState.journalEntries.firstIndex(where: { $0.id == entry.id }) {
            let updatedEntry = JournalEntry(
                id: entry.id,
                text: newText,
                mood: newMood,
                date: entry.date,
                intensity: intensity
            )
            
            withAnimation {
                appState.journalEntries[index] = updatedEntry
            }
            
            // Update the fullscreen entry if it's the one being edited
            if fullscreenEntry?.id == entry.id {
                fullscreenEntry = updatedEntry
            }
        }
    }
}

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

