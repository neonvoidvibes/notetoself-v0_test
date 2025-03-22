//
//  NoteToSelf_v0_testApp.swift
//  NoteToSelf-v0_test
//
//  Created by Stefan Ekwall on 2025-03-22.
//

import SwiftUI

@main
struct NoteToSelf_v0_testApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        appState.loadSampleData()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
        }
    }
}
