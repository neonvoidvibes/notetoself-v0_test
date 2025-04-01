import SwiftUI

struct StickyHeaderView: View {
    let title: String
    var backgroundColor: Color? = nil
    var textColor: Color? = nil
    var topPadding: CGFloat = 16
    var bottomPadding: CGFloat = 8
    var horizontalPadding: CGFloat = 20

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    var body: some View {
        Text(title)
            .font(styles.typography.title3)
            .foregroundColor(textColor ?? styles.colors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .padding(.horizontal, horizontalPadding)
            .background(backgroundColor ?? styles.colors.appBackground)
    }
}

// Extension for sticky header behavior in ScrollView
extension View {
    func stickyHeader() -> some View {
        self
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ViewOffsetKey.self,
                            value: geo.frame(in: .global).minY
                        )
                }
            )
            .zIndex(1) // Ensure header stays on top
    }
}

struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct StickyHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StickyHeaderView(title: "Today")
                .previewLayout(.sizeThatFits)
                .background(UIStyles.shared.colors.appBackground)
            
            StickyHeaderView(title: "Yesterday", 
                           backgroundColor: Color.black.opacity(0.8),
                           textColor: .white)
                .previewLayout(.sizeThatFits)
        }
    }
}
