import SwiftUI

// Renamed from FocusTheme
struct FocusMainTheme: Theme {
    let name = "FocusMain" // Renamed

    let colors = ThemeColors(
        appBackground: Color("FocusMainAppBackground"),
        cardBackground: Color("FocusMainCardBackground"),
        menuBackground: Color("FocusMainMenuBackground"),
        secondaryBackground: Color("FocusMainSecondaryBackground"),
        tertiaryBackground: Color("FocusMainTertiaryBackground"),
        quaternaryBackground: Color("FocusMainQuaternaryBackground"),

        text: Color("FocusMainText"),
        textSecondary: Color("FocusMainTextSecondary"),
        textDisabled: Color("FocusMainTextDisabled"),
        placeholderText: Color("FocusMainPlaceholderText"),

        accent: Color("FocusMainAccent"),
        accentContrastText: Color("FocusMainAccentContrastText"),
        secondaryAccent: Color(hex: "F8D84A"), // NEW - Yellowish highlight
        tertiaryAccent: Color("FocusMainSecondaryAccent"), // RENAMED - Use the asset previously used by secondaryAccent (gray)

        userBubbleColor: Color("FocusMainUserBubbleColor"), // Use main gray bg
        userBubbleText: Color("FocusMainUserBubbleText"), // Use main text color
        assistantBubbleColor: Color("FocusMainAssistantBubbleColor"), // Use main gray bg
        assistantBubbleText: Color("FocusMainAssistantBubbleText"), // Use main text color

        error: Color("FocusMainError"),
        divider: Color("FocusMainDivider"),

        // Mood colors remain standard

        // Specific UI Elements
        inputBackground: Color("FocusMainInputBackground"),
        inputFieldInnerBackground: Color("FocusMainInputFieldInnerBackground"),
        tabBarBackground: Color("FocusMainTabBarBackground"),
        bottomSheetBackground: Color("FocusMainBottomSheetBackground"),
        reflectionsNavBackground: Color("FocusMainReflectionsNavBackground"),
        statusBarBackground: Color("FocusMainStatusBarBackground"),

        // Button/icon colors
        primaryButtonText: Color("FocusMainPrimaryButtonText"),
        accentIconForeground: Color("FocusMainAccentIconForeground"),

        // Journey Card Specific Inverted Text Colors
        // ASSUMES Asset Catalog entries exist:
        // "JourneyCardTextPrimary" (Light: Black, Dark: White)
        // "JourneyCardTextSecondary" (Light: Dark Gray, Dark: Light Gray)
        journeyCardTextPrimary: Color("JourneyCardTextPrimary"), // Hypothetical Asset Color
        journeyCardTextSecondary: Color("JourneyCardTextSecondary") // Hypothetical Asset Color
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