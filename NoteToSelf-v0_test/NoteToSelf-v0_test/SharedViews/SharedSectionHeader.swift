import SwiftUI

/// A reusable view for section headers, designed for use in Lists or ScrollViews.
struct SharedSectionHeader: View {
    let title: String
    let backgroundColor: Color // Parameter to control background

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    // Initializer explicitly accepting the background color
    init(title: String, backgroundColor: Color) {
        self.title = title
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        // Wrap Text in HStack to apply padding only to text, allowing background full width
        HStack {
            Text(title)
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
            Spacer() // Push text to the left
        }
        // Increased padding to align with indented card content
        .padding(.leading, styles.layout.paddingL * 2)
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure HStack takes full width for background
        // REMOVED: .padding(.top, 12) - Removed in previous step
        // REMOVED: .padding(.bottom, 5) - Let font line height and LazyVStack spacing control gap
        .padding(.vertical, 8) // Apply some vertical padding for visual spacing within the background
        .listRowInsets(EdgeInsets()) // For List compatibility - important for sticky behavior
        .background(backgroundColor) // Apply the specific background color
    }
}

#Preview {
    // Example usage in different contexts
    VStack {
        List {
            Section(header: SharedSectionHeader(title: "Menu Section", backgroundColor: UIStyles.shared.colors.menuBackground)) {
                Text("Chat Item 1")
            }
            .listRowBackground(UIStyles.shared.colors.menuBackground)
        }
        .listStyle(.plain)
        .frame(height: 100)

        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) { // Set spacing to 0 here too
                Section(header: SharedSectionHeader(title: "App Section (Journal/Insights)", backgroundColor: UIStyles.shared.colors.appBackground)) {
                    Text("Journal Item 1")
                }
            }
        }
        .frame(height: 100)
    }
    .background(Color.gray)
    .preferredColorScheme(.dark)
}