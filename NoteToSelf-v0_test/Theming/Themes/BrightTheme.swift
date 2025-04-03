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

    // Use Futura font
    let typography = ThemeTypography(
        headingFont: .custom("Futura-Bold", size: 36), // Futura Bold
        bodyFont: .custom("Futura-Medium", size: 16),    // Futura Medium
        smallLabelFont: .custom("Futura-Medium", size: 14),
        tinyHeadlineFont: .custom("Futura-Medium", size: 12),
        bodyLarge: .custom("Futura-Medium", size: 18),
        caption: .custom("Futura-Medium", size: 12),
        label: .custom("Futura-Medium", size: 14), // Medium for label
        bodySmall: .custom("Futura-Medium", size: 12),
        title1: .custom("Futura-Bold", size: 20),       // Futura Bold
        title3: .custom("Futura-Bold", size: 20),       // Futura Bold for semibold equivalent
        largeTitle: .custom("Futura-Bold", size: 34),   // Futura Bold
        navLabel: .custom("Futura-Medium", size: 10),   // Medium
        moodLabel: .custom("Futura-Medium", size: 14),  // Medium
        wheelplusminus: .custom("Futura-Medium", size: 24), // Medium
        sectionHeader: .custom("Futura-Bold", size: 18), // Futura Bold for semibold equivalent
        insightValue: .custom("Futura-Bold", size: 24),  // Futura Bold
        insightCaption: .custom("Futura-Medium", size: 14) // Medium
    )

    // Blur styles
    let blurStyleLight: UIBlurEffect.Style = .systemChromeMaterialLight
    let blurStyleDark: UIBlurEffect.Style = .systemChromeMaterialDark
}