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
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content (always visible)
            VStack {
                content()
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: HeightPreferenceKey.self,
                                value: geometry.size.height
                            )
                        }
                    )
            }
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                contentHeight = height
            }
            
            // Detail content (visible when expanded)
            if isExpanded {
                VStack {
                    detailContent()
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: DetailHeightPreferenceKey.self,
                                    value: geometry.size.height
                                )
                            }
                        )
                }
                .onPreferenceChange(DetailHeightPreferenceKey.self) { height in
                    detailContentHeight = height
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Expand/collapse button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(colors.accent)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(colors.tertiaryBackground)
                        )
                    
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(colors.cardBackground)
        .cornerRadius(layout.radiusL)
        .shadow(
            color: Color.black.opacity(layout.cardShadowOpacity),
            radius: layout.cardShadowRadius,
            x: 0,
            y: isPrimary ? 6 : 4
        )
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

