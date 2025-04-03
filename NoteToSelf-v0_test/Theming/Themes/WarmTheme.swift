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

    let typography = ThemeTypography(fontDesign: .default) // Use default (SF Pro) for non-mono

    // Blur styles (adjust as needed)
    let blurStyleLight: UIBlurEffect.Style = .systemMaterialLight
    let blurStyleDark: UIBlurEffect.Style = .systemMaterialDark
}