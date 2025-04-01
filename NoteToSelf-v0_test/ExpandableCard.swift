import SwiftUI

// Create a global state object to track which card is expanded
class ExpandableCardManager: ObservableObject {
    static let shared = ExpandableCardManager()
    @Published var expandedCardId: String? = nil
    
    func setExpandedCard(id: String?) {
        expandedCardId = id
    }
}

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
    // Use the theme-specific structs defined in ThemeProtocol.swift
    let colors: ThemeColors
    let typography: ThemeTypography
    let layout: UIStyles.Layout // Layout remains the same for now
    let isPrimary: Bool

    // Internal state for animations
    @State private var contentHeight: CGFloat = 0
    @State private var detailContentHeight: CGFloat = 0
    @State private var isAnimating: Bool = false
    @State private var hovered: Bool = false

    // Access to the shared card manager
    @StateObject private var cardManager = ExpandableCardManager.shared
    // Observe UIStyles for theme changes
    @ObservedObject private var internalStyles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content area with button overlay
            ZStack(alignment: .bottomTrailing) {
                // Main content (always visible)
                VStack(alignment: .leading, spacing: 0) {
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    
                    // Add padding at the bottom to make room for the button
                    if !isExpanded {
                        Spacer()
                            .frame(height: 70)
                    }
                }
            }
            
            // Expand button in its own container below content
            if !isExpanded {
                HStack {
                    Spacer()
                    ExpandCollapseButtonInternal(isExpanded: $isExpanded, hovered: hovered)
                        .opacity(hovered ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.2), value: hovered)
                        .onTapGesture {
                            toggleExpansion()
                        }
                }
                .padding(.top, -44)
                .padding(.bottom, 0)
                .padding(.trailing, 4)
            }

            // Detail content (expandable)
            if isExpanded || isAnimating {
                VStack(alignment: .leading, spacing: 0) {
                    // Animated divider
                    Divider()
                        .background(colors.divider.opacity(0.5)) // Use theme divider color
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
        
                    detailContent()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)

                    // Collapse Button at the bottom of details - match position with Details button
                    HStack {
                        Spacer()
                        ExpandCollapseButtonInternal(isExpanded: $isExpanded, hovered: hovered)
                            .scaleEffect(hovered ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
                            .onTapGesture {
                                toggleExpansion()
                            }
                    }
                    .padding(.top, layout.paddingM)
                    .padding(.bottom, 0)
                    .padding(.trailing, 4)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)
            }
        }
        .padding(layout.cardInnerPadding)
        .background(
            RoundedRectangle(cornerRadius: layout.radiusM)
                 // Use theme card background color
                .fill(colors.cardBackground)
                .shadow(
                    color: isPrimary ? colors.accent.opacity(0.15) : Color.black.opacity(0.15), // Shadow color can be themed
                    radius: 10,
                    x: 0,
                    y: 5
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: layout.radiusM)
                .strokeBorder(
                    // Use theme divider or accent color for border
                    isPrimary ? colors.accent.opacity(0.3) : colors.divider.opacity(0.5),
                    lineWidth: isPrimary ? 1.5 : 1
                )
        )
        .scaleEffect(hovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleExpansion()
        }
        .onHover { isHovered in
            hovered = isHovered
        }
        // Listen for changes to the expanded card ID
        .onChange(of: cardManager.expandedCardId) { oldValue, newValue in
            // If another card was expanded and this card is expanded, collapse this card
            if let newExpandedId = newValue, 
               let thisCardId = cardId, 
               newExpandedId != thisCardId && 
               isExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded = false
                    isAnimating = true
                }
                
                // Reset animation flag after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isAnimating = false
                }
            }
        }
    }

    // Function to handle toggling expansion and scrolling
    private func toggleExpansion() {
        let wasExpanded = isExpanded // Capture state before toggle
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isExpanded.toggle()
            
            // Update the global expanded card tracker
            if isExpanded, let id = cardId {
                cardManager.setExpandedCard(id: id)
            } else if !isExpanded && cardManager.expandedCardId == cardId {
                cardManager.setExpandedCard(id: nil)
            }
            
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

// Internal button view with enhanced styling
struct ExpandCollapseButtonInternal: View {
    @Binding var isExpanded: Bool
    var hovered: Bool
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                .font(.system(size: styles.layout.iconSizeS))
            Text(isExpanded ? "Close" : "Details")
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
        .contentShape(Rectangle())
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