import SwiftUI

struct CardContainer<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    init(cornerRadius: CGFloat = UIStyles.shared.layout.mainContentCornerRadius, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .background(styles.colors.cardBackground) // Use instance
            .clipShape(RoundedCorner(radius: cornerRadius, corners: [.bottomLeft, .bottomRight]))
            // Add a subtle shadow to enhance the 3D effect
            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5) // Shadow color can be themed later
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
