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
        secondaryAccent: Color("WarmSecondaryAccent"), // Muted Warm Gray/Brown

        userBubbleColor: Color("WarmUserBubbleColor"), // Light Warm Gray/Beige
        userBubbleText: Color("WarmUserBubbleText"), // Dark Brown/Gray
        assistantBubbleColor: Color("WarmAssistantBubbleColor"), // Use secondary background
        assistantBubbleText: Color("WarmAssistantBubbleText"), // Off-White/Light Beige

        error: Color("WarmError"), // Muted Red/Orange
        divider: Color("WarmDivider"), // Subtle Warm Gray

        // Mood colors (can adjust hues slightly for warmth, or keep originals)
        moodHappy: Color(hex: "#FFA726"), // Warmer Green/Orange
        moodNeutral: Color(hex: "#BCAAA4"), // Warm Gray
        moodSad: Color(hex: "#8D6E63"), // Muted Purple/Brown
        moodAnxious: Color(hex: "#FF8A65"), // Warm Pink/Coral
        moodExcited: Color(hex: "#FFB74D"), // Warm Yellow/Orange
        moodAlert: Color(hex: "#FFF176"), // Warm Yellow
        moodContent: Color(hex: "#AED581"), // Earthy Green
        moodRelaxed: Color(hex: "#81C784"), // Muted Green
        moodCalm: Color(hex: "#4DB6AC"), // Teal/Aqua
        moodBored: Color(hex: "#90A4AE"), // Blue Gray
        moodDepressed: Color(hex: "#795548"), // Deep Brown
        moodAngry: Color(hex: "#E57373"), // Muted Red
        moodStressed: Color(hex: "#FFB74D"), // Orange

        // Specific UI Elements
        inputBackground: Color("WarmInputBackground"),
        inputFieldInnerBackground: Color("WarmInputFieldInnerBackground"),
        tabBarBackground: Color("WarmTabBarBackground"), // Dark Warm Gray or match App Background Dark
        bottomSheetBackground: Color("WarmBottomSheetBackground"), // Medium Warm Gray
        reflectionsNavBackground: Color("WarmReflectionsNavBackground"), // Match Menu Background

        // New: Dedicated status bar background color
        statusBarBackground: Color("WarmStatusBarBackground") // Use the new asset
    )

    let typography = ThemeTypography(fontDesign: .default) // Use default (SF Pro) for non-mono

    // Blur styles (adjust as needed)
    let blurStyleLight: UIBlurEffect.Style = .systemMaterialLight
    let blurStyleDark: UIBlurEffect.Style = .systemMaterialDark
}