import SwiftUI

struct ExpandableCard<Content: View, DetailContent: View>: View {
    let content: () -> Content
    let detailContent: () -> DetailContent
    @Binding var isExpanded: Bool
    let colors: UIStyles.Colors
    let typography: UIStyles.Typography
    let layout: UIStyles.Layout
    let isPrimary: Bool
    
    @State private var cardHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var isAnimating: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Preview content (always visible)
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
                detailContent()
                    .frame(height: isExpanded ? nil : 0)
                    .opacity(isExpanded ? 1 : 0)
                    .clipped()
            }
        }
        .padding(layout.cardInnerPadding)
        .background(
            RoundedRectangle(cornerRadius: layout.radiusL)
                .fill(colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: layout.radiusL)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isPrimary ? colors.accent.opacity(0.5) : colors.tertiaryBackground.opacity(0.5),
                                    isPrimary ? colors.accent.opacity(0.2) : colors.tertiaryBackground.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: isPrimary ? colors.accent.opacity(0.15) : Color.black.opacity(0.08),
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

// Preference key to measure content height
struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Extension to add a "show more" button to expandable cards
extension View {
    func withShowMoreButton(isExpanded: Binding<Bool>, colors: UIStyles.Colors, typography: UIStyles.Typography) -> some View {
        self.overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            isExpanded.wrappedValue.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded.wrappedValue ? "Show Less" : "Show More")
                                .font(typography.caption)
                                .foregroundColor(colors.accent)
                            
                            Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(colors.accent)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colors.tertiaryBackground.opacity(0.5))
                        )
                    }
                }
                .padding(.bottom, 8)
                .padding(.trailing, 8)
            }
        )
    }
}

