import SwiftUI

struct WarmTheme: Theme {
    let name = "Warm"

    let colors = ThemeColors(
        appBackground: Color("WarmAppBackground"), // Light: Beige, Dark: Warm Dark Gray
        cardBackground: Color("WarmCardBackground"), // Light: Off-white, Dark: Darker Warm Gray
        menuBackground: Color("WarmMenuBackground"), // Light: Light Beige, Dark: Slightly lighter Warm Dark Gray
        secondaryBackground: Color("WarmSecondaryBackground"), // Light: Lighter Beige, Dark: Medium Warm Gray
        tertiaryBackground: Color("WarmTertiaryBackground"), // Light: Subtle Beige, Dark: Lighter Warm Gray
        quaternaryBackground: Color("WarmQuaternaryBackground"), // Adjusted for contrast

        text: Color("WarmText"), // Light: Dark Brown/Gray, Dark: Off-White/Light Beige
        textSecondary: Color("WarmTextSecondary"), // Light: Medium Brown/Gray, Dark: Light Gray/Beige
        textDisabled: Color("WarmTextDisabled"),
        placeholderText: Color("WarmPlaceholderText"),

        accent: Color("WarmAccent"), // Warm Orange/Terracotta
        accentContrastText: Color("WarmAccentContrastText"), // Dark Brown / Light Beige
        secondaryAccent: Color("WarmSecondaryAccent"), // Muted Warm Gray/Brown

        userBubbleColor: Color("WarmUserBubbleColor"), // Light Warm Gray/Beige
        userBubbleText: Color("WarmUserBubbleText"), // Dark Brown/Gray
        assistantBubbleColor: Color("WarmAssistantBubbleColor"), // Use secondary background
        assistantBubbleText: Color("WarmAssistantBubbleText"), // Off-White/Light Beige

        error: Color("WarmError"), // Muted Red/Orange
        divider: Color("WarmDivider"), // Subtle Warm Gray

        // Mood colors removed - use Mood.color

        // Specific UI Elements
        inputBackground: Color("WarmInputBackground"),
        inputFieldInnerBackground: Color("WarmInputFieldInnerBackground"),
        tabBarBackground: Color("WarmTabBarBackground"), // Dark Warm Gray or match App Background Dark
        bottomSheetBackground: Color("WarmBottomSheetBackground"), // Medium Warm Gray
        reflectionsNavBackground: Color("WarmReflectionsNavBackground"), // Match Menu Background

        // New: Dedicated status bar background color
        statusBarBackground: Color("WarmStatusBarBackground"), // Use the new asset

        // Initialize new button/icon colors
        primaryButtonText: Color("WarmPrimaryButtonText"),
        accentIconForeground: Color("WarmAccentIconForeground")
    )

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

    // Blur styles (adjust as needed)
    let blurStyleLight: UIBlurEffect.Style = .systemMaterialLight
    let blurStyleDark: UIBlurEffect.Style = .systemMaterialDark
}