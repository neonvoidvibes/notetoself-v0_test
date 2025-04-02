import SwiftUI

struct MonoTheme: Theme {
    let name = "Mono"

    let colors = ThemeColors(
        appBackground: Color("MonoAppBackground"),
        cardBackground: Color("MonoCardBackground"),
        menuBackground: Color("MonoMenuBackground"),
        secondaryBackground: Color("MonoSecondaryBackground"),
        tertiaryBackground: Color("MonoTertiaryBackground"),
        quaternaryBackground: Color("MonoQuaternaryBackground"), // Existing #555555

        text: Color("MonoText"),
        textSecondary: Color("MonoTextSecondary"),
        textDisabled: Color("MonoTextDisabled"),
        placeholderText: Color("MonoPlaceholderText"),

        accent: Color("MonoAccent"),
        secondaryAccent: Color("MonoSecondaryAccent"), // Existing #989898

        userBubbleColor: Color("MonoUserBubbleColor"), // Light gray #CCCCCC
        userBubbleText: Color("MonoUserBubbleText"), // Black
        assistantBubbleColor: Color("MonoAssistantBubbleColor"), // Use secondary background
        assistantBubbleText: Color("MonoAssistantBubbleText"), // White

        error: Color("MonoError"), // Use standard red
        divider: Color("MonoDivider"), // Existing #222222

        // Mood colors (can keep original hex for consistency across themes, or make them themeable)
        moodHappy: Color(hex: "#66FF66"),
        moodNeutral: Color(hex: "#CCCCCC"),
        moodSad: Color(hex: "#CC33FF"),
        moodAnxious: Color(hex: "#FF3399"),
        moodExcited: Color(hex: "#99FF33"),
        moodAlert: Color(hex: "#CCFF00"),
        moodContent: Color(hex: "#33FFCC"),
        moodRelaxed: Color(hex: "#33CCFF"),
        moodCalm: Color(hex: "#3399FF"),
        moodBored: Color(hex: "#6666FF"),
        moodDepressed: Color(hex: "#9933FF"),
        moodAngry: Color(hex: "#FF3333"),
        moodStressed: Color(hex: "#FF9900"),

        // Specific UI Elements
        inputBackground: Color("MonoInputBackground"), // e.g., Reflections input area outer
        inputFieldInnerBackground: Color("MonoInputFieldInnerBackground"), // Often clear or same as secondary
        tabBarBackground: Color("MonoTabBarBackground"), // Black
        bottomSheetBackground: Color("MonoBottomSheetBackground"), // Dark Gray
        reflectionsNavBackground: Color("MonoReflectionsNavBackground"), // Dark Gray #1A1A1A

        // New: Dedicated status bar background color
        statusBarBackground: Color("MonoStatusBarBackground") // Use the new asset
    )

    let typography = ThemeTypography(fontDesign: .monospaced)

    // Blur styles
    let blurStyleLight: UIBlurEffect.Style = .systemUltraThinMaterialLight // Example
    let blurStyleDark: UIBlurEffect.Style = .systemUltraThinMaterialDark // Original
}