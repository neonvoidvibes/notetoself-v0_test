import SwiftUI
import Combine

// Enum for Light/Dark/System preference
enum ThemeModePreference: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: String { self.rawValue }
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    // --- Theme Selection (FocusMain, Pastel, etc.) ---
    @Published private(set) var activeTheme: Theme
    let availableThemes: [Theme] = [FocusMainTheme()] // Add other themes here later
    private var currentThemeIndex = 0

    // --- Light/Dark Mode Preference ---
    @AppStorage("themeModePreference") private var storedPreferenceRaw: String = ThemeModePreference.system.rawValue
    @Published var themeModePreference: ThemeModePreference = .system

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Initialize active theme
        // TODO: Load saved theme index from UserDefaults if persistence is added for theme *selection*
        self.activeTheme = availableThemes[currentThemeIndex]
        print("[ThemeManager] Initialized. Active theme: \(activeTheme.name)")

        // Initialize theme mode preference from AppStorage
        if let loadedPreference = ThemeModePreference(rawValue: storedPreferenceRaw) {
            self.themeModePreference = loadedPreference
            print("[ThemeManager] Loaded theme mode preference: \(loadedPreference.rawValue)")
        } else {
            // Handle case where stored value is invalid, default to system
            self.themeModePreference = .system
            self.storedPreferenceRaw = ThemeModePreference.system.rawValue
             print("[ThemeManager] Invalid stored preference, defaulted to System.")
        }

        // Update UIStyles with the initial theme
        UIStyles.shared.updateTheme(self.activeTheme)

        // Set up publisher to save preference changes automatically
        $themeModePreference
            .dropFirst() // Ignore initial value emission
            .map { $0.rawValue } // Convert enum to rawValue String
            .sink { [weak self] rawValue in
                 print("[ThemeManager] Saving theme mode preference: \(rawValue)")
                self?.storedPreferenceRaw = rawValue
            }
            .store(in: &cancellables)

        print("[ThemeManager] Initial theme mode preference: \(self.themeModePreference.rawValue)")
    }

    // --- Theme Switching Methods ---

    // Method to change the *design theme* (FocusMain, Pastel, etc.)
    func setTheme(_ theme: Theme) {
        guard let index = availableThemes.firstIndex(where: { $0.name == theme.name }) else {
            print("[ThemeManager] Error: Theme '\(theme.name)' not found in availableThemes.")
            return
        }
        currentThemeIndex = index
        activeTheme = theme
        UIStyles.shared.updateTheme(theme) // Update UIStyles singleton
        print("[ThemeManager] Theme set to: \(activeTheme.name)")
        // TODO: Save theme index to UserDefaults if persistence is added for theme *selection*
    }

    // Developer method to cycle through *design themes*
    func cycleTheme() {
        currentThemeIndex = (currentThemeIndex + 1) % availableThemes.count
        setTheme(availableThemes[currentThemeIndex])
        print("[ThemeManager] Cycled design theme.")
    }

    // Method to set the *light/dark mode preference* (called by Picker)
    // Note: This is handled automatically by the @Published var triggering the sink now.
    // func setThemeModePreference(_ preference: ThemeModePreference) {
    //     themeModePreference = preference // This will trigger the sink to save to AppStorage
    //     print("[ThemeManager] Theme mode preference set to: \(preference.rawValue)")
    // }
}