import SwiftUI

// Make UIStyles ObservableObject to update UI on theme change
class UIStyles: ObservableObject {
    // Singleton instance
    static let shared = UIStyles()

    // Publish the current theme
    // private(set) makes it readable publicly but only settable via updateTheme
    @Published private(set) var currentTheme: Theme = FocusMainTheme() // Start with theme

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
        let shimmerAnimation = SwiftUI.Animation.linear(duration: 1.5).repeatForever(autoreverses: false) // Shimmer specific
    }

    var headerPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: layout.paddingXL, bottom: layout.paddingM, trailing: layout.paddingXL)
    }

    // MARK: - Header Accent Bar
    func accentBar() -> some View {
        Rectangle()
            .fill(colors.accent) // Use theme color
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Glow Effect Modifier
    struct Glow: ViewModifier {
        @ObservedObject var styles = UIStyles.shared
        var radius: CGFloat = 10 // Default radius
        var isActive: Bool = true // Control whether the glow is active
    
        func body(content: Content) -> some View {
            content
                .shadow(color: isActive ? styles.colors.accent.opacity(0.6) : Color.clear, radius: radius / 2) // Inner subtle glow
                .shadow(color: isActive ? styles.colors.accent.opacity(0.4) : Color.clear, radius: radius)     // Outer wider glow
        }
    }
    
    extension View {
        func glow(radius: CGFloat = 10, isActive: Bool = true) -> some View {
            self.modifier(Glow(radius: radius, isActive: isActive))
        }
    }
    
    #Preview {
        // Example usage in different contexts
        VStack {
            List {
                Section(header: SharedSectionHeader(title: "Menu Section", backgroundColor: UIStyles.shared.colors.menuBackground)) {
                    Text("Chat Item 1")
                }
                .listRowBackground(UIStyles.shared.colors.menuBackground)
            }
            .listStyle(.plain)
            .frame(height: 100)
    
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) { // Set spacing to 0 here too
                    Section(header: SharedSectionHeader(title: "App Section (Journal/Insights)", backgroundColor: UIStyles.shared.colors.appBackground)) {
                        Text("Journal Item 1")
                    }
                }
            }
            .frame(height: 100)
    
            // Glow Preview
            HStack {
                Circle().fill(Color.blue).frame(width: 50, height: 50).glow(isActive: true)
                Circle().fill(Color.blue).frame(width: 50, height: 50).glow(isActive: false)
            }
            .padding()
    
        }
        .background(Color.gray)
        .preferredColorScheme(.dark)
    }
                let primaryButtonText: Color
        let accentIconForeground: Color
    
        let streakBarBackground: Color // NEW: For the bar behind streak dots
    
        // REMOVED Journey Card Specific Inverted Text Colors
        // let journeyCardTextPrimary: Color
        // let journeyCardTextSecondary: Color
    }
        @ObservedObject var styles = UIStyles.shared
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(styles.typography.bodyFont)
                .padding(styles.layout.paddingM)
                .frame(maxWidth: .infinity)
                .background(styles.colors.secondaryBackground)
                .foregroundColor(styles.colors.text)
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
                .foregroundColor(styles.colors.accent)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Card Style Helper
    func card<Content: View>(_ content: Content) -> some View {
        content
            .background(colors.cardBackground)
            .cornerRadius(layout.radiusL)
    }

    // MARK: - Bottom Sheet Style Helper
    func bottomSheet<Content: View>(_ content: Content) -> some View {
        content
            .background(colors.bottomSheetBackground)
            .cornerRadius(layout.bottomSheetCornerRadius)
    }

    // MARK: - Enhanced Card Style Helper
    func enhancedCard<Content: View>(_ content: Content, isPrimary: Bool = false) -> some View {
        content
            .background(colors.cardBackground)
            .cornerRadius(layout.radiusL)
            .shadow(
                color: Color.black.opacity(layout.cardShadowOpacity),
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
                    .font(typography.sectionHeader)
                    .foregroundColor(colors.text)
                Spacer()
            }
            Rectangle()
                .fill(colors.accent.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal, layout.paddingXL)
        .padding(.top, layout.sectionHeaderSpacing)
        .padding(.bottom, layout.spacingS)
    }

      // MARK: - Expandable Card Helper (Updated)
     func expandableCard<Content: View>(
         // scrollProxy: ScrollViewProxy? = nil, // Removed
         // cardId: String? = nil, // Removed
         showOpenButton: Bool = true, // Add parameter with default
         @ViewBuilder content: @escaping () -> Content
     ) -> some View {
         ExpandableCard( // Call the simplified ExpandableCard struct's explicit init
             content: content,
             // scrollProxy: scrollProxy, // Removed
             // cardId: cardId, // Removed
             colors: self.colors,
             typography: self.typography,
             layout: self.layout,
            showOpenButton: showOpenButton // Pass parameter through
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

// MARK: - Shimmer Effect [4.1]
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    @ObservedObject private var styles = UIStyles.shared // Access styles for animation

    // Define gradient colors based on theme's secondary background
    private var shimmerColor1: Color { styles.colors.secondaryBackground.opacity(0.3) }
    private var shimmerColor2: Color { styles.colors.secondaryBackground.opacity(0.1) }

    func body(content: Content) -> some View {
        content
            .modifier(AnimatedMask(phase: phase)
                // Use repeating animation without value
                .animation(styles.animation.shimmerAnimation) // REMOVED value: phase
            )
            .onAppear { phase = 0.8 } // Trigger animation on appear
    }

    // Sub-modifier for the animated mask
    struct AnimatedMask: AnimatableModifier {
        var phase: CGFloat = 0

        var animatableData: CGFloat {
            get { phase }
            set { phase = newValue }
        }

        func body(content: Content) -> some View {
            content
                .mask(GradientMask(phase: phase).scaleEffect(3))
        }
    }

    // Sub-view for the gradient mask
    struct GradientMask: View {
        let phase: CGFloat
        // Reuse shimmer colors defined in the main modifier
        @ObservedObject private var styles = UIStyles.shared
        private var shimmerColor1: Color { styles.colors.secondaryBackground.opacity(0.3) }
        private var shimmerColor2: Color { styles.colors.secondaryBackground.opacity(0.1) }


        var body: some View {
            LinearGradient(gradient: Gradient(stops: [
                .init(color: shimmerColor1, location: phase),
                .init(color: shimmerColor2, location: phase + 0.1),
                .init(color: shimmerColor1, location: phase + 0.2)
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// Extension to easily apply shimmer
extension View {
    @ViewBuilder func shimmer(_ condition: Bool = true) -> some View {
        if condition {
            modifier(Shimmer())
        } else {
            self
        }
    }
}