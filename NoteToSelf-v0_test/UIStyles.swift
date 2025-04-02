import SwiftUI

// Make UIStyles ObservableObject to update UI on theme change
class UIStyles: ObservableObject {
    // Singleton instance
    static let shared = UIStyles()

    // Publish the current theme
    // private(set) makes it readable publicly but only settable via updateTheme
    @Published private(set) var currentTheme: Theme = MonoTheme() // Start with Mono theme

    // Computed property for colors, derived from the current theme
    var colors: ThemeColors {
        currentTheme.colors
    }

    // Computed property for typography, derived from the current theme
    var typography: ThemeTypography {
        currentTheme.typography
    }

    // Method to update the theme, triggering UI updates
    func updateTheme(_ newTheme: Theme) {
        guard newTheme.name != currentTheme.name else { return } // Avoid unnecessary updates
        currentTheme = newTheme
        print("[UIStyles] Theme updated to: \(newTheme.name)")
    }

    // MARK: - Layout (Remains unchanged for now)
    // Can remain static or become instance properties if needed later
    let layout = Layout()
    struct Layout {
        let paddingXL: CGFloat = 24
        let paddingL: CGFloat = 20
        let paddingM: CGFloat = 16
        let paddingS: CGFloat = 8
        let spacingXL: CGFloat = 24
        let spacingL: CGFloat = 20
        let spacingM: CGFloat = 16
        let spacingS: CGFloat = 8
        let spacingXS: CGFloat = 4
        let iconSizeL: CGFloat = 32
        let iconSizeM: CGFloat = 24
        let iconSizeS: CGFloat = 16
        let iconSizeXS: CGFloat = 12
        let iconSizeXL: CGFloat = 40
        let floatingButtonSize: CGFloat = 60
        let radiusL: CGFloat = 12
        let radiusM: CGFloat = 8
        let inputFieldCornerRadius: CGFloat = 16
        let inputOuterCornerRadius: CGFloat = 20
        let entryFormInputMinHeight: CGFloat = 240
        let entryFormInputMinHeightKeyboardOpen: CGFloat = 160
        let topSafeAreaPadding: CGFloat = 50
        let settingsMenuWidth: CGFloat = 300

        // Bottom sheet layout
        let bottomSheetPeekHeight: CGFloat = 40
        let bottomSheetPeekRadius: CGFloat = 20
        let bottomSheetFullHeight: CGFloat = 100
        let bottomSheetIndicatorWidth: CGFloat = 40
        let bottomSheetIndicatorHeight: CGFloat = 4
        let bottomSheetCornerRadius: CGFloat = 24
        let mainContentCornerRadius: CGFloat = 0

        let inputAreaHeight: CGFloat = 40

        // Card styling
        let cardSpacing: CGFloat = 32
        let cardInnerPadding: CGFloat = 24
        let cardShadowRadius: CGFloat = 8
        let cardShadowOpacity: CGFloat = 0.15

        // Section header spacing
        let sectionHeaderSpacing: CGFloat = 16
        let sectionBottomSpacing: CGFloat = 24
    }

    // MARK: - Animation (Remains unchanged for now)
    let animation = Animation()
    struct Animation {
        let defaultAnimation = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        let quickAnimation = SwiftUI.Animation.easeOut(duration: 0.2)
        let slowAnimation = SwiftUI.Animation.easeInOut(duration: 0.5)
        let bottomSheetAnimation = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        let tabSwitchAnimation = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
    }

