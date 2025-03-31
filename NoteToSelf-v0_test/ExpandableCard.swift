import SwiftUI

struct ExpandableCard<Content: View, DetailContent: View>: View {
    // Content builders
    let content: () -> Content
    let detailContent: () -> DetailContent

    // State
    @Binding var isExpanded: Bool

    // Scroll Proxy for scroll-on-collapse
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    // Styling
    let colors: UIStyles.Colors
    let typography: UIStyles.Typography
    let layout: UIStyles.Layout
    let isPrimary: Bool

    // Internal state for animations
    @State private var contentHeight: CGFloat = 0
    @State private var detailContentHeight: CGFloat = 0
    @State private var isAnimating: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Ensure alignment is leading
            // Main content area with button overlay
            ZStack(alignment: .bottomTrailing) {
                // Main content (always visible)
                content()
                    .frame(maxWidth: .infinity, alignment: .leading) // Ensure content takes width
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ContentHeightPreferenceKey.self,
                                value: geometry.size.height
                            )
                        }
                    )
                    .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                        self.contentHeight = height
                    }

                // Expand/Collapse Button (only shown when not expanded)
                if !isExpanded {
                    ExpandCollapseButtonInternal(isExpanded: $isExpanded)
                        .padding(layout.paddingM) // Add padding around the button
                }
            }

            // Detail content (expandable)
            if isExpanded || isAnimating {
                 // Add the collapse button inside the details section as well
                 VStack(alignment: .leading, spacing: 0) { // Use VStack for detail content + button
                     Divider()
                         .background(colors.tertiaryBackground)
                         .padding(.vertical, 8)

                     detailContent()
                         .frame(maxWidth: .infinity, alignment: .leading) // Ensure content takes width

                     // Collapse Button at the bottom of details
                     HStack {
                         Spacer() // Push button to the right
                         ExpandCollapseButtonInternal(isExpanded: $isExpanded)
                     }
                     .padding(.top, layout.paddingM) // Add padding above button
                 }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
            }
        }
        .padding(layout.cardInnerPadding)
        .background(
            RoundedRectangle(cornerRadius: layout.radiusL)
                .fill(colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: layout.radiusL)
                        .strokeBorder(
                            colors.tertiaryBackground.opacity(0.5),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
        .contentShape(Rectangle()) // Keep whole card tappable
        .onTapGesture {
            toggleExpansion()
        }
    }

    // Function to handle toggling expansion and scrolling
    private func toggleExpansion() {
        let wasExpanded = isExpanded // Capture state before toggle
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isExpanded.toggle()
            if !isExpanded { // If collapsing
                isAnimating = true // Keep animating flag for smooth transition out
            }
        }

        // Scroll smoothly to top if collapsing
        if wasExpanded && !isExpanded, let proxy = scrollProxy, let id = cardId {
            withAnimation(.easeInOut(duration: 0.4)) { // Smooth animation
                proxy.scrollTo(id, anchor: .top)
            }
        }

        // Reset animation flag after animation completes if collapsed
        if !isExpanded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isAnimating = false
            }
        }
    }
}

// Internal button view to avoid cluttering ExpandableCard body
struct ExpandCollapseButtonInternal: View {
    @Binding var isExpanded: Bool
    private let styles = UIStyles.shared

    var body: some View {
        Button(action: {
            // Action handled by parent's onTapGesture or explicitly if needed
            // For now, this button relies on the parent tap gesture
            // To make it independent: add toggleExpansion() call here
        }) {
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: styles.layout.iconSizeS))
                Text(isExpanded ? "Close" : "Details")
                    .font(styles.typography.smallLabelFont)
            }
            .foregroundColor(styles.colors.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(styles.colors.secondaryBackground.opacity(0.8))
            .cornerRadius(styles.layout.radiusM)
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
        }
        // Ensure button taps don't interfere with the main card tap if they overlap
        .contentShape(Rectangle())
        // Prevent button tap from triggering parent tap gesture if needed
        // .allowsHitTesting(true) // Default is true
    }
}


// Height preference keys for measuring content (Unchanged)
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct DetailHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}