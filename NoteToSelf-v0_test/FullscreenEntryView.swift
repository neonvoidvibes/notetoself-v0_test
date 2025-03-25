import SwiftUI

struct FullscreenEntryView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    
    // Optional callbacks for edit and delete actions
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom navigation bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: styles.layout.spacingS) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(styles.colors.accent)
                    }
                    
                    Spacer()
                    
                    // Date display
                    Text(formatDate(entry.date))
                        .font(styles.typography.smallLabelFont)
                        .foregroundColor(styles.colors.textSecondary)
                }
                .padding(.horizontal, styles.layout.paddingXL)
                .padding(.top, styles.layout.topSafeAreaPadding)
                .padding(.bottom, styles.layout.paddingM)
                
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: styles.layout.spacingXL) {
                        // Header with mood and action buttons
                        HStack(spacing: styles.layout.spacingM) {
                            Spacer()
                            
                            // Mood pill - styled like in filter view
                            Text(entry.mood.name)
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.text)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                        .fill(entry.mood.color.opacity(0.3))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                        .stroke(entry.mood.color.opacity(0.5), lineWidth: 1)
                                )
                            
                            // Edit button (if not locked and onEdit is provided)
                            if !entry.isLocked && onEdit != nil {
                                Button(action: {
                                    onEdit?()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: styles.layout.iconSizeS))
                                        Text("Edit")
                                            .font(styles.typography.caption)
                                    }
                                    .foregroundColor(styles.colors.accent)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(styles.colors.secondaryBackground)
                                    .cornerRadius(styles.layout.radiusM)
                                }
                            }
                            
                            // Delete button (if onDelete is provided)
                            if onDelete != nil {
                                Button(action: {
                                    onDelete?()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                            .font(.system(size: styles.layout.iconSizeS))
                                        Text("Delete")
                                            .font(styles.typography.caption)
                                    }
                                    .foregroundColor(styles.colors.textSecondary) // Gray instead of red
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(styles.colors.secondaryBackground)
                                    .cornerRadius(styles.layout.radiusM)
                                }
                            }
                            
                            // Locked indicator if needed
                            if entry.isLocked {
                                HStack(spacing: styles.layout.spacingS) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14))
                                    Text("Locked")
                                }
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(styles.colors.secondaryBackground)
                                .cornerRadius(styles.layout.radiusM)
                            }
                        }
                        .padding(.horizontal, styles.layout.paddingXL)
                        .padding(.top, styles.layout.paddingL)
                        
                        // Entry text
                        Text(entry.text)
                            .font(styles.typography.bodyLarge)
                            .foregroundColor(styles.colors.text)
                            .lineSpacing(8)
                            .padding(.horizontal, styles.layout.paddingXL)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Editable Fullscreen Entry View
