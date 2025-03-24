import SwiftUI

struct NewEntryView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (String, Mood) -> Void

    @State private var entryText: String = ""
    @State private var selectedMood: Mood = .neutral

    // Access shared styles
    private let styles = UIStyles.shared

    var body: some View {
        EntryFormView(
            title: "New Entry",
            onSave: {
                if !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onSave(entryText, selectedMood)
                    dismiss()
                }
            },
            saveButtonEnabled: !entryText.isEmpty
        ) {
            // Text editor with placeholder
            ZStack(alignment: .topLeading) {
                TextEditor(text: $entryText)
                    .font(styles.typography.bodyLarge)
                    .padding(styles.layout.paddingM)
                    .frame(maxWidth: .infinity, minHeight: 240)
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
                            .frame(maxWidth: .infinity)
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
            }
        }
    }
}

struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NewEntryView(onSave: { _, _ in })
    }
}
