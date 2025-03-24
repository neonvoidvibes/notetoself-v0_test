import SwiftUI

// Enum for date filter types
enum DateFilterType: String, CaseIterable, Identifiable {
    case all = "All Time"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case custom = "Custom Range"
    
    var id: String { self.rawValue }
}