struct EditableFullscreenEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entryText: String
    @State private var selectedMood: Mood
    @FocusState private var isTextFieldFocused: Bool
    
    // For new entries, date is set to now
    // For editing, we keep the original date
    private let date: Date
    private let isNewEntry: Bool
    private let isLocked: Bool
    private let autoFocusText: Bool
    
    // Callback when saving
    var onSave: ((String, Mood) -> Void)?
    var onDelete: (() -> Void)?
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    // Initialize for new entry
    init(initialMood: Mood = .neutral, onSave: ((String, Mood) -> Void)? = nil, autoFocusText: Bool = false) {
        self._entryText = State(initialValue: "")
        self._selectedMood = State(initialValue: initialMood)
        self.date = Date()
        self.isNewEntry = true
        self.isLocked = false
        self.onSave = onSave
        self.onDelete = nil
        self.autoFocusText = autoFocusText
    }
    
    // Initialize for editing existing entry
    init(entry: JournalEntry, onSave: ((String, Mood) -> Void)? = nil, onDelete: (() -> Void)? = nil, autoFocusText: Bool = true) {
        self._entryText = State(initialValue: entry.text)
        self._selectedMood = State(initialValue: entry.mood)
        self.date = entry.date
        self.isNewEntry = false
        self.isLocked = entry.isLocked
        self.onSave = onSave
        self.onDelete = onDelete
        self.autoFocusText = autoFocusText
    }
    
    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom navigation bar - match the view mode exactly
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: styles.layout.spacingS) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text(isNewEntry ? "Cancel" : "Back")
                        }
                        .foregroundColor(styles.colors.accent)
                    }
                    
                    Spacer()
                    
                    // Show date for existing entries, title for new ones
                    if isNewEntry {
                        Text("New Entry")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                    } else {
                        Text(formatDate(date))
                            .font(styles.typography.smallLabelFont)
                            .foregroundColor(styles.colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Save button only visible when editing
                    if !isNewEntry || entryText.isEmpty {
                        // Invisible placeholder for layout balance
                        Text("Save")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(.clear)
                    } else {
                        // Actual save button
                        Button(action: {
                            if !entryText.isEmpty {
                                onSave?(entryText, selectedMood)
                                dismiss()
                            }
                        }) {
                            Text("Save")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.accent)
                        }
                        .disabled(entryText.isEmpty)
                        .opacity(entryText.isEmpty ? 0.5 : 1.0)
                    }
                }
                .padding(.horizontal, styles.layout.paddingXL)
                .padding(.top, styles.layout.topSafeAreaPadding)
                .padding(.bottom, styles.layout.paddingM)
                
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: styles.layout.spacingXL) {
                        // Header with mood and action buttons - match view mode exactly
                        HStack(spacing: styles.layout.spacingM) {
                            Spacer()
                            
                            // Mood pill - styled like in filter view
                            if !isNewEntry {
                                Text(selectedMood.name)
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.text)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                            .fill(selectedMood.color.opacity(0.3))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                            .stroke(selectedMood.color.opacity(0.5), lineWidth: 1)
                                    )
                            }
                            
                            // Save button for existing entries
                            if !isNewEntry {
                                Button(action: {
                                    if !entryText.isEmpty {
                                        onSave?(entryText, selectedMood)
                                        dismiss()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: styles.layout.iconSizeS))
                                        Text("Save")
                                            .font(styles.typography.caption)
                                    }
                                    .foregroundColor(styles.colors.accent)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(styles.colors.secondaryBackground)
                                    .cornerRadius(styles.layout.radiusM)
                                }
                                .disabled(entryText.isEmpty)
                                .opacity(entryText.isEmpty ? 0.5 : 1.0)
                            }
                            
                            // Delete button (if onDelete is provided)
                            if !isNewEntry && onDelete != nil {
                                Button(action: {
                                    onDelete?()
                                    dismiss()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                            .font(.system(size: styles.layout.iconSizeS))
                                        Text("Delete")
                                            .font(styles.typography.caption)
                                    }
                                    .foregroundColor(styles.colors.textSecondary) // Gray instead of red
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(styles.colors.secondaryBackground)
                                    .cornerRadius(styles.layout.radiusM)
                                }
                            }
                        }
                        .padding(.horizontal, styles.layout.paddingXL)
                        .padding(.top, styles.layout.paddingL)
                        
                        // Text editor - styled to match the text display in view mode
                        TextEditor(text: $entryText)
                            .font(styles.typography.bodyLarge)
                            .foregroundColor(styles.colors.text)
                            .lineSpacing(8)
                            .padding(.horizontal, styles.layout.paddingXL - 5) // Adjust padding to match text view
                            .frame(minHeight: 200)
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)
                            .focused($isTextFieldFocused)
                            .overlay(
                                Group {
                                    if entryText.isEmpty {
                                        Text("What's on your mind today?")
                                            .font(styles.typography.bodyLarge)
                                            .foregroundColor(styles.colors.placeholderText)
                                            .padding(.horizontal, styles.layout.paddingXL)
                                            .padding(.top, 8)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                            .allowsHitTesting(false)
                                    }
                                }
                            )
                        
                        // Mood selector - only show when creating a new entry
                        if isNewEntry {
                            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                Text("How are you feeling?")
                                    .font(styles.typography.label)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .padding(.horizontal, styles.layout.paddingXL)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: styles.layout.spacingM) {
                                        ForEach(Mood.allCases, id: \.self) { mood in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedMood = mood
                                                }
                                            }) {
                                                VStack(spacing: styles.layout.spacingS) {
                                                    mood.icon
                                                        .font(.system(size: styles.layout.iconSizeL))
                                                        .foregroundColor(selectedMood == mood ? mood.color : styles.colors.textSecondary)
                                                    Text(mood.name)
                                                        .font(styles.typography.caption)
                                                        .foregroundColor(selectedMood == mood ? styles.colors.text : styles.colors.textSecondary)
                                                }
                                                .frame(width: 80)
                                                .padding(.vertical, styles.layout.spacingM)
                                                .background(
                                                    RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                                        .fill(selectedMood == mood ? styles.colors.secondaryBackground : styles.colors.appBackground)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                                        .stroke(selectedMood == mood ? mood.color.opacity(0.5) : Color.clear, lineWidth: 1)
                                                )
                                                .scaleEffect(selectedMood == mood ? 1.05 : 1.0)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, styles.layout.paddingXL)
                                }
                            }
                            .padding(.top, styles.layout.spacingL)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                .onTapGesture {
                    // Only dismiss keyboard if we tap outside the text editor
                    if !isTextFieldFocused {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Auto-focus the text field and position cursor at the end
            if autoFocusText {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FullscreenEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntry = JournalEntry(
            text: "This is a sample journal entry with some text to preview how it would look in the fullscreen view. The text should be displayed prominently and be easy to read.",
            mood: .happy,
            date: Date()
        )
        
        Group {
            FullscreenEntryView(entry: sampleEntry)
                .previewDisplayName("View Mode")
            
            EditableFullscreenEntryView(entry: sampleEntry)
                .previewDisplayName("Edit Mode")
            
            EditableFullscreenEntryView()
                .previewDisplayName("New Entry Mode")
        }
    }
}

