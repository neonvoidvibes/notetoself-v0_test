import SwiftUI

struct JournalView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingNewEntrySheet = false
    @State private var expandedEntryId: UUID? = nil
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background
            styles.colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Journal")
                        .font(styles.typography.title1)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                }
                .padding(.horizontal, styles.layout.paddingXL)
                .padding(.top, styles.layout.paddingL)
                .padding(.bottom, styles.layout.paddingM)
                
                // Journal entries
                ScrollView {
                    LazyVStack(spacing: styles.layout.spacingM) {
                        ForEach(appState.journalEntries) { entry in
                            JournalEntryCard(
                                entry: entry,
                                isExpanded: expandedEntryId == entry.id,
                                onTap: {
                                    withAnimation(styles.animation.defaultAnimation) {
                                        expandedEntryId = expandedEntryId == entry.id ? nil : entry.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, styles.layout.paddingL)
                    .padding(.bottom, 100) // Extra padding for floating button
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
                            .font(.system(size: styles.layout.iconSizeL, weight: .bold))
                            .foregroundColor(styles.colors.buttonText)
                            .frame(width: styles.layout.floatingButtonSize, height: styles.layout.floatingButtonSize)
                            .background(styles.colors.accent)
                            .clipShape(Circle())
                            .shadow(color: styles.colors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, styles.layout.paddingXL)
                    .padding(.bottom, styles.layout.paddingXL)
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
    }
}

struct JournalEntryCard: View {
    let entry: JournalEntry
    let isExpanded: Bool
    let onTap: () -> Void
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header always visible
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                    Text(formatDate(entry.date))
                        .font(styles.typography.label)
                        .foregroundColor(styles.colors.textSecondary)
                    
                    if !isExpanded {
                        Text(entry.text)
                            .lineLimit(1)
                            .font(styles.typography.body)
                            .foregroundColor(styles.colors.text)
                    }
                }
                
                Spacer()
                
                HStack(spacing: styles.layout.spacingM) {
                    // Mood icon
                    entry.mood.icon
                        .foregroundColor(entry.mood.color)
                        .font(.system(size: styles.layout.iconSizeM))
                    
                    // Lock icon if needed
                    if entry.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: styles.layout.iconSizeS))
                            .foregroundColor(styles.colors.lockIcon)
                    }
                    
                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: styles.layout.iconSizeS, weight: .bold))
                        .foregroundColor(styles.colors.textSecondary)
                }
            }
            .padding(.horizontal, styles.layout.paddingL)
            .padding(.vertical, styles.layout.paddingM)
            
            // Expanded content
            if isExpanded {
                Divider()
                    .background(styles.colors.divider)
                    .padding(.horizontal, styles.layout.paddingM)
                
                Text(entry.text)
                    .font(styles.typography.body)
                    .foregroundColor(styles.colors.text)
                    .padding(.horizontal, styles.layout.paddingL)
                    .padding(.vertical, styles.layout.paddingM)
            }
        }
        .background(styles.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: styles.layout.radiusL))
        .overlay(
            RoundedRectangle(cornerRadius: styles.layout.radiusL)
                .stroke(styles.colors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onTapGesture {
            onTap()
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

struct NewEntryView: View {
    let onSave: (String, Mood) -> Void
    
    @State private var entryText: String = ""
    @State private var selectedMood: Mood = .neutral
    @Environment(\.dismiss) private var dismiss
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                styles.colors.background
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
                                    .background(selectedMood == mood ? styles.colors.moodSelectedBackground : styles.colors.moodBackground)
                                    .cornerRadius(styles.layout.radiusM)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(styles.layout.paddingXL)
            }
            .navigationTitle("New Entry")
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
    static var previews: some View {
        let appState = AppState()
        appState.loadSampleData()
        
        return JournalView()
            .environmentObject(appState)
    }
}
