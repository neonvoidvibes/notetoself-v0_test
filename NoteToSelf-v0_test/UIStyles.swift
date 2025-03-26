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
    
    // Mood colors - updated for Russell's Circumplex Model
    let moodHappy: Color = Color(hex: "#66FF66")
    let moodNeutral: Color = Color(hex: "#CCCCCC")
    let moodSad: Color = Color(hex: "#CC33FF")
    let moodAnxious: Color = Color(hex: "#FF3399") // Renamed to distressed in the model
    let moodExcited: Color = Color(hex: "#99FF33")
    
    // Additional mood colors from the circumplex model
    let moodAlert: Color = Color(hex: "#CCFF00")
    let moodContent: Color = Color(hex: "#33FFCC")
    let moodRelaxed: Color = Color(hex: "#33CCFF")
    let moodCalm: Color = Color(hex: "#3399FF")
    let moodBored: Color = Color(hex: "#6666FF")
    let moodDepressed: Color = Color(hex: "#9933FF")
    let moodDistressed: Color = Color(hex: "#FF3399")
    let moodAngry: Color = Color(hex: "#FF3333")
    let moodTense: Color = Color(hex: "#FF9900")
    
    let inputBackground: Color = Color(hex: "#111111")
    let inputFieldInnerBackground: Color = Color.clear
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
    
    // Update the menu icon background color to be slightly brighter
    // In the Colors struct, add:
    let menuIconBackground: Color = Color(hex: "#222222") // Slightly brighter than black

    // Add a new property for the menu background
    let menuBackground: Color = Color(hex: "#111111") // Slightly brighter than app background
    
    // Navigation colors - updated with new app background and gradient colors
    let appBackgroundDarker: Color = Color(hex: "#1A1A1A") // Slightly darker gray for app background
    let navBackgroundTop: Color = Color(hex: "#1A1A1A") // Same as app background at top
    let navBackgroundBottom: Color = Color(hex: "#444444") // Brighter gray at bottom
    let navIconDefault: Color = Color(hex: "#666666") // Darker gray for non-selected icons
    let navIconSelected: Color = Color(hex: "#000000") // Black for selected icons
    let navSelectionCircle: Color = Color.white.opacity(0.3) // Light gray circle for selection
    
    // Chat bubble colors
    let userBubbleColor: Color = Color(hex: "#CCCCCC") // Light gray for user bubbles
    let userBubbleText: Color = Color.black // Black text for user bubbles
    let assistantBubbleColor: Color = Color.clear // Transparent for assistant bubbles
    let assistantBubbleText: Color = Color.white // White text for assistant bubbles
    let inputContainerBackground: Color = Color.black // Black for outer input container
    let inputAreaBackground: Color = Color.clear // Transparent for input area
    
    // Bottom nav area color for ReflectionsView
    let reflectionsNavBackground: Color = Color(hex: "#1A1A1A") // Gray for bottom nav in ReflectionsView
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
    let title1: Font = Font.system(size: 20, weight: .bold, design: .monospaced)
    let title3: Font = Font.system(size: 20, weight: .semibold, design: .monospaced)
    let largeTitle: Font = Font.system(size: 34, weight: .bold, design: .monospaced)
    let navLabel: Font = Font.system(size: 10, weight: .medium, design: .monospaced)
    let moodLabel: Font = Font.system(size: 14, weight: .medium, design: .monospaced)
    let wheelplusminus: Font = Font.system(size: 24, weight: .medium, design: .monospaced)

    // New properties for section headers and improved typography
    let sectionHeader: Font = Font.system(size: 18, weight: .semibold, design: .monospaced)
    let insightValue: Font = Font.system(size: 24, weight: .bold, design: .monospaced)
    let insightCaption: Font = Font.system(size: 14, weight: .medium, design: .monospaced)
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
    let inputFieldCornerRadius: CGFloat = 16
    let inputOuterCornerRadius: CGFloat = 20
    let entryFormInputMinHeight: CGFloat = 240
    let entryFormInputMinHeightKeyboardOpen: CGFloat = 160
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
    
    let inputAreaHeight: CGFloat = 40 // Fixed height for input area

    // New properties for improved card spacing and styling
    let cardSpacing: CGFloat = 32       // Increased spacing between cards (was using spacingXL = 24)
    let cardInnerPadding: CGFloat = 24  // Increased inner padding for cards (was paddingL = 20)
    let cardShadowRadius: CGFloat = 8   // Reduced shadow radius (was 15)
    let cardShadowOpacity: CGFloat = 0.15 // Reduced shadow opacity (was 0.2)
    
    // Section header spacing
    let sectionHeaderSpacing: CGFloat = 16
    let sectionBottomSpacing: CGFloat = 24
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
    EdgeInsets(top: 0, leading: layout.paddingXL, bottom: layout.paddingM, trailing: layout.paddingXL)
}

// Add a new function to create the accent bar
// Add this function inside the UIStyles struct, after the existing functions

// MARK: - Header Accent Bar
func accentBar() -> some View {
    Rectangle()
        .fill(colors.accent)
        .frame(width: 20, height: 3) // Reduced from 40 to 20 points
}

// MARK: - Header Title with Accent Bar
func headerTitleWithAccent(_ title: String) -> some View {
    VStack(spacing: 8) {
        Text(title)
            .font(typography.title1)
            .foregroundColor(colors.text)
        
        accentBar()
    }
    .frame(maxWidth: .infinity, alignment: .center)
    .padding(.top, 20)
    .padding(.bottom, 10)
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

// Add this new function to the UIStyles struct for consistent card styling
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

// Add this new component for section headers
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

