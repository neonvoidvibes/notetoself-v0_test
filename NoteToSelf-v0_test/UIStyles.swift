import SwiftUI

struct UIStyles {
    static let shared = UIStyles()
    
    // MARK: - Colors
    let appBackground = Color(hex: "#000000")
    let cardBackground = Color("CardBackground")
    let accentColor = Color(hex: "#FFFF00")
    let secondaryAccentColor = Color(hex: "#989898")
    let textColor = Color("TextColor")
    let offWhite = Color(red: 0.95, green: 0.95, blue: 0.95)
    let entryBackground = Color(hex: "#0A0A0A")
    let secondaryBackground = Color(hex: "#111111")
    let tertiaryBackground = Color(hex: "#313131")
    let quaternaryBackground = Color(hex: "#555555")
    
    // Mood colors dictionary for mood tracking
    let moodColors: [String: Color] = [
        "Happy": Color(red: 1.0, green: 0.84, blue: 0.0),
        "Neutral": Color.gray,
        "Sad": Color.blue,
        "Stressed": Color(red: 0.8, green: 0.0, blue: 0.0),
        "Excited": Color.orange
    ]
    
    // MARK: - Typography
    let headingFont = Font.custom("Menlo", size: 36)
    let bodyFont = Font.custom("Menlo", size: 16)
    let smallLabelFont = Font.custom("Menlo", size: 14)
    let tinyHeadlineFont = Font.custom("Menlo", size: 12)
    
    // MARK: - Corners & Radii
    let defaultCornerRadius: CGFloat = 12
    let saveButtonCornerRadius: CGFloat = 30
}

struct ChatBubbleShape: Shape {
    var isUser: Bool
    func path(in rect: CGRect) -> Path {
        let path: UIBezierPath
        if isUser {
            path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: [.topLeft, .topRight, .bottomLeft],
                                cornerRadii: CGSize(width: UIStyles.shared.defaultCornerRadius, height: UIStyles.shared.defaultCornerRadius))
        } else {
            path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: [.topLeft, .topRight, .bottomRight],
                                cornerRadii: CGSize(width: UIStyles.shared.defaultCornerRadius, height: UIStyles.shared.defaultCornerRadius))
        }
        return Path(path.cgPath)
    }
}

struct BottomSheetStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationDetents([.height(420), .large])
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
    }
}

struct BreathingAnimation: ViewModifier {
    @State private var scale: CGFloat = 1.0
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(2.0 - scale)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.5
                }
            }
    }
}

extension UIStyles {
    var reflectionAssistantLoadingIndicator: some View {
        Circle()
            .fill(UIStyles.shared.offWhite)
            .frame(width: 20, height: 20)
            .modifier(BreathingAnimation())
    }
}

extension View {
    func applyBottomSheetStyle() -> some View {
        self.modifier(BottomSheetStyleModifier())
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

extension String {
    func baseMood() -> String {
        return self.components(separatedBy: "|").first ?? self
    }
    
    func moodOpacity() -> CGFloat {
        if let lastComponent = self.components(separatedBy: "|").last,
           let opacity = Double(lastComponent) {
            return CGFloat(opacity)
        }
        return 1.0
    }
}