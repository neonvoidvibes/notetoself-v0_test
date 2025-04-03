import SwiftUI

struct AuraTheme: Theme {
    let name = "Aura"

    let colors = ThemeColors(
        appBackground: Color("AuraAppBackground"),
        cardBackground: Color("AuraCardBackground"),
        menuBackground: Color("AuraMenuBackground"),
        secondaryBackground: Color("AuraSecondaryBackground"),
        tertiaryBackground: Color("AuraTertiaryBackground"),
        quaternaryBackground: Color("AuraQuaternaryBackground"),

        text: Color("AuraText"),
        textSecondary: Color("AuraTextSecondary"),
        textDisabled: Color("AuraTextDisabled"),
        placeholderText: Color("AuraPlaceholderText"),

        accent: Color("AuraAccent"),
        accentContrastText: Color("AuraAccentContrastText"),
        secondaryAccent: Color("AuraSecondaryAccent"),

        userBubbleColor: Color("AuraUserBubbleColor"),
        userBubbleText: Color("AuraUserBubbleText"),
        assistantBubbleColor: Color("AuraAssistantBubbleColor"),
        assistantBubbleText: Color("AuraAssistantBubbleText"),

        error: Color("AuraError"),
        divider: Color("AuraDivider"),

        // Mood colors remain standard

        // Specific UI Elements
        inputBackground: Color("AuraInputBackground"),
        inputFieldInnerBackground: Color("AuraInputFieldInnerBackground"),
        tabBarBackground: Color("AuraTabBarBackground"),
        bottomSheetBackground: Color("AuraBottomSheetBackground"),
        reflectionsNavBackground: Color("AuraReflectionsNavBackground"),
        statusBarBackground: Color("AuraStatusBarBackground"),

        // Button/icon colors
        primaryButtonText: Color("AuraPrimaryButtonText"),
        accentIconForeground: Color("AuraAccentIconForeground")
    )

    // Use .default font design (Inter/SF Pro)
    let typography = ThemeTypography(fontDesign: .default)

    // Blur styles
    let blurStyleLight: UIBlurEffect.Style = .systemMaterialLight // Softer blur
    let blurStyleDark: UIBlurEffect.Style = .systemMaterialDark   // Softer blur
}