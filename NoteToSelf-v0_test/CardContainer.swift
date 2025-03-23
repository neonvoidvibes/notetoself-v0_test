import SwiftUI

struct CardContainer<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = UIStyles.shared.layout.mainContentCornerRadius, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .background(UIStyles.shared.colors.cardBackground)
            .clipShape(RoundedCorner(radius: cornerRadius, corners: [.bottomLeft, .bottomRight]))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

struct CardContainer_Previews: PreviewProvider {
    static var previews: some View {
        CardContainer {
            Text("Sample Content")
                .padding()
        }
        .padding()
        .background(Color.gray.opacity(0.3))
    }
}