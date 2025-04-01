## Document 21: Theming System Implementation Plan

**1. Goal:**

*   Implement a lightweight, scalable theming system allowing users (eventually) to select different visual themes for the app.
*   Each theme must support both light and dark color schemes automatically based on system settings.
*   The current dark mode styling will be established as the "Mono" theme's dark mode variant.
*   Changes should primarily affect colors and font types, keeping layout and core functionality unchanged.
*   Centralize theme definitions and implementations for easy maintenance and addition of new themes.
*   Provide a temporary developer-only mechanism to cycle through themes for testing.

**2. Architecture Proposal:**

1.  **`Theme` Protocol:** Define a protocol (`Theme`) that outlines the structure of a theme, including its color palette and typography settings. (`Theming/ThemeProtocol.swift`)
2.  **`ThemeColors` Struct:** A struct containing semantic color definitions (e.g., `appBackground`, `text`, `accent`). Each `Color` property within this struct *must* be adaptive, either using `Color(light: dark:)` or referencing a Named Color from `Assets.xcassets` which has light/dark variants defined.
3.  **`ThemeTypography` Struct:** A struct containing semantic font definitions (e.g., `title1`, `bodyFont`). This struct will allow specifying the font *design* (e.g., `.monospaced`, `.serif`, `.default`) while keeping semantic sizes/weights consistent.
4.  **Concrete Theme Structs:** Create specific structs conforming to the `Theme` protocol (e.g., `MonoTheme`, `PastelTheme`) within a dedicated folder (`Theming/Themes/`). Each struct will provide its specific `ThemeColors` and `ThemeTypography` implementations.
5.  **`ThemeManager`:** An `ObservableObject` singleton (`ThemeManager.shared`) responsible for holding the list of available themes and managing the currently active theme. It will publish changes to the active theme.
6.  **`UIStyles` Refactoring:**
    *   Modify the existing `UIStyles` singleton (`UIStyles.shared`) to become an `ObservableObject`.
    *   `UIStyles.shared` will hold a `@Published` property for the `currentTheme: Theme`.
    *   The `ThemeManager` will be responsible for updating `UIStyles.shared.currentTheme` when the active theme changes.
    *   The existing `colors` and `typography` properties within `UIStyles` will become computed properties, returning the values from `UIStyles.shared.currentTheme.colors` and `UIStyles.shared.currentTheme.typography`, respectively.
    *   Static properties like `layout` and `animation` in `UIStyles` will remain unchanged as they are not part of this theming phase.
    *   Views will continue to observe `UIStyles.shared` (e.g., `@ObservedObject private var styles = UIStyles.shared`) and automatically update when the theme changes.
7.  **Asset Catalog:** Utilize `Assets.xcassets` to define Named Colors for each theme (e.g., "MonoAppBackground", "PastelAccent"). Define both "Any Appearance" (Light) and "Dark Appearance" variants for each named color to enable automatic switching.
8.  **Developer Toggle:** Add a simple function call in a suitable location (e.g., `MainTabView.onAppear` or via a temporary button/gesture) to cycle through the themes managed by `ThemeManager`.

**3. Themeable Properties:**

