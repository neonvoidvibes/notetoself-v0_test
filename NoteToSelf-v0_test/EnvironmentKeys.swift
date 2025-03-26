import SwiftUI

// MARK: - Main Scrolling Disabled Key
struct MainScrollingDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

// MARK: - Settings Scrolling Disabled Key
struct SettingsScrollingDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

// MARK: - Bottom Sheet Expanded Key
struct BottomSheetExpandedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

// MARK: - Environment Values Extension
extension EnvironmentValues {
    var mainScrollingDisabled: Bool {
        get { self[MainScrollingDisabledKey.self] }
        set { self[MainScrollingDisabledKey.self] = newValue }
    }
    
    var settingsScrollingDisabled: Bool {
        get { self[SettingsScrollingDisabledKey.self] }
        set { self[SettingsScrollingDisabledKey.self] = newValue }
    }
    
    var bottomSheetExpanded: Bool {
        get { self[BottomSheetExpandedKey.self] }
        set { self[BottomSheetExpandedKey.self] = newValue }
    }
}

// MARK: - View Extension for Environment Modifiers
extension View {
    func mainScrollingDisabled(_ disabled: Bool) -> some View {
        environment(\.mainScrollingDisabled, disabled)
    }
    
    func settingsScrollingDisabled(_ disabled: Bool) -> some View {
        environment(\.settingsScrollingDisabled, disabled)
    }
    
    func bottomSheetExpanded(_ expanded: Bool) -> some View {
        environment(\.bottomSheetExpanded, expanded)
    }
}

