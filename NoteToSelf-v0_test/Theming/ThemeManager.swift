import SwiftUI
import Combine

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var activeTheme: Theme
    // Add StandardTheme to the list
    let availableThemes: [Theme] = [MonoTheme(), WarmTheme(), StandardTheme()]

    private var currentThemeIndex = 0
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // TODO: Load saved theme index from UserDefaults if persistence is added
        self.activeTheme = availableThemes[currentThemeIndex]
        print("[ThemeManager] Initialized. Active theme: \(activeTheme.name)")

        // Observe changes from UIStyles if needed (or vice-versa)
        // For now, ThemeManager drives UIStyles
    }

    func setTheme(_ theme: Theme) {
        guard let index = availableThemes.firstIndex(where: { $0.name == theme.name }) else {
            print("[ThemeManager] Error: Theme '\(theme.name)' not found in availableThemes.")
            return
        }
        currentThemeIndex = index
        activeTheme = theme
        UIStyles.shared.updateTheme(theme) // Update UIStyles singleton
        print("[ThemeManager] Theme set to: \(activeTheme.name)")
        // TODO: Save theme index to UserDefaults if persistence is added
    }

    func cycleTheme() {
        currentThemeIndex = (currentThemeIndex + 1) % availableThemes.count
        setTheme(availableThemes[currentThemeIndex])
        print("[ThemeManager] Cycled theme.")
    }
}