import SwiftUI

struct JournalView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingNewEntrySheet = false
    @State private var expandedEntryId: UUID? = nil
    @State private var editingEntry: JournalEntry? = nil
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Journal")
                        .font(styles.typography.title1)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, styles.layout.topSafeAreaPadding)
                .padding(.bottom, 16)
                
                // Journal entries
                ScrollView {
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
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Extra padding for floating button
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
                            .background(styles.colors.accent)
                            .clipShape(Circle())
                            .shadow(color: styles.colors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showingNewEntrySheet) {
            NewEntryView(onSave: { text, mood in
                let newEntry = JournalEntry(text: text, mood: mood, date: Date())
                appState.journalEntries.insert(newEntry, at: 0)
                expandedEntryId = newEntry.id // Auto-expand new entry
            })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingEntry) { entry in
            EditEntryView(entry: entry, onSave: { updatedText, updatedMood in
                updateEntry(entry, newText: updatedText, newMood: updatedMood)
            })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func deleteEntry(_ entry: JournalEntry) {
        if let index = appState.journalEntries.firstIndex(where: { $0.id == entry.id }) {
            withAnimation {
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
                    // Mood icon
                    entry.mood.icon
                        .foregroundColor(entry.mood.color)
                        .font(.system(size: 20))
                    
                    // Lock icon if needed
                    if entry.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#FF6B6B"))
                    }
                    
                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(styles.colors.secondaryAccent)
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
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: styles.layout.iconSizeS))
                            Text("Delete")
                                .font(styles.typography.smallLabelFont)
                        }
                        .foregroundColor(styles.colors.error)
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
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: styles.layout.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .stroke(Color(hex: "#222222"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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
        NavigationView {
            ZStack {
                styles.colors.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: styles.layout.spacingXL) {
                    // Text editor
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $entryText)
                            .font(styles.typography.bodyLarge)
                            .padding(styles.layout.paddingM)
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(styles.colors.inputBackground)
                            .cornerRadius(styles.layout.radiusM)
                            .foregroundColor(styles.colors.text)
                        
                        if entryText.isEmpty {
                            Text("What's on your mind today?")
                                .font(styles.typography.bodyLarge)
                                .foregroundColor(styles.colors.placeholderText)
                                .padding(22)
                        }
                    }
                    
                    // Mood selector
                    VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                        Text("How are you feeling?")
                            .font(styles.typography.label)
                            .foregroundColor(styles.colors.textSecondary)
                        
                        HStack(spacing: styles.layout.spacingM) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                Button(action: {
                                    selectedMood = mood
                                }) {
                                    VStack(spacing: styles.layout.spacingS) {
                                        mood.icon
                                            .font(.system(size: styles.layout.iconSizeL))
                                            .foregroundColor(selectedMood == mood ? mood.color : styles.colors.textSecondary)
                                        
                                        Text(mood.name)
                                            .font(styles.typography.caption)
                                            .foregroundColor(selectedMood == mood ? styles.colors.text : styles.colors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, styles.layout.spacingM)
                                    .background(selectedMood == mood ? styles.colors.secondaryBackground : styles.colors.appBackground)
                                    .cornerRadius(styles.layout.radiusM)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(styles.layout.paddingXL)
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(styles.colors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(entryText, selectedMood)
                        dismiss()
                    }
                    .foregroundColor(styles.colors.accent)
                    .disabled(entryText.isEmpty)
                    .opacity(entryText.isEmpty ? 0.5 : 1.0)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct JournalView_Previews: PreviewProvider {
    static let previewAppState: AppState = {
        let appState = AppState()
        appState.loadSampleData()
        return appState
    }()
    
    static var previews: some View {
        JournalView().environmentObject(previewAppState)
    }
}