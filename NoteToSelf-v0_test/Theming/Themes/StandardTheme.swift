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

    // Blur styles (same as Mono theme)
    let blurStyleLight: UIBlurEffect.Style = .systemUltraThinMaterialLight
    let blurStyleDark: UIBlurEffect.Style = .systemUltraThinMaterialDark
}