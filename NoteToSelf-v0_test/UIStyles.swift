import SwiftUI

struct UIStyles {
    static let shared = UIStyles()
    
    // MARK: - Colors
    struct Colors {
        let appBackground: Color = Color(hex: "#000000")
        let cardBackground: Color = Color("CardBackground")
        let accent: Color = Color(hex: "#FFFF00")
        let secondaryAccent: Color = Color(hex: "#989898")
        let text: Color = Color("TextColor")
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
    }
    let colors = Colors()
    
    // MARK: - Typography
    struct Typography {
        let headingFont: Font = Font.custom("Menlo", size: 36)
        let bodyFont: Font = Font.custom("Menlo", size: 16)
        let smallLabelFont: Font = Font.custom("Menlo", size: 14)
        let tinyHeadlineFont: Font = Font.custom("Menlo", size: 12)
        let bodyLarge: Font = Font.custom("Menlo", size: 18)
        let caption: Font = Font.custom("Menlo", size: 12)
        let label: Font = Font.custom("Menlo", size: 14)
        let bodySmall: Font = Font.custom("Menlo", size: 12)
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
        let iconSizeXL: CGFloat = 40
        let floatingButtonSize: CGFloat = 60
        let radiusL: CGFloat = 12
        let radiusM: CGFloat = 8
    }
    let layout = Layout()
    
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
    
    func PrimaryButtonStyle() -> some ButtonStyle {
        return PrimaryButtonStyle(colors: colors, typography: typography, layout: layout)
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
    
    func SecondaryButtonStyle() -> some ButtonStyle {
        return SecondaryButtonStyle(colors: colors, typography: typography, layout: layout)
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
    
    func GhostButtonStyle() -> some ButtonStyle {
        return GhostButtonStyle(colors: colors, typography: typography, layout: layout)
    }
    
    // MARK: - Card Style Helper
    func card<Content: View>(_ content: Content) -> some View {
        content
            .background(colors.cardBackground)
            .cornerRadius(layout.radiusL)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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