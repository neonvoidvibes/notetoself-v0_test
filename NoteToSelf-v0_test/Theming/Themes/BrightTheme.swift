import SwiftUI

struct BrightTheme: Theme {
    let name = "Bright"

    let colors = ThemeColors(
        appBackground: Color("BrightAppBackground"),
        cardBackground: Color("BrightCardBackground"),
        menuBackground: Color("BrightMenuBackground"),
        secondaryBackground: Color("BrightSecondaryBackground"),
        tertiaryBackground: Color("BrightTertiaryBackground"),
        quaternaryBackground: Color("BrightQuaternaryBackground"),

        text: Color("BrightText"),
        textSecondary: Color("BrightTextSecondary"),
        textDisabled: Color("BrightTextDisabled"),
        placeholderText: Color("BrightPlaceholderText"),

        accent: Color("BrightAccent"),
        accentContrastText: Color("BrightAccentContrastText"),
        secondaryAccent: Color("BrightSecondaryAccent"),

        userBubbleColor: Color("BrightUserBubbleColor"),
        userBubbleText: Color("BrightUserBubbleText"),
        assistantBubbleColor: Color("BrightAssistantBubbleColor"),
        assistantBubbleText: Color("BrightAssistantBubbleText"),

        error: Color("BrightError"),
        divider: Color("BrightDivider"),

        // Mood colors remain standard

        // Specific UI Elements
        inputBackground: Color("BrightInputBackground"),
        inputFieldInnerBackground: Color("BrightInputFieldInnerBackground"),
        tabBarBackground: Color("BrightTabBarBackground"),
        bottomSheetBackground: Color("BrightBottomSheetBackground"),
        reflectionsNavBackground: Color("BrightReflectionsNavBackground"),
        statusBarBackground: Color("BrightStatusBarBackground"),

        // Button/icon colors
        primaryButtonText: Color("BrightPrimaryButtonText"),
        accentIconForeground: Color("BrightAccentIconForeground")
    )

    // Use .default font design (Inter/SF Pro)
    let typography = ThemeTypography(fontDesign: .default)

    // Blur styles
    let blurStyleLight: UIBlurEffect.Style = .systemChromeMaterialLight
    let blurStyleDark: UIBlurEffect.Style = .systemChromeMaterialDark
}