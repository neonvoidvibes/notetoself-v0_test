import SwiftUI

struct UIStyles {
  static let shared = UIStyles()
  
  // MARK: - Colors
  struct Colors {
      let appBackground: Color = Color(hex: "#000000")
      let cardBackground: Color = Color("CardBackground")
      let accent: Color = Color(hex: "#FFFF00")
      let secondaryAccent: Color = Color(hex: "#989898")
      let text: Color = Color(hex: "#FFFFFF")
      let textSecondary: Color = Color(hex: "#999999")
      let offWhite: Color = Color(red: 0.95, green: 0.95, blue: 0.95)
      let entryBackground: Color = Color(hex: "#0A0A0A")
      let secondaryBackground: Color = Color(hex: "#111111")
      let tertiaryBackground: Color = Color(hex: "#313131")
      let quaternaryBackground: Color = Color(hex: "#555555")
      
      // Mood colors
      let moodHappy: Color = Color(red: 1.0, green: 0.84, blue: 0.0)
      let moodNeutral: Color = Color.gray
      let moodSad: Color = Color.blue
      let moodAnxious: Color = Color(red: 0.8, green: 0.0, blue: 0.0)
      let moodExcited: Color = Color.orange
      
      let inputBackground: Color = Color(hex: "#111111")
      let surface: Color = Color(hex: "#313131")
      let divider: Color = Color(hex: "#222222")
      let error: Color = Color.red
      let chatAIBubble: Color = Color(hex: "#555555")
      let buttonText: Color = Color("TextColor")
      let placeholderText: Color = Color(hex: "#999999")
      let textDisabled: Color = Color.gray.opacity(0.5)
      let tabBarBackground: Color = Color.black
      
      // Navigation sheet colors
        let bottomSheetBackground: Color = Color(hex: "#444444")
      let bottomSheetPeek: Color = Color(hex: "#222222")
      let bottomSheetIndicator: Color = Color(hex: "#444444")
      let bottomSheetShadow: Color = Color.black.opacity(0.3)
  }
  let colors = Colors()
  
  // MARK: - Typography
  struct Typography {
      // Changed all fonts to SF Mono
      let headingFont: Font = Font.system(size: 36, weight: .bold, design: .monospaced)
      let bodyFont: Font = Font.system(size: 16, weight: .regular, design: .monospaced)
      let smallLabelFont: Font = Font.system(size: 14, weight: .regular, design: .monospaced)
      let tinyHeadlineFont: Font = Font.system(size: 12, weight: .regular, design: .monospaced)
      let bodyLarge: Font = Font.system(size: 18, weight: .regular, design: .monospaced)
      let caption: Font = Font.system(size: 12, weight: .regular, design: .monospaced)
      let label: Font = Font.system(size: 14, weight: .medium, design: .monospaced)
      let bodySmall: Font = Font.system(size: 12, weight: .regular, design: .monospaced)
      let title1: Font = Font.system(size: 28, weight: .bold, design: .monospaced)
      let title3: Font = Font.system(size: 20, weight: .semibold, design: .monospaced)
      let largeTitle: Font = Font.system(size: 34, weight: .bold, design: .monospaced)
      let navLabel: Font = Font.system(size: 10, weight: .medium, design: .monospaced)
  }
  let typography = Typography()
  
  // MARK: - Layout
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
      let topSafeAreaPadding: CGFloat = 50 // Added for universal top padding
      let settingsMenuWidth: CGFloat = 300 // Width for the slide-in settings menu
      
      // Bottom sheet layout
      let bottomSheetPeekHeight: CGFloat = 40 // Height of the peeking portion
      let bottomSheetPeekRadius: CGFloat = 20 // Radius for the top corners
      let bottomSheetFullHeight: CGFloat = 100 // Height when fully expanded
      let bottomSheetIndicatorWidth: CGFloat = 40 // Width of the handle indicator
      let bottomSheetIndicatorHeight: CGFloat = 4 // Height of the handle indicator
      let bottomSheetCornerRadius: CGFloat = 24 // Corner radius of the bottom sheet
      let mainContentCornerRadius: CGFloat = 40 // Corner radius for the main content card
  }
  let layout = Layout()
  
  // MARK: - Animation
  struct Animation {
      let defaultAnimation = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
      let quickAnimation = SwiftUI.Animation.easeOut(duration: 0.2)
      let slowAnimation = SwiftUI.Animation.easeInOut(duration: 0.5)
      let bottomSheetAnimation = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
      let tabSwitchAnimation = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
  }
  let animation = Animation()
  
  var headerPadding: EdgeInsets {
      EdgeInsets(top: layout.topSafeAreaPadding, leading: layout.paddingXL, bottom: layout.paddingM, trailing: layout.paddingXL)
  }
  
  // MARK: - Button Styles
  struct PrimaryButtonStyle: ButtonStyle {
      let colors: Colors
      let typography: Typography
      let layout: Layout
      
      func makeBody(configuration: Configuration) -> some View {
          configuration.label
              .font(typography.bodyFont)
              .padding(layout.paddingM)
              .background(colors.accent)
              .foregroundColor(.black)
              .cornerRadius(layout.radiusM)
              .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      }
  }
  
  struct SecondaryButtonStyle: ButtonStyle {
      let colors: Colors
      let typography: Typography
      let layout: Layout
      
      func makeBody(configuration: Configuration) -> some View {
          configuration.label
              .font(typography.bodyFont)
              .padding(layout.paddingM)
              .background(colors.secondaryBackground)
              .foregroundColor(colors.text)
              .cornerRadius(layout.radiusM)
              .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      }
  }
  
  struct GhostButtonStyle: ButtonStyle {
      let colors: Colors
      let typography: Typography
      let layout: Layout
      
      func makeBody(configuration: Configuration) -> some View {
          configuration.label
              .font(typography.bodyFont)
              .padding(layout.paddingM)
              .foregroundColor(colors.accent)
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
}

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
          (a, r, g, b) = (255, 0, 0, 0)
      }
      self.init(
          .sRGB,
          red: Double(r) / 255,
          green: Double(g) / 255,
          blue: Double(b) / 255,
          opacity: Double(a) / 255
      )
  }
}

// MARK: - Custom Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Universal Main Card Style Modifier
extension View {
    func mainCardStyle() -> some View {
        self
            .background(UIStyles.shared.colors.cardBackground)
            .clipShape(RoundedCorner(radius: UIStyles.shared.layout.mainContentCornerRadius, corners: [.bottomLeft, .bottomRight]))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

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