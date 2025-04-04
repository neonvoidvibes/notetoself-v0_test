import SwiftUI

// Simplified Card View - No longer handles internal expansion state
struct ExpandableCard<Content: View>: View {
    // Content builder
    let content: () -> Content

    // Properties passed from UIStyles or parent view
    let colors: ThemeColors
    let typography: ThemeTypography
    let layout: UIStyles.Layout
    // scrollProxy and cardId might not be strictly needed now, but keep for potential future use cases
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    // Internal state for hover effect
    @State private var hovered: Bool = false

    // Explicit Initializer
    init(
        @ViewBuilder content: @escaping () -> Content,
        scrollProxy: ScrollViewProxy? = nil,
        cardId: String? = nil,
        colors: ThemeColors,
        typography: ThemeTypography,
        layout: UIStyles.Layout
    ) {
        self.content = content
        self.scrollProxy = scrollProxy
        self.cardId = cardId
        self.colors = colors
        self.typography = typography
        self.layout = layout
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content area
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                // Removed GeometryReader for height measuring as it's not needed for inline expansion anymore

            // Keep "Open" Button below content - positioned using padding
            HStack {
                Spacer()
                ExpandCollapseButtonInternal(hovered: hovered) // Pass hover state
                    .opacity(hovered ? 1.0 : 0.85) // Slightly less fade when not hovered
                    .animation(.easeInOut(duration: 0.2), value: hovered)
                    // The actual tap action to open the full screen is now handled
                    // by the parent view applying .onTapGesture to this ExpandableCard instance.
            }
            // Use padding to position the button relative to the VStack bottom edge
             .padding(.trailing, 4)
             .padding(.bottom, 4) // Adjust as needed

        }
        .padding(layout.cardInnerPadding) // Apply inner padding to the content VStack
        .background(
            RoundedRectangle(cornerRadius: layout.radiusM)
                .fill(colors.cardBackground)
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        )
        .scaleEffect(hovered ? 1.01 : 1.0) // Keep hover scale effect
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
        .contentShape(Rectangle()) // Ensure the whole area is tappable
        .onHover { isHovered in // Keep hover state update
            hovered = isHovered
        }
        // Removed internal expansion logic, state, and related functions/modifiers
    }
}

// Internal button view - Simplified for "Open" state only
fileprivate struct ExpandCollapseButtonInternal: View { // Make fileprivate
    var hovered: Bool // Needs hover state
    // Use @EnvironmentObject or pass styles if needed, using styles singleton for simplicity here
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        HStack(spacing: 4) {
            // Use a consistent icon for "Open", e.g., expand arrows or similar
            Image(systemName: "arrow.up.left.and.arrow.down.right") // Or "arrow.expand" etc.
                .font(.system(size: styles.layout.iconSizeS))
            Text("Open") // Always show "Open"
                .font(styles.typography.smallLabelFont)
        }
        .foregroundColor(styles.colors.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .fill(styles.colors.secondaryBackground.opacity(0.8))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
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
    // Need to provide necessary environment objects and parameters for preview
    ExpandableCard(
        content: {
            VStack(alignment: .leading) {
                Text("Preview Card Title").font(UIStyles.shared.typography.title3)
                Text("This is the preview content for the card.")
            }
        },
        colors: UIStyles.shared.colors,
        typography: UIStyles.shared.typography,
        layout: UIStyles.shared.layout
    )
    .padding()
    .environmentObject(UIStyles.shared) // Pass styles if button uses it directly
    .environmentObject(ThemeManager.shared)
    .background(Color.gray.opacity(0.1))

}