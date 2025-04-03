import SwiftUI

struct FullscreenEntryView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss

    // Optional callbacks for edit and delete actions
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    // Access to shared styles - Use @ObservedObject
    @ObservedObject private var styles = UIStyles.shared

    @State private var showingDeleteConfirmation = false

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
                                .font(styles.typography.bodyFont) // Use styles instance
                        }
                        .foregroundColor(styles.colors.accent) // Use styles instance
                    }

                    Spacer()

                    // Date display
                    Text(formatDate(entry.date))
                        .font(styles.typography.smallLabelFont) // Use styles instance
                        .foregroundColor(styles.colors.textSecondary) // Use styles instance
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

                            // Mood pill with formatted intensity
                            Text(formattedMoodText(entry.mood, intensity: entry.intensity))
                                .font(styles.typography.caption) // Use styles instance
                                .foregroundColor(styles.colors.text) // Use styles instance
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
                                            .font(styles.typography.caption) // Use styles instance
                                    }
                                    .foregroundColor(styles.colors.accent) // Use styles instance
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(styles.colors.secondaryBackground) // Use styles instance
                                    .cornerRadius(styles.layout.radiusM)
                                }
                            }

                            // Locked indicator if needed - icon only (Moved Before Delete)
                            if entry.isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(styles.colors.textSecondary) // Use styles instance
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(styles.colors.secondaryBackground) // Use styles instance
                                    .cornerRadius(styles.layout.radiusM)
                            }

                            // Delete button (if onDelete is provided) - icon only (Moved After Lock)
                            if onDelete != nil {
                                Button(action: {
                                    showingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: styles.layout.iconSizeS))
                                        .foregroundColor(styles.colors.textSecondary) // Use styles instance
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(styles.colors.secondaryBackground) // Use styles instance
                                        .cornerRadius(styles.layout.radiusM)
                                }
                            }
                        }
                        .padding(.horizontal, styles.layout.paddingXL)
                        .padding(.top, styles.layout.paddingL)

                        // Entry text
                        Text(entry.text)
                            .font(styles.typography.bodyLarge) // Use styles instance
                            .foregroundColor(styles.colors.text) // Use styles instance
                            .lineSpacing(8)
                            .padding(.horizontal, styles.layout.paddingXL)

                        Spacer(minLength: 100)
                    }
                }
            }
            // Delete confirmation modal
            if showingDeleteConfirmation {
                // Pass styles explicitly if needed, or ensure ConfirmationModal uses @ObservedObject
                ConfirmationModal(
                    title: "Delete Entry",
                    message: "Are you sure you want to delete this journal entry? This action cannot be undone.",
                    confirmText: "Delete",
                    confirmAction: {
                        showingDeleteConfirmation = false
                        onDelete?()
                    },
                    cancelAction: {
                        showingDeleteConfirmation = false
                    },
                    isDestructive: true
                )
                .animation(.spring(), value: showingDeleteConfirmation)
            }
        }
        // .preferredColorScheme(.dark) // REMOVED - Let theme handle it
    }

    private func formatDate(_ date: Date) -> String {
        return date.formatted(date: .long, time: .shortened)
    }

    private func formattedMoodText(_ mood: Mood, intensity: Int = 2) -> String {
        switch intensity {
        case 1: return "Slightly \(mood.name)"
        case 3: return "Very \(mood.name)"
        default: return mood.name
        }
    }
}

// MARK: - Editable Fullscreen Entry View
struct EditableFullscreenEntryView: View {
    var entry: JournalEntry?
    var initialMood: Mood = .neutral
    var onSave: (String, Mood, Int) -> Void
    var onDelete: (() -> Void)?
    var onCancel: (() -> Void)?
    var autoFocusText: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var entryText: String
    @State private var selectedMood: Mood
    @FocusState private var isTextFieldFocused: Bool
    @State private var showMoodSelector: Bool = false
    @State private var selectedIntensity: Int
    @State private var showingCancelConfirmation = false
    @State private var showingDeleteConfirmation = false

    private let date: Date
    private let isNewEntry: Bool
    private let isLocked: Bool

    // Access shared styles - Use @ObservedObject
    @ObservedObject private var styles = UIStyles.shared

