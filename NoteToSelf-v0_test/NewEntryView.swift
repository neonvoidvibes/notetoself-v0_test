import SwiftUI

struct NewEntryView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (String, Mood) -> Void
    
    @State private var entryText: String = ""
    @State private var selectedMood: Mood = .neutral
    
    // Access shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: styles.layout.spacingM) {
                Text("New Entry")
                    .font(styles.typography.title3)
                    .foregroundColor(styles.colors.text)
                
                TextEditor(text: $entryText)
                    .padding()
                    .background(styles.colors.secondaryBackground)
                    .cornerRadius(styles.layout.radiusM)
                    .foregroundColor(styles.colors.text)
                    .frame(height: 200)
                
                Picker("Mood", selection: $selectedMood) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        Text(mood.name).tag(mood)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Button("Save") {
                    guard !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        return
                    }
                    onSave(entryText, selectedMood)
                    dismiss()
                }
                .buttonStyle(UIStyles.PrimaryButtonStyle(
                    colors: styles.colors,
                    typography: styles.typography,
                    layout: styles.layout
                ))
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(styles.colors.accent)
                }
            }
            .background(styles.colors.appBackground.ignoresSafeArea())
        }
    }
}

struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NewEntryView(onSave: {_,_ in })
    }
}