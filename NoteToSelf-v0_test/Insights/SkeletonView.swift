import SwiftUI

struct SkeletonView: View {
    let height: CGFloat // Changed from private let to internal let (default)
    private var cornerRadius: CGFloat = UIStyles.shared.layout.radiusM
    @State private var isAnimating: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    // Explicit initializer (optional, but good practice for clarity)
    // Ensures 'height' is accessible
    init(height: CGFloat) {
        self.height = height
    }

    var body: some View {
        let baseColor = colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
        let highlightColor = colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.15)

        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [baseColor, highlightColor, baseColor]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(isAnimating ? 1 : 0.8) // Subtle opacity change
            )
            .frame(height: height)
            .modifier(AnimatingGradient(isAnimating: $isAnimating)) // Apply modifier
             .onAppear {
                  withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                      isAnimating = true
                  }
              }
    }
}

// Modifier for the animating gradient effect
struct AnimatingGradient: ViewModifier {
    @Binding var isAnimating: Bool
    private let start = UnitPoint(x: -1.5, y: 0.5) // Start off-screen left
    private let end = UnitPoint(x: 2.5, y: 0.5)   // End off-screen right

    func body(content: Content) -> some View {
        content
            .mask( // Mask the content with the gradient to make it shimmer
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0), // Start clear
                        .init(color: .black, location: 0.4), // Fade in to black (mask)
                        .init(color: .black, location: 0.6), // Stay black
                        .init(color: .clear, location: 1) // Fade out to clear
                    ]),
                    startPoint: isAnimating ? start : end, // Animate start/end points
                    endPoint: isAnimating ? end : start
                )
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        SkeletonView(height: 60)
        SkeletonView(height: 100)
        SkeletonView(height: 40)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}