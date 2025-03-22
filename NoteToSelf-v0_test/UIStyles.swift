import SwiftUI

/// Central styling system for the Note to Self app
struct UIStyles {
    // MARK: - Color Palette
    
    struct Colors {
        // Base colors
        let background = Color.black
        let surface = Color(hex: "111111")
        let surfaceElevated = Color(hex: "1A1A1A")
        let border = Color(hex: "222222")
        let divider = Color(hex: "222222")
        
        // Text colors
        let text = Color.white
        let textSecondary = Color(hex: "999999")
        let textTertiary = Color(hex: "666666")
        let textDisabled = Color(hex: "444444")
        
        // Accent colors
        let accent = Color.yellow
        let accentSecondary = Color.yellow.opacity(0.7)
        let accentMuted = Color.yellow.opacity(0.3)
        
        // Status colors
        let success = Color(hex: "4CAF50")
        let warning = Color(hex: "FF9800")
        let error = Color(hex: "FF6B6B")
        let info = Color(hex: "2196F3")
        
        // Mood colors
        let moodHappy = Color.yellow
        let moodNeutral = Color.gray
        let moodSad = Color.blue
        let moodAnxious = Color.orange
        let moodExcited = Color.purple
        
        // Component-specific colors
        let cardBackground = Color(hex: "111111")
        let cardBorder = Color(hex: "222222")
        let inputBackground = Color(hex: "111111")
        let buttonBackground = Color.yellow
        let buttonText = Color.black
        let tabBarBackground = Color(hex: "0A0A0A")
        let tabBarInactive = Color(hex: "777777")
        let lockIcon = Color(hex: "FF6B6B")
        let placeholderText = Color(hex: "666666")
        let moodBackground = Color(hex: "111111")
        let moodSelectedBackground = Color(hex: "222222")
        let chatUserBubble = Color(hex: "222222")
        let chatAIBubble = Color(hex: "333333")
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Headings
        let largeTitle = Font.system(size: 34, weight: .bold, design: .monospaced)
        let title1 = Font.system(size: 28, weight: .bold, design: .monospaced)
        let title2 = Font.system(size: 22, weight: .bold, design: .monospaced)
        let title3 = Font.system(size: 20, weight: .bold, design: .monospaced)
        
        // Body text
        let bodyLarge = Font.system(size: 18, weight: .regular)
        let body = Font.system(size: 16, weight: .regular)
        let bodySmall = Font.system(size: 14, weight: .regular)
        
        // Special text
        let caption = Font.system(size: 12, weight: .medium)
        let button = Font.system(size: 16, weight: .semibold)
        let label = Font.system(size: 14, weight: .medium, design: .monospaced)
        let code = Font.system(size: 14, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Layout
    
    struct Layout {
        // Spacing
        let spacingXS: CGFloat = 4
        let spacingS: CGFloat = 8
        let spacingM: CGFloat = 16
        let spacingL: CGFloat = 24
        let spacingXL: CGFloat = 32
        let spacingXXL: CGFloat = 48
        
        // Padding
        let paddingS: CGFloat = 12
        let paddingM: CGFloat = 16
        let paddingL: CGFloat = 20
        let paddingXL: CGFloat = 24
        
        // Radius
        let radiusS: CGFloat = 8
        let radiusM: CGFloat = 12
        let radiusL: CGFloat = 16
        let radiusXL: CGFloat = 24
        let radiusCircle: CGFloat = 9999
        
        // Sizes
        let buttonHeight: CGFloat = 50
        let inputHeight: CGFloat = 56
        let iconSizeS: CGFloat = 16
        let iconSizeM: CGFloat = 20
        let iconSizeL: CGFloat = 24
        let iconSizeXL: CGFloat = 32
        let floatingButtonSize: CGFloat = 60
        
        // Shadows
        func shadowSmall() -> some View {
            return AnyView(
                Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        
        func shadowMedium() -> some View {
            return AnyView(
                Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
        }
        
        func shadowLarge() -> some View {
            return AnyView(
                Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
            )
        }
    }
    
    // MARK: - Animation
    
    struct Animation {
        let defaultAnimation = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        let quickAnimation = SwiftUI.Animation.easeOut(duration: 0.2)
        let slowAnimation = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
    
    // MARK: - Shared Instance
    
    static let shared = UIStyles()
    
    let colors = Colors()
    let typography = Typography()
    let layout = Layout()
    let animation = Animation()
    
    // MARK: - Component Styles
    
    // Card style
    func card<Content: View>(_ content: Content) -> some View {
        content
            .background(colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: layout.radiusL))
            .overlay(
                RoundedRectangle(cornerRadius: layout.radiusL)
                    .stroke(colors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // Primary button style
    func primaryButton() -> some ButtonStyle {
        return PrimaryButtonStyle(colors: colors, typography: typography, layout: layout)
    }
    
    // Secondary button style
    func secondaryButton() -> some ButtonStyle {
        return SecondaryButtonStyle(colors: colors, typography: typography, layout: layout)
    }
    
    // Ghost button style
    func ghostButton() -> some ButtonStyle {
        return GhostButtonStyle(colors: colors, typography: typography, layout: layout)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let colors: UIStyles.Colors
    let typography: UIStyles.Typography
    let layout: UIStyles.Layout
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(typography.button)
            .foregroundColor(colors.buttonText)
            .frame(height: layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(colors.accent.opacity(configuration.isPressed ? 0.8 : 1))
            .cornerRadius(layout.radiusM)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let colors: UIStyles.Colors
    let typography: UIStyles.Typography
    let layout: UIStyles.Layout
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(typography.button)
            .foregroundColor(colors.accent)
            .frame(height: layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(colors.surface)
            .cornerRadius(layout.radiusM)
            .overlay(
                RoundedRectangle(cornerRadius: layout.radiusM)
                    .stroke(colors.accent, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    let colors: UIStyles.Colors
    let typography: UIStyles.Typography
    let layout: UIStyles.Layout
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(typography.button)
            .foregroundColor(colors.accent)
            .frame(height: layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Helper Extensions

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
            (a, r, g, b) = (1, 1, 1, 0)
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

struct Shadow: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: x, y: y)
    }
}
