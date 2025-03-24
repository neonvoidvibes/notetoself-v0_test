import SwiftUI

//Use `JournalEntryFormContent` as shared component for both new entries and editing existing entries

struct NewEntryView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (String, Mood) -> Void

    @State private var entryText: String = ""
    @State private var selectedMood: Mood = .neutral

    // Access shared styles
    private let styles = UIStyles.shared

    var body: some View {
        EntryFormView(
            title: "Add Note",
            onSave: {
                if !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onSave(entryText, selectedMood)
                    dismiss()
                }
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

struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NewEntryView(onSave: { _, _ in })
    }
}
