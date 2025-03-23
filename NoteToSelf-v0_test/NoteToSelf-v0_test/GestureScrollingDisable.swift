import SwiftUI

// EnvironmentKey for disabling scrolling in the main (background) content
private struct MainScrollingDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var mainScrollingDisabled: Bool {
        get { self[MainScrollingDisabledKey.self] }
        set { self[MainScrollingDisabledKey.self] = newValue }
    }
}

// EnvironmentKey for disabling scrolling in the settings view
private struct SettingsScrollingDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var settingsScrollingDisabled: Bool {
        get { self[SettingsScrollingDisabledKey.self] }
        set { self[SettingsScrollingDisabledKey.self] = newValue }
    }
}