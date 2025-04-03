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
    let typography = ThemeTypography(
        headingFont: .system(size: 36, weight: .bold, design: .default),
        bodyFont: .system(size: 16, weight: .regular, design: .default),
        smallLabelFont: .system(size: 14, weight: .regular, design: .default),
        tinyHeadlineFont: .system(size: 12, weight: .regular, design: .default),
        bodyLarge: .system(size: 18, weight: .regular, design: .default),
        caption: .system(size: 12, weight: .regular, design: .default),
        label: .system(size: 14, weight: .medium, design: .default),
        bodySmall: .system(size: 12, weight: .regular, design: .default),
        title1: .system(size: 20, weight: .bold, design: .default),
        title3: .system(size: 20, weight: .semibold, design: .default),
        largeTitle: .system(size: 34, weight: .bold, design: .default),
        navLabel: .system(size: 10, weight: .medium, design: .default),
        moodLabel: .system(size: 14, weight: .medium, design: .default),
        wheelplusminus: .system(size: 24, weight: .medium, design: .default),
        sectionHeader: .system(size: 18, weight: .semibold, design: .default),
        insightValue: .system(size: 24, weight: .bold, design: .default),
        insightCaption: .system(size: 14, weight: .medium, design: .default)
    )

    // Blur styles
    let blurStyleLight: UIBlurEffect.Style = .systemMaterialLight // Softer blur
    let blurStyleDark: UIBlurEffect.Style = .systemMaterialDark   // Softer blur
}