*   **Colors:**
    *   `appBackground`: Overall background.
    *   `cardBackground`: Background for cards (journal entries, insights).
    *   `menuBackground`: Background for side menus/drawers (Settings, Chat History).
    *   `secondaryBackground`: Used for input fields, selected items, etc.
    *   `tertiaryBackground`: Used for dividers, subtle backgrounds.
    *   `text`: Primary text color.
    *   `textSecondary`: Secondary text color.
    *   `placeholderText`: Placeholder text color.
    *   `accent`: Primary accent color (buttons, highlights).
    *   `secondaryAccent`: Secondary accent (often gray, used for dates, subtle icons).
    *   `userBubbleColor`: Background for user chat bubbles.
    *   `userBubbleText`: Text color for user chat bubbles.
    *   `assistantBubbleColor`: Background for AI chat bubbles.
    *   `assistantBubbleText`: Text color for AI chat bubbles.
    *   `error`: Error indication color.
    *   `divider`: Color for dividers.
    *   `mood*`: Colors for each mood (can remain consistent or vary per theme).
    *   *(Self-suggestion)* `blurStyleLight`, `blurStyleDark`: Allow themes to specify `UIBlurEffect.Style` for light/dark modes. (Let's add this).
*   **Typography:**
    *   `fontDesign`: The primary `Font.Design` (e.g., `.monospaced`, `.serif`, `.rounded`, `.default`) to be applied to all semantic font styles (`title1`, `bodyFont`, etc.). Size and weight definitions within `UIStyles.Typography` remain.
*   **Other Suggestions:**
    *   Consider themeable icon styles later if needed (e.g., filled vs. outline), but keep it simple for now.

**4. Implementation Steps:**

1.  **Backup:** Create a full project backup.
2.  **Define Protocols/Structs:**
    *   Create `Theming/ThemeProtocol.swift` defining `Theme`, `ThemeColors`, and `ThemeTypography`.
    *   Ensure `ThemeColors` properties are `Color` and `ThemeTypography` specifies `fontDesign: Font.Design` and includes the semantic font properties (`title1`, `bodyFont`, etc.). Add `blurStyleLight`/`blurStyleDark` to `Theme`.
3.  **Create ThemeManager:**
    *   Create `Theming/ThemeManager.swift` with `@Published var activeTheme: Theme` and a list of available themes.
    *   Add `cycleTheme()` method for developer testing.
4.  **Refactor UIStyles:**
    *   Modify `UIStyles.swift` to be `class UIStyles: ObservableObject`.
    *   Replace `static let shared = UIStyles()` with `static let shared = UIStyles()`.
    *   Add `@Published private(set) var currentTheme: Theme = MonoTheme()` (using a default initially).
    *   Make `colors` and `typography` computed vars accessing `currentTheme`.
    *   Keep `layout` and `animation` structs as they are (can remain static or become instance properties, static is fine for now).
    *   Add `updateTheme(_ newTheme: Theme)` method.
    *   Modify helper methods (like `primaryButtonStyle`) to use the instance `colors` and `typography`.
    *   *(Self-correction)* Ensure views using `styles` now use `@ObservedObject private var styles = UIStyles.shared`.
5.  **Create Asset Colors:**
    *   In `Assets.xcassets`, create Named Colors for *all* semantic colors needed by `ThemeColors` for the "Mono" theme (e.g., "MonoAppBackground", "MonoText", "MonoAccent", "MonoCardBackground").
    *   For each Named Color, define color values for "Any Appearance" (Light) and "Dark Appearance". Start by matching the *existing* dark mode hex values for the "Dark Appearance" of the "Mono" colors. Choose sensible light mode counterparts (e.g., white background, dark text for Mono Light).
6.  **Implement MonoTheme:**
    *   Create `Theming/Themes/MonoTheme.swift`.
    *   Implement `Theme`.
    *   In its `ThemeColors`, initialize colors using `Color("Mono...")` referencing the Assets.
    *   In its `ThemeTypography`, set `fontDesign = .monospaced` and define the fonts using a helper.
    *   Set appropriate `blurStyleLight`/`blurStyleDark`.
7.  **Implement Example Theme (e.g., Pastel):**
    *   Create corresponding Named Colors in Assets for "Pastel" (e.g., "PastelAppBackground"). Define light/dark variants.
    *   Create `Theming/Themes/PastelTheme.swift`.
    *   Implement `Theme` using `Color("Pastel...")` and perhaps `fontDesign = .default` or `.serif`.
    *   Set different blur styles if desired.
8.  **Connect ThemeManager & UIStyles:**
    *   Instantiate `ThemeManager` as `@StateObject` in `NoteToSelf_v0_testApp.swift`.
    *   Inject `ThemeManager` into the environment.
    *   Modify `ThemeManager`'s `setTheme` (or `init`) to call `UIStyles.shared.updateTheme(newTheme)`. Initialize `ThemeManager` with `MonoTheme` as default.
9.  **Update Views:**
    *   Ensure views using `styles` now use `@ObservedObject private var styles = UIStyles.shared`.
    *   Remove any `.preferredColorScheme(.dark)` modifiers from views to allow system/theme control. Exception: Maybe keep it on modal presentation sheets like `DatePickerSheetView` if they should always be dark regardless of theme? (Let's remove them generally first).
    *   Update `BlurView.swift` to accept a `UIBlurEffect.Style` and use the theme-provided style via `styles.currentTheme.blurStyleLight` / `styles.currentTheme.blurStyleDark` based on `@Environment(\.colorScheme)`.
10. **Add Developer Toggle:**
    *   In `NoteToSelf_v0_testApp.swift` or `MainTabView.swift`, add a line to call `themeManager.cycleTheme()` somewhere easily accessible during development (e.g., attached to a temporary button or `.onAppear` for testing). A simple way is to add it to the main `WindowGroup` body:
      ```swift
      WindowGroup {
          ContentView() // Your main view (e.g., MainTabView)
              .environmentObject(themeManager) // Ensure ThemeManager is available
              // Temporary Toggle - Tap status bar area (example)
              .onTapGesture(count: 3) { // Triple tap status bar area
                  themeManager.cycleTheme()
              }
      }
      ```
11. **Refactor Hardcoded Colors:** Search the project (especially `UIStyles.swift` initially) for `Color(hex: ...)` or direct color literals (`Color.red`, `Color.black`). Replace them with references to semantic colors from `styles.colors` (e.g., `styles.colors.appBackground`, `styles.colors.error`). The *definition* of these semantic colors now lives within the Theme structs and Assets.

**5. Testing:**

*   Build and run the app.
*   Verify the default "Mono" theme appears correctly in both light and dark system modes. Check backgrounds, text, accents, cards, chat bubbles.
*   Trigger the developer toggle (`themeManager.cycleTheme()`).
*   Verify the "Pastel" (or other example) theme applies correctly in both light and dark modes. Check colors *and* font type changes.
*   Test across different views (Journal, Insights, Reflections, Settings, Modals) to ensure consistent theme application.
*   Check for any visual regressions or unexpected color/font combinations.

**6. Future Considerations:**

*   Implement a user-facing theme selection UI in Settings.
*   Persist the user's selected theme choice (`UserDefaults` or similar).
*   Allow themes to customize more elements if needed (e.g., specific icon styles).
