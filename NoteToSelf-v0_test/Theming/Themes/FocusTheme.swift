import SwiftUI

struct FocusTheme: Theme {
    let name = "Focus"

    let colors = ThemeColors(
        appBackground: Color("FocusAppBackground"),
        cardBackground: Color("FocusCardBackground"),
        menuBackground: Color("FocusMenuBackground"),
        secondaryBackground: Color("FocusSecondaryBackground"),
        tertiaryBackground: Color("FocusTertiaryBackground"),
        quaternaryBackground: Color("FocusQuaternaryBackground"),

        text: Color("FocusText"),
        textSecondary: Color("FocusTextSecondary"),
        textDisabled: Color("FocusTextDisabled"),
        placeholderText: Color("FocusPlaceholderText"),

        accent: Color("FocusAccent"),
        accentContrastText: Color("FocusAccentContrastText"),
        secondaryAccent: Color("FocusSecondaryAccent"),

        userBubbleColor: Color("FocusUserBubbleColor"), // Use main gray bg
        userBubbleText: Color("FocusUserBubbleText"), // Use main text color
        assistantBubbleColor: Color("FocusAssistantBubbleColor"), // Use main gray bg
        assistantBubbleText: Color("FocusAssistantBubbleText"), // Use main text color

        error: Color("FocusError"),
        divider: Color("FocusDivider"),

        // Mood colors remain standard

        // Specific UI Elements
        inputBackground: Color("FocusInputBackground"),
        inputFieldInnerBackground: Color("FocusInputFieldInnerBackground"),
        tabBarBackground: Color("FocusTabBarBackground"),
        bottomSheetBackground: Color("FocusBottomSheetBackground"),
        reflectionsNavBackground: Color("FocusReflectionsNavBackground"),
        statusBarBackground: Color("FocusStatusBarBackground"),

        // Button/icon colors
        primaryButtonText: Color("FocusPrimaryButtonText"),
        accentIconForeground: Color("FocusAccentIconForeground")
    )

    // Use Futura font (copied from BrightTheme)
    let typography = ThemeTypography(
        headingFont: .custom("Futura-Bold", size: 36),
        bodyFont: .custom("Futura-Medium", size: 16),
        smallLabelFont: .custom("Futura-Medium", size: 14),
        tinyHeadlineFont: .custom("Futura-Medium", size: 12),
        bodyLarge: .custom("Futura-Medium", size: 18),
        caption: .custom("Futura-Medium", size: 12),
        label: .custom("Futura-Medium", size: 14),
        bodySmall: .custom("Futura-Medium", size: 12),
        title1: .custom("Futura-Bold", size: 20),
        title3: .custom("Futura-Bold", size: 20),
        largeTitle: .custom("Futura-Bold", size: 34),
        navLabel: .custom("Futura-Medium", size: 10),
        moodLabel: .custom("Futura-Medium", size: 14),
        wheelplusminus: .custom("Futura-Medium", size: 24),
        sectionHeader: .custom("Futura-Bold", size: 18),
        insightValue: .custom("Futura-Bold", size: 24),
        insightCaption: .custom("Futura-Medium", size: 14)
    )

    // Blur styles (copied from BrightTheme)
    let blurStyleLight: UIBlurEffect.Style = .systemChromeMaterialLight
    let blurStyleDark: UIBlurEffect.Style = .systemChromeMaterialDark
}