    // Initializers remain the same, no styles passed here
    init(initialMood: Mood = .neutral, onSave: @escaping (String, Mood, Int) -> Void, onDelete: (() -> Void)? = nil, onCancel: (() -> Void)? = nil, autoFocusText: Bool = false) {
        self.initialMood = initialMood
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        self.autoFocusText = autoFocusText

        self._entryText = State(initialValue: "")
        self._selectedMood = State(initialValue: initialMood)
        self._selectedIntensity = State(initialValue: 2)
        self.date = Date()
        self.isNewEntry = true
        self.isLocked = false
    }

    init(entry: JournalEntry, onSave: @escaping (String, Mood, Int) -> Void, onDelete: (() -> Void)? = nil, onCancel: (() -> Void)? = nil, autoFocusText: Bool = true) {
        self.entry = entry
        self.initialMood = entry.mood
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        self.autoFocusText = autoFocusText

        self._entryText = State(initialValue: entry.text)
        self._selectedMood = State(initialValue: entry.mood)
        self._selectedIntensity = State(initialValue: entry.intensity)
        self.date = entry.date
        self.isNewEntry = false
        self.isLocked = entry.isLocked
    }

    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground // Use styles instance
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                    if showMoodSelector {
                        withAnimation { showMoodSelector = false }
                    }
                }

            VStack(spacing: 0) {
                // Custom navigation bar
                HStack {
                    Button(action: {
                        if !entryText.isEmpty {
                            showingCancelConfirmation = true
                        } else {
                            if let onCancel = onCancel {
                                onCancel()
                            } else {
                                dismiss()
                            }
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(styles.colors.text) // Use styles instance
                    }
                    Spacer()
                    Text(formatDate(date))
                        .font(styles.typography.smallLabelFont) // Use styles instance
                        .foregroundColor(styles.colors.textSecondary) // Use styles instance
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
                            Button(action: {
                                isTextFieldFocused = false
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showMoodSelector.toggle()
                                }
                            }) {
                                Text(formattedMoodText(selectedMood, intensity: selectedIntensity))
                                    .font(styles.typography.caption) // Use styles instance
                                    .foregroundColor(styles.colors.text) // Use styles instance
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
                            if !isNewEntry && onDelete != nil {
                                Button(action: {
                                    showingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: styles.layout.iconSizeS))
                                        .foregroundColor(styles.colors.textSecondary) // Use styles instance
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(styles.colors.secondaryBackground) // Use styles instance
                                        .cornerRadius(styles.layout.radiusM)
                                }
                            }
                        }
                        .padding(.horizontal, styles.layout.paddingXL)
                        .padding(.top, styles.layout.paddingL)

                        // Mood wheel selector panel
                        if showMoodSelector {
                            VStack {
                                // Ensure MoodWheel observes UIStyles if needed, or pass style info
                                MoodWheel(selectedMood: $selectedMood, selectedIntensity: $selectedIntensity)
                                    .padding(.horizontal, styles.layout.spacingM)
                            }
                            .background(styles.colors.secondaryBackground) // Use styles instance
                            .cornerRadius(styles.layout.radiusL)
                            .padding(.horizontal, styles.layout.paddingXL)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Text editor
                        TextEditor(text: $entryText)
                            .font(styles.typography.bodyLarge) // Use styles instance
                            .foregroundColor(styles.colors.text) // Use styles instance
                            .lineSpacing(8)
                            .padding(.horizontal, styles.layout.paddingXL - 5)
                            .frame(minHeight: 200)
                            .background(Color.clear) // Keep clear
                            .scrollContentBackground(.hidden) // Keep hidden
                            .focused($isTextFieldFocused)
                            .onChange(of: isTextFieldFocused) { oldValue, newValue in
                                if newValue {
                                    withAnimation { showMoodSelector = false }
                                }
                            }
                            .overlay(
                                Group {
                                    if entryText.isEmpty {
                                        Text("What's on your mind today?")
                                            .font(styles.typography.bodyLarge) // Use styles instance
                                            .foregroundColor(styles.colors.placeholderText) // Use styles instance
                                            .padding(.horizontal, styles.layout.paddingXL)
                                            .padding(.top, 8)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                            .allowsHitTesting(false)
                                    }
                                }
                            )
                        Spacer(minLength: 100)
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { _ in isTextFieldFocused = false }
                )
            }

            // Save button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if showMoodSelector {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showMoodSelector = false
                            }
                        }) {
                            Text("Confirm")
                                .font(styles.typography.bodyFont) // Use styles instance
                                .foregroundColor(styles.colors.accentContrastText) // Apply to Text
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(RoundedRectangle(cornerRadius: styles.layout.radiusM).fill(styles.colors.accent)) // Use styles instance
                        }
                        .tint(styles.colors.accentContrastText) // Apply tint to Button
                        .padding([.trailing, .bottom], 24)
                    } else {
                        Button(action: {
                            if !entryText.isEmpty {
                                onSave(entryText, selectedMood, selectedIntensity)
                                dismiss()
                            }
                        }) {
                            Text("Save")
                                .font(styles.typography.bodyFont) // Use styles instance
                                .foregroundColor(styles.colors.accentContrastText) // Apply to Text
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(RoundedRectangle(cornerRadius: styles.layout.radiusM).fill(styles.colors.accent)) // Use styles instance
                        }
                        .tint(styles.colors.accentContrastText) // Apply tint to Button
                        .disabled(entryText.isEmpty)
                        .opacity(entryText.isEmpty ? 0.5 : 1.0)
                        .padding([.trailing, .bottom], 24)
                    }
                }
            }
            // Cancel confirmation modal
            if showingCancelConfirmation {
                 // Pass styles explicitly if needed, or ensure ConfirmationModal uses @ObservedObject
                ConfirmationModal(
                    title: "Discard Changes",
                    message: "Are you sure you want to discard this journal entry? Your changes will be lost.",
                    confirmText: "Discard",
                    confirmAction: {
                        showingCancelConfirmation = false
                        if let onCancel = onCancel {
                            onCancel()
                        } else {
                            dismiss()
                        }
                    },
                    cancelAction: {
                        showingCancelConfirmation = false
                    },
                    isDestructive: true
                )
                .animation(.spring(), value: showingCancelConfirmation)
            }
            // Delete confirmation modal
            if showingDeleteConfirmation {
                 // Pass styles explicitly if needed, or ensure ConfirmationModal uses @ObservedObject
                ConfirmationModal(
                    title: "Delete Entry",
                    message: "Are you sure you want to delete this journal entry? This action cannot be undone.",
                    confirmText: "Delete",
                    confirmAction: {
                        showingDeleteConfirmation = false
                        onDelete?()
                        dismiss()
                    },
                    cancelAction: {
                        showingDeleteConfirmation = false
                    },
                    isDestructive: true
                )
                .animation(.spring(), value: showingDeleteConfirmation)
            }
        }
        // .preferredColorScheme(.dark) // REMOVED - Let theme handle it
        .onAppear {
            if autoFocusText {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
        }
    } // End body

    // Helper functions defined within the struct
    private func formatDate(_ date: Date) -> String {
        return date.formatted(date: .long, time: .shortened)
    }

    private func formattedMoodText(_ mood: Mood, intensity: Int = 2) -> String {
        switch intensity {
        case 1: return "Slightly \(mood.name)"
        case 3: return "Very \(mood.name)"
        default: return mood.name
        }
    }
} // End EditableFullscreenEntryView struct

struct FullscreenEntryView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data setup remains the same
        let sampleEntry = JournalEntry(
            text: "This is a sample journal entry with some text to preview how it would look in the fullscreen view. The text should be displayed prominently and be easy to read.",
            mood: .happy,
            date: Date()
        )

        Group {
            FullscreenEntryView(entry: sampleEntry)
                .previewDisplayName("View Mode")

            EditableFullscreenEntryView(entry: sampleEntry, onSave: { _, _, _ in })
                .previewDisplayName("Edit Mode")

            EditableFullscreenEntryView(onSave: { _, _, _ in })
                .previewDisplayName("New Entry Mode")
        }
         // Add environment object for preview if UIStyles is needed by previews
         .environmentObject(UIStyles.shared)
    }
}