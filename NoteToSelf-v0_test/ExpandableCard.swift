import SwiftUI

// Simplified Card View - No longer handles internal expansion state
struct ExpandableCard<Content: View>: View {
    // Content builder
    let content: () -> Content

    // Properties passed from UIStyles or parent view
    let colors: ThemeColors
     let typography: ThemeTypography
     let layout: UIStyles.Layout
     let showOpenButton: Bool // New parameter

     // Removed unused scrollProxy and cardId properties
     // var scrollProxy: ScrollViewProxy? = nil
     // var cardId: String? = nil

     // Internal state for hover effect
    @State private var hovered: Bool = false

     // Explicit Initializer
     init(
         @ViewBuilder content: @escaping () -> Content,
         // scrollProxy: ScrollViewProxy? = nil, // Removed
         // cardId: String? = nil, // Removed
         colors: ThemeColors,
         typography: ThemeTypography,
        layout: UIStyles.Layout,
        showOpenButton: Bool = true // Default to true
     ) {
         self.content = content
         // self.scrollProxy = scrollProxy // Removed
         // self.cardId = cardId // Removed
         self.colors = colors
         self.typography = typography
        self.layout = layout
        self.showOpenButton = showOpenButton // Assign new parameter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content area
            content()
                .frame(maxWidth: .infinity, alignment: .leading)

            // Conditionally show "Open" Button
            if showOpenButton {
                HStack {
                    Spacer()
                    ExpandCollapseButtonInternal(hovered: hovered) // Pass hover state
                        .opacity(hovered ? 1.0 : 0.85) // Slightly less fade when not hovered
                        .animation(.easeInOut(duration: 0.2), value: hovered)
                }
                 .padding(.trailing, 4)
                 .padding(.bottom, 4)
            }

        }
        .padding(layout.cardInnerPadding) // Apply inner padding to the content VStack
        .background(
            RoundedRectangle(cornerRadius: layout.radiusM)
                .fill(colors.cardBackground)
        )
        // BORDER OVERLAY using ACCENT color
        .overlay(
             RoundedRectangle(cornerRadius: layout.radiusM)
                 .stroke(colors.accent, lineWidth: 1) // CHANGED to accent color
         )
        .scaleEffect(hovered ? 1.01 : 1.0) // Keep hover scale effect
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
        .contentShape(Rectangle()) // Ensure the whole area is tappable
        .onHover { isHovered in // Keep hover state update
            hovered = isHovered
        }
    }
}

// Internal button view - Simplified for "Open" state only
fileprivate struct ExpandCollapseButtonInternal: View { // Make fileprivate
    var hovered: Bool // Needs hover state
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        HStack(spacing: 4) {
            Text("Open") // Text first
                .font(styles.typography.smallLabelFont)

            Image(systemName: "arrow.up.right") // Changed icon
                .font(.system(size: styles.layout.iconSizeS))

        }
        .foregroundColor(styles.colors.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .fill(styles.colors.secondaryBackground.opacity(0.8))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1) // Keep subtle shadow on button only
        )
        .overlay(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .strokeBorder(
                    styles.colors.accent.opacity(hovered ? 0.3 : 0.1),
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle()) // Ensure button itself is tappable if needed
    }
}

// Preview Provider
#Preview {
    ExpandableCard(
        content: {
            VStack(alignment: .leading) {
                Text("Preview Card Title").font(UIStyles.shared.typography.title3)
                Text("This is the preview content for the card.")
            }
        },
        colors: UIStyles.shared.colors,
        typography: UIStyles.shared.typography,
        layout: UIStyles.shared.layout,
        showOpenButton: true // Explicitly show in preview
    )
    .padding()
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
    .background(Color.gray.opacity(0.1))

}