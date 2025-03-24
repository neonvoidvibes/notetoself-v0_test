import SwiftUI

//Use `JournalEntryFormContent` as shared component for both new entries and editing existing entries

struct JournalView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.mainScrollingDisabled) private var mainScrollingDisabled: Bool
    @State private var showingNewEntrySheet = false
    @State private var expandedEntryId: UUID? = nil
    @State private var editingEntry: JournalEntry? = nil
    @Binding var tabBarOffset: CGFloat
    @Binding var lastScrollPosition: CGFloat
    @Binding var tabBarVisible: Bool
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
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
                    
                    // Menu button on left
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
                    }
                    .padding(.horizontal, styles.layout.paddingXL)
                }
                .padding(.top, 8) // Further reduced top padding
                .padding(.bottom, 8)
                
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
                        
                        // Inspiring prompt
                        if !appState.journalEntries.isEmpty {
                            VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                                Text("Today's Reflection")
                                    .font(styles.typography.smallLabelFont)
                                    .foregroundColor(styles.colors.accent)
                                
                                Text("What's one small or big thing on your mind right now?")
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .padding(.bottom, styles.layout.spacingS)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, styles.layout.spacingM)
                            .padding(.top, styles.layout.spacingS)
                        }
                        
                        if appState.journalEntries.isEmpty {
                            VStack(spacing: 16) {
                                Spacer()
                                
                                Text("No journal entries yet.")
                                    .font(styles.typography.headingFont)
                                    .foregroundColor(styles.colors.text)
                                
                                Text("Tap the + button to add your first entry.")
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                                
                                Spacer()
                            }
                            .frame(minHeight: UIScreen.main.bounds.height * 0.7)
                            .padding()
                        } else {
                            LazyVStack(spacing: styles.layout.radiusM) {
                                ForEach(appState.journalEntries) { entry in
                                    JournalEntryCard(
                                        entry: entry,
                                        isExpanded: expandedEntryId == entry.id,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                expandedEntryId = expandedEntryId == entry.id ? nil : entry.id
                                            }
                                        },
                                        onEdit: {
                                            if !entry.isLocked {
                                                editingEntry = entry
                                            }
                                        },
                                        onDelete: {
                                            deleteEntry(entry)
                                        }
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
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
        .sheet(isPresented: $showingNewEntrySheet) {
            NewEntryView(onSave: { text, mood in
                let newEntry = JournalEntry(text: text, mood: mood, date: Date())
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    appState.journalEntries.insert(newEntry, at: 0)
                    expandedEntryId = newEntry.id // Auto-expand new entry
                }
            })
            // Presentation detents moved to EntryFormView for consistency
        }
        .sheet(item: $editingEntry) { entry in
            EditEntryView(entry: entry, onSave: { updatedText, updatedMood in
                updateEntry(entry, newText: updatedText, newMood: updatedMood)
            })
            // Presentation detents moved to EntryFormView for consistency
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
    }
    
    private func updateEntry(_ entry: JournalEntry, newText: String, newMood: Mood) {
        if let index = appState.journalEntries.firstIndex(where: { $0.id == entry.id }) {
            let updatedEntry = JournalEntry(
                id: entry.id,
                text: newText,
                mood: newMood,
                date: entry.date
            )
            
            withAnimation {
                appState.journalEntries[index] = updatedEntry
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
    let onEdit: () -> Void
    let onDelete: () -> Void
    
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
                    // Mood icon with subtle animation
                    entry.mood.icon
                        .foregroundColor(entry.mood.color)
                        .font(.system(size: 20))
                        .scaleEffect(isExpanded ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                    
                    // Lock icon if needed (only when expanded)
                    if isExpanded && entry.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#FF6B6B"))
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
                
                // Action buttons for edit and delete
                HStack {
                    Spacer()
                    
                    if !entry.isLocked {
                        Button(action: onEdit) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: styles.layout.iconSizeS))
                                Text("Edit")
                                    .font(styles.typography.smallLabelFont)
                            }
                            .foregroundColor(styles.colors.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(styles.colors.secondaryBackground)
                            .cornerRadius(styles.layout.radiusM)
                        }
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: styles.layout.iconSizeS))
                    }
                    .foregroundColor(styles.colors.error)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(styles.colors.secondaryBackground)
                    .cornerRadius(styles.layout.radiusM)
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
            if !entry.isLocked {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
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
}

struct EditEntryView: View {
    let entry: JournalEntry
    let onSave: (String, Mood) -> Void
    
    @State private var entryText: String
    @State private var selectedMood: Mood
    @Environment(\.dismiss) private var dismiss
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    init(entry: JournalEntry, onSave: @escaping (String, Mood) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _entryText = State(initialValue: entry.text)
        _selectedMood = State(initialValue: entry.mood)
    }
    
    var body: some View {
        EntryFormView(
            title: "Edit Note",
            onSave: {
                onSave(entryText, selectedMood)
                dismiss()
            },
            saveButtonEnabled: !entryText.isEmpty
        ) {
            JournalEntryFormContent(
                entryText: $entryText,
                selectedMood: $selectedMood
            )
        }
    }
}

