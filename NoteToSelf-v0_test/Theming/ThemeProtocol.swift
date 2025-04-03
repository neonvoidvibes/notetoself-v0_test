import SwiftUI

// MARK: - Theme Protocol
protocol Theme {
    var name: String { get }
    var colors: ThemeColors { get }
    var typography: ThemeTypography { get }
    var blurStyleLight: UIBlurEffect.Style { get }
    var blurStyleDark: UIBlurEffect.Style { get }
}

// MARK: - Theme Colors Struct
// Holds all semantic color definitions for a theme.
// Colors MUST be adaptive (defined in Assets or using Color(light:dark:)).
struct ThemeColors {
    let appBackground: Color
    let cardBackground: Color
    let menuBackground: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let quaternaryBackground: Color // Added, used in older MoodWheel

    let text: Color
    let textSecondary: Color
    let textDisabled: Color
    let placeholderText: Color

    let accent: Color
    let accentContrastText: Color // Color for text on accent background
    let secondaryAccent: Color // Often gray

    let userBubbleColor: Color
    let userBubbleText: Color
    let assistantBubbleColor: Color
    let assistantBubbleText: Color

    let error: Color
    let divider: Color

    // Mood colors are now accessed via Mood.color which uses Asset Catalog

    // Specific UI Elements
    let inputBackground: Color // e.g., Reflections input area outer background
    let inputFieldInnerBackground: Color // Inner background for TextEditor/TextField
    let tabBarBackground: Color
    let bottomSheetBackground: Color
    let reflectionsNavBackground: Color // Specific bg for Reflections input area
    let statusBarBackground: Color

    // New colors for button text/icons
    let primaryButtonText: Color
    let accentIconForeground: Color
}

// MARK: - Theme Typography Struct
// Defines explicit semantic Font styles.
struct ThemeTypography {
    let headingFont: Font
    let bodyFont: Font
    let smallLabelFont: Font
    let tinyHeadlineFont: Font
    let bodyLarge: Font
    let caption: Font
    let label: Font
    let bodySmall: Font
    let title1: Font
    let title3: Font
    let largeTitle: Font
    let navLabel: Font
    let moodLabel: Font
    let wheelplusminus: Font
    let sectionHeader: Font
    let insightValue: Font
    let insightCaption: Font
}