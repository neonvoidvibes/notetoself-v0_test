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
        accentContrastText: Color("MonoAccentContrastText"), // Black/White
        secondaryAccent: Color("MonoSecondaryAccent"), // Existing #989898

        userBubbleColor: Color("MonoUserBubbleColor"), // Light gray #CCCCCC
        userBubbleText: Color("MonoUserBubbleText"), // Black
        assistantBubbleColor: Color("MonoAssistantBubbleColor"), // Use secondary background
        assistantBubbleText: Color("MonoAssistantBubbleText"), // White

        error: Color("MonoError"), // Use standard red
        divider: Color("MonoDivider"), // Existing #222222

        // Mood colors removed - use Mood.color

        // Specific UI Elements
        inputBackground: Color("MonoInputBackground"), // e.g., Reflections input area outer
        inputFieldInnerBackground: Color("MonoInputFieldInnerBackground"), // Often clear or same as secondary
        tabBarBackground: Color("MonoTabBarBackground"), // Black
        bottomSheetBackground: Color("MonoBottomSheetBackground"), // Dark Gray
        reflectionsNavBackground: Color("MonoReflectionsNavBackground"), // Dark Gray #1A1A1A

        // New: Dedicated status bar background color
        statusBarBackground: Color("MonoStatusBarBackground"), // Use the new asset

        // Initialize new button/icon colors
        primaryButtonText: Color("MonoPrimaryButtonText"),
        accentIconForeground: Color("MonoAccentIconForeground")
    )

    let typography = ThemeTypography(
        headingFont: .system(size: 36, weight: .bold, design: .monospaced),
        bodyFont: .system(size: 16, weight: .regular, design: .monospaced),
        smallLabelFont: .system(size: 14, weight: .regular, design: .monospaced),
        tinyHeadlineFont: .system(size: 12, weight: .regular, design: .monospaced),
        bodyLarge: .system(size: 18, weight: .regular, design: .monospaced),
        caption: .system(size: 12, weight: .regular, design: .monospaced),
        label: .system(size: 14, weight: .medium, design: .monospaced),
        bodySmall: .system(size: 12, weight: .regular, design: .monospaced),
        title1: .system(size: 20, weight: .bold, design: .monospaced),
        title3: .system(size: 20, weight: .semibold, design: .monospaced),
        largeTitle: .system(size: 34, weight: .bold, design: .monospaced),
        navLabel: .system(size: 10, weight: .medium, design: .monospaced),
        moodLabel: .system(size: 14, weight: .medium, design: .monospaced),
        wheelplusminus: .system(size: 24, weight: .medium, design: .monospaced),
        sectionHeader: .system(size: 18, weight: .semibold, design: .monospaced),
        insightValue: .system(size: 24, weight: .bold, design: .monospaced),
        insightCaption: .system(size: 14, weight: .medium, design: .monospaced)
    )

    // Blur styles
    let blurStyleLight: UIBlurEffect.Style = .systemUltraThinMaterialLight // Example
    let blurStyleDark: UIBlurEffect.Style = .systemUltraThinMaterialDark // Original
}