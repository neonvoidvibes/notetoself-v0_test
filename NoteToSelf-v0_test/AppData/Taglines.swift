import Foundation

// Enum to identify the view type for taglines
enum ViewType {
    case journal, insights, reflect
}

struct Taglines {
    // Ensure 7 taglines for each view, ordered Mon-Sun
    static let journal: [String] = [
        "Just get it down.",         // Monday
        "Keep showing up.",          // Tuesday
        "Check in with yourself.",   // Wednesday
        "What just happened?",       // Thursday
        "You’re not performing.",    // Friday
        "Anything worth noting?",    // Saturday
        "One note at a time."        // Sunday
    ]

    static let insights: [String] = [
        "A little more clarity.",        // Monday
        "Track the signal, not the noise.", // Tuesday
        "Patterns don’t lie.",           // Wednesday
        "What’s beneath the surface?",   // Thursday
        "This is where things connect.", // Friday
        "Your mind leaves fingerprints.",// Saturday
        "See yourself clearer."          // Sunday
    ]

    static let reflect: [String] = [
        "Look twice at today.",         // Monday
        "Turn emotion into insight.",   // Tuesday
        "What touched you?",            // Wednesday
        "Some moments ask to be seen.", // Thursday
        "What stayed with you?",        // Friday
        "Meaning hides in the small.",  // Saturday
        "Not everything passes."        // Sunday
    ]

    // Function to get the tagline for a specific view type and day
    static func getTagline(for viewType: ViewType, on date: Date = Date()) -> String {
        let calendar = Calendar.current
        // Weekday: 1 = Sun, 2 = Mon, ..., 7 = Sat
        let weekday = calendar.component(.weekday, from: date)
        // Convert to 0-based index (0 = Mon, ..., 6 = Sun)
        let index = (weekday - 2 + 7) % 7

        switch viewType {
        case .journal:
            guard journal.indices.contains(index) else { return journal.first ?? "" }
            return journal[index]
        case .insights:
            guard insights.indices.contains(index) else { return insights.first ?? "" }
            return insights[index]
        case .reflect:
            guard reflect.indices.contains(index) else { return reflect.first ?? "" }
            return reflect[index]
        }
    }
}