    var headerPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: layout.paddingXL, bottom: layout.paddingM, trailing: layout.paddingXL)
    }

    // MARK: - Header Accent Bar
    func accentBar() -> some View {
        Rectangle()
            .fill(colors.accent) // Use theme color
            .frame(width: 20, height: 3)
    }

    // MARK: - Header Title with Accent Bar
    func headerTitleWithAccent(_ title: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(typography.title1) // Use theme typography
                .foregroundColor(colors.text) // Use theme color

            accentBar()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Button Styles
    // Button styles now implicitly use the computed 'colors' and 'typography'
    struct PrimaryButtonStyle: ButtonStyle {
        @ObservedObject var styles = UIStyles.shared // Observe singleton for theme changes

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(styles.typography.bodyFont.weight(.semibold))
                .padding(styles.layout.paddingM)
                .frame(maxWidth: .infinity)
                .background(styles.colors.accent) // Uses theme color
                .foregroundColor(Color.black) // Consider making button text color themeable?
                .cornerRadius(styles.layout.radiusM)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        }
    }

    struct SecondaryButtonStyle: ButtonStyle {
        @ObservedObject var styles = UIStyles.shared

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(styles.typography.bodyFont)
                .padding(styles.layout.paddingM)
                .frame(maxWidth: .infinity)
                .background(styles.colors.secondaryBackground) // Uses theme color
                .foregroundColor(styles.colors.text) // Uses theme color
                .cornerRadius(styles.layout.radiusM)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        }
    }

    struct GhostButtonStyle: ButtonStyle {
        @ObservedObject var styles = UIStyles.shared

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(styles.typography.bodyFont)
                .padding(styles.layout.paddingM)
                .foregroundColor(styles.colors.accent) // Uses theme color
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Card Style Helper
    func card<Content: View>(_ content: Content) -> some View {
        content
            .background(colors.cardBackground) // Use theme color
            .cornerRadius(layout.radiusL)
    }

    // MARK: - Bottom Sheet Style Helper
    func bottomSheet<Content: View>(_ content: Content) -> some View {
        content
            .background(colors.bottomSheetBackground) // Use theme color
            .cornerRadius(layout.bottomSheetCornerRadius)
    }

    // MARK: - Enhanced Card Style Helper
    func enhancedCard<Content: View>(_ content: Content, isPrimary: Bool = false) -> some View {
        content
            .background(colors.cardBackground) // Use theme color
            .cornerRadius(layout.radiusL)
            .shadow(
                color: Color.black.opacity(layout.cardShadowOpacity), // Shadow color could be themeable later
                radius: layout.cardShadowRadius,
                x: 0,
                y: isPrimary ? 6 : 4
            )
    }

    // MARK: - Section Header
    func sectionHeader(_ title: String) -> some View {
        VStack(spacing: layout.spacingXS) {
            HStack {
                Text(title)
                    .font(typography.sectionHeader) // Use theme typography
                    .foregroundColor(colors.text) // Use theme color

                Spacer()
            }

            Rectangle()
                .fill(colors.accent.opacity(0.3)) // Use theme color
                .frame(height: 1)
        }
        .padding(.horizontal, layout.paddingXL)
        .padding(.top, layout.sectionHeaderSpacing)
        .padding(.bottom, layout.spacingS)
    }

     // MARK: - Expandable Card Helper
    // Pass self (UIStyles instance) to ExpandableCard initializer
    func expandableCard<Content: View, DetailContent: View>(
        isExpanded: Binding<Bool>,
        isPrimary: Bool = false,
        scrollProxy: ScrollViewProxy? = nil,
        cardId: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder detailContent: @escaping () -> DetailContent
    ) -> some View {
        ExpandableCard(
            content: content,
            detailContent: detailContent,
            isExpanded: isExpanded,
            scrollProxy: scrollProxy,
            cardId: cardId,
            // Pass the current theme's components directly
            colors: self.colors,
            typography: self.typography,
            layout: self.layout,
            isPrimary: isPrimary
        )
    }

    // MARK: - Card Header Helper
    func cardHeader(title: String, icon: String) -> some View {
        HStack {
            Text(title)
                .font(typography.title3) // Use theme typography
                .foregroundColor(colors.text) // Use theme color

            Spacer()

            Image(systemName: icon)
                .foregroundColor(colors.accent) // Use theme color
                .font(.system(size: layout.iconSizeL))
        }
    }
}

// Keep Color(hex:) extension outside the class
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Default to black
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Initializer for adaptive colors (light/dark hex)
    init(lightHex: String, darkHex: String) {
        self.init(uiColor: UIColor(light: UIColor(hex: lightHex), dark: UIColor(hex: darkHex)))
    }
}

// Helper UIColor extension for adaptive colors
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }

    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                return light
            case .dark:
                return dark
            @unknown default:
                return light
            }
        }
    }
}


// MARK: - Custom Corner Radius Extension (Keep as is)
extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
      clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

// MARK: - Universal Main Card Style Modifier (Keep as is)
extension View {
  func mainCardStyle(isExpanded: Bool = false) -> some View {
      self
          .background(UIStyles.shared.colors.cardBackground) // Now uses theme color
          .clipShape(RoundedCorner(radius: UIStyles.shared.layout.mainContentCornerRadius, corners: [.bottomLeft, .bottomRight]))
          .shadow(color: Color.black.opacity(isExpanded ? 0 : 0.2), radius: 0, x: 0, y: 10)
  }
}

// MARK: - RoundedCorner Shape (Keep as is)
struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
      let path = UIBezierPath(
          roundedRect: rect,
          byRoundingCorners: corners,
          cornerRadii: CGSize(width: radius, height: radius)
      )
      return Path(path.cgPath)
  }
}

// REMOVED AdaptiveColorSchemeModifier