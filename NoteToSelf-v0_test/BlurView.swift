import SwiftUI

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style // Style is now provided

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: nil) // Start with no effect initially
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // Update the effect based on the provided style
        uiView.effect = UIBlurEffect(style: style)
    }
}

// Helper View Modifier to easily apply theme-aware blur
struct ThemeAwareBlur: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var styles = UIStyles.shared

    func body(content: Content) -> some View {
        content
            .background(
                BlurView(style: colorScheme == .dark ? styles.currentTheme.blurStyleDark : styles.currentTheme.blurStyleLight)
            )
    }
}

extension View {
    func themeAwareBlur() -> some View {
        self.modifier(ThemeAwareBlur())
    }
}