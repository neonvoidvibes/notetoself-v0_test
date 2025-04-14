import SwiftUI

struct EntryPreviewPopupView: View {
    let entry: JournalEntry
    @Binding var isPresented: Bool
    let onExpand: () -> Void // Callback for the Expand button

    @ObservedObject private var styles = UIStyles.shared
    @Environment(\.colorScheme) private var colorScheme

    // Formatter for the date/time in the popup
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        ZStack {
            // Dimmed background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }

            // Popup Content Card
            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                // Header: Mood Icon and Date
                HStack {
                    entry.mood.icon
                        .foregroundColor(entry.mood.color)
                        .font(.system(size: 20))
                    Text(entry.date, formatter: dateFormatter)
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.textSecondary)
                    Spacer()
                    // Close Button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                    }
                }

                // Entry Text Preview
                Text(entry.text)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.text)
                    .lineLimit(4) // Show a few lines

                // Expand Button
                Button(action: onExpand) {
                    HStack {
                        Text("View Full Entry")
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    .font(styles.typography.bodyFont.weight(.medium))
                    .foregroundColor(styles.colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, styles.layout.paddingS)
                    .background(styles.colors.accent.opacity(0.1))
                    .cornerRadius(styles.layout.radiusM)
                }
                .buttonStyle(.plain) // Use plain style for custom background interaction
            }
            .padding(styles.layout.paddingL)
            .background(
                styles.colors.cardBackground // Use card background
                    .cornerRadius(styles.layout.radiusL)
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
            )
            .padding(.horizontal, styles.layout.paddingXL) // Add horizontal padding to constrain width
            .frame(maxWidth: 400) // Limit max width for larger screens/landscape
        }
    }
}

// Define PreviewContainer outside the #Preview block
fileprivate struct PreviewContainer: View {
    @State var showPopup = true
    // Pass the entry to the container instead of capturing
    let entry: JournalEntry

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if showPopup {
                EntryPreviewPopupView(entry: entry, isPresented: $showPopup) {
                    print("Expand tapped!")
                }
            }

            Button("Show Popup") { showPopup = true }
                .padding()
                .buttonStyle(.borderedProminent)
                .disabled(showPopup)

        }
         .environmentObject(UIStyles.shared)
         .environmentObject(ThemeManager.shared)
    }
}


#Preview {
    // Define sampleEntry here, accessible by PreviewContainer below
    let sampleEntry = JournalEntry(
        text: "This is a preview of the journal entry text. It might be quite long, so we should only show a few lines here to give the user an idea of the content before they decide to expand it fully.",
        mood: .happy,
        date: Date()
    )

    // Instantiate the container, passing the entry
    PreviewContainer(entry: sampleEntry)
}