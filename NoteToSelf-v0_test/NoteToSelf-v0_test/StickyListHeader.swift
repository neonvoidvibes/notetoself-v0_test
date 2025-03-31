import SwiftUI

/// A reusable view for section headers designed to be sticky within a SwiftUI `List`.
struct StickyListHeader: View {
    let title: String
    private let styles = UIStyles.shared

    var body: some View {
        Text(title)
            .font(styles.typography.title3)
            .foregroundColor(styles.colors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, styles.layout.paddingM)
            .padding(.top, 12) // Add top padding for sticky headers
            .padding(.bottom, 5)
            // These modifiers ensure proper appearance within a List
            .listRowInsets(EdgeInsets())
             // Use menuBackground for consistency across views using this header
            .background(styles.colors.menuBackground)
    }
}

#Preview {
    List {
        Section(header: StickyListHeader(title: "Sample Section")) {
            Text("Item 1")
            Text("Item 2")
        }
    }
    .listStyle(.plain)
    .background(Color.black)
    .preferredColorScheme(.dark)
}