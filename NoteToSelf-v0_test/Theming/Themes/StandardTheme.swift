import SwiftUI

struct StandardTheme: Theme {
    let name = "Standard"

    let colors = ThemeColors(
        appBackground: Color("StandardAppBackground"),
        cardBackground: Color("StandardCardBackground"),
        menuBackground: Color("StandardMenuBackground"),
        secondaryBackground: Color("StandardSecondaryBackground"),
        tertiaryBackground: Color("StandardTertiaryBackground"),
        quaternaryBackground: Color("StandardQuaternaryBackground"),

        text: Color("StandardText"),
        textSecondary: Color("StandardTextSecondary"),
        textDisabled: Color("StandardTextDisabled"),
        placeholderText: Color("StandardPlaceholderText"),

        accent: Color("StandardAccent"),
        accentContrastText: Color("StandardAccentContrastText"),
        secondaryAccent: Color("StandardSecondaryAccent"),

        userBubbleColor: Color("StandardUserBubbleColor"),
        userBubbleText: Color("StandardUserBubbleText"),
        assistantBubbleColor: Color("StandardAssistantBubbleColor"),
        assistantBubbleText: Color("StandardAssistantBubbleText"),

        error: Color("StandardError"),
        divider: Color("StandardDivider"),

        // Mood colors removed - use Mood.color

        // Specific UI Elements
        inputBackground: Color("StandardInputBackground"),
        inputFieldInnerBackground: Color("StandardInputFieldInnerBackground"),
        tabBarBackground: Color("StandardTabBarBackground"),
        bottomSheetBackground: Color("StandardBottomSheetBackground"),
        reflectionsNavBackground: Color("StandardReflectionsNavBackground"),
        statusBarBackground: Color("StandardStatusBarBackground"),

        // Initialize new button/icon colors
        primaryButtonText: Color("StandardPrimaryButtonText"),
        accentIconForeground: Color("StandardAccentIconForeground")
    )

    // Use .default font design (like Warm theme)
    let typography = ThemeTypography(fontDesign: .default)

    // Blur styles (same as Mono theme)
    let blurStyleLight: UIBlurEffect.Style = .systemUltraThinMaterialLight
    let blurStyleDark: UIBlurEffect.Style = .systemUltraThinMaterialDark
}