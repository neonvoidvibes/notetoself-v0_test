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
    let secondaryAccent: Color // Often gray

    let userBubbleColor: Color
    let userBubbleText: Color
    let assistantBubbleColor: Color
    let assistantBubbleText: Color

    let error: Color
    let divider: Color

    // Mood colors - can be consistent or theme-specific
    let moodHappy: Color
    let moodNeutral: Color
    let moodSad: Color
    let moodAnxious: Color // Represents high-arousal negative
    let moodExcited: Color // Represents high-arousal positive
    let moodAlert: Color
    let moodContent: Color
    let moodRelaxed: Color
    let moodCalm: Color
    let moodBored: Color
    let moodDepressed: Color
    let moodAngry: Color
    let moodStressed: Color // Added, was missing

    // Specific UI Elements
    let inputBackground: Color // e.g., Reflections input area outer background
    let inputFieldInnerBackground: Color // Inner background for TextEditor/TextField
    let tabBarBackground: Color
    let bottomSheetBackground: Color
    let reflectionsNavBackground: Color // Specific bg for Reflections input area
}

// MARK: - Theme Typography Struct
// Defines the font design and semantic font styles.
struct ThemeTypography {
    let fontDesign: Font.Design

    // Semantic font styles (size/weight remain consistent, design changes)
    var headingFont: Font { Font.system(size: 36, weight: .bold, design: fontDesign) }
    var bodyFont: Font { Font.system(size: 16, weight: .regular, design: fontDesign) }
    var smallLabelFont: Font { Font.system(size: 14, weight: .regular, design: fontDesign) }
    var tinyHeadlineFont: Font { Font.system(size: 12, weight: .regular, design: fontDesign) } // Consider renaming?
    var bodyLarge: Font { Font.system(size: 18, weight: .regular, design: fontDesign) }
    var caption: Font { Font.system(size: 12, weight: .regular, design: fontDesign) }
    var label: Font { Font.system(size: 14, weight: .medium, design: fontDesign) }
    var bodySmall: Font { Font.system(size: 12, weight: .regular, design: fontDesign) }
    var title1: Font { Font.system(size: 20, weight: .bold, design: fontDesign) }
    var title3: Font { Font.system(size: 20, weight: .semibold, design: fontDesign) }
    var largeTitle: Font { Font.system(size: 34, weight: .bold, design: fontDesign) }
    var navLabel: Font { Font.system(size: 10, weight: .medium, design: fontDesign) }
    var moodLabel: Font { Font.system(size: 14, weight: .medium, design: fontDesign) }
    var wheelplusminus: Font { Font.system(size: 24, weight: .medium, design: fontDesign) }
    var sectionHeader: Font { Font.system(size: 18, weight: .semibold, design: fontDesign) }
    var insightValue: Font { Font.system(size: 24, weight: .bold, design: fontDesign) }
    var insightCaption: Font { Font.system(size: 14, weight: .medium, design: fontDesign) }
}