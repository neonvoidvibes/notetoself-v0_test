import SwiftUI

struct ExpandableCard<Content: View, DetailContent: View>: View {
    // Content builders
    let content: () -> Content
    let detailContent: () -> DetailContent
    
    // State
    @Binding var isExpanded: Bool
    
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
        VStack(spacing: 0) {
            // Main content (always visible)
            content()
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
        
            // Detail content (expandable)
            if isExpanded || isAnimating {
                VStack {
                    Divider()
                        .background(colors.tertiaryBackground)
                        .padding(.vertical, 8)
                
                    detailContent()
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
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isExpanded.toggle()
                isAnimating = true
            }
        
            // Reset animation flag after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if !isExpanded {
                    isAnimating = false
                }
            }
        }
    }
}

// Height preference keys for measuring content
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

