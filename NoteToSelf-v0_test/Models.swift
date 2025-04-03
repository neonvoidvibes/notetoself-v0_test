import SwiftUI // Using SwiftUI for Color and Image, otherwise Foundation is fine
import Combine // Needed for AppState publisher

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable, Equatable, Hashable { // Added Equatable & Hashable
    let id: UUID
    let text: String
    let isUser: Bool
    let date: Date
    var isStarred: Bool

    init(id: UUID = UUID(), text: String, isUser: Bool, date: Date = Date(), isStarred: Bool = false) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.date = date
        self.isStarred = isStarred
    }

    // Equatable conformance
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// MARK: - Chat Model
struct Chat: Identifiable, Codable, Equatable, Hashable { // Added Equatable & Hashable
    let id: UUID
    var messages: [ChatMessage]
    let createdAt: Date
    var lastUpdatedAt: Date
    var title: String
    var isStarred: Bool // Required by ChatManager

    init(id: UUID = UUID(), messages: [ChatMessage] = [], createdAt: Date = Date(), lastUpdatedAt: Date = Date(), title: String = "New Chat", isStarred: Bool = false) {
        self.id = id
        self.messages = messages
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.title = title
        self.isStarred = isStarred
    }

    // Generate a title based on the first user message
    mutating func generateTitle() {
        if let firstUserMessage = messages.first(where: { $0.isUser }) {
            let maxLength = min(firstUserMessage.text.count, 30)
            let truncatedText = String(firstUserMessage.text.prefix(maxLength)) // Ensure it's String
            title = truncatedText + (maxLength < firstUserMessage.text.count ? "..." : "")
        } else {
            title = "New Chat" // Keep default if no user message
        }
    }

    // Equatable conformance
    static func == (lhs: Chat, rhs: Chat) -> Bool {
         return lhs.id == rhs.id
     }

     // Hashable conformance
     func hash(into hasher: inout Hasher) {
         hasher.combine(id)
     }
}

// MARK: - Journal Entry Model
struct JournalEntry: Identifiable, Codable, Equatable, Hashable { // Added Equatable & Hashable
    let id: UUID
    let text: String
    let mood: Mood // Ensure Mood enum is also defined below
    let date: Date
    let intensity: Int
    var isStarred: Bool // Added starred property

    init(id: UUID = UUID(), text: String, mood: Mood, date: Date, intensity: Int = 2, isStarred: Bool = false) {
        self.id = id
        self.text = text
        self.mood = mood
        self.date = date
        // Ensure intensity is within a valid range if necessary, e.g., 1-3
        self.intensity = max(1, min(intensity, 3))
        self.isStarred = isStarred // Initialize starred property
    }

    // Existing isLocked logic - check if still relevant/used
    var isLocked: Bool {
        let hoursSinceCreation = Calendar.current.dateComponents([.hour], from: date, to: Date()).hour ?? 0
        return hoursSinceCreation >= 24
    }

    // Equatable conformance
    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool {
        return lhs.id == rhs.id
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Mood Enum
enum Mood: String, CaseIterable, Codable, Hashable { // Added Hashable
    // High arousal, positive valence (yellow to green)
    case alert, excited, happy
    // Low arousal, positive valence (green to blue)
    case content, relaxed, calm
    // Low arousal, negative valence (blue to red)
    case bored, depressed, sad
    // High arousal, negative valence (red to yellow)
    case anxious, angry, stressed
    // Center
    case neutral

    var name: String {
        switch self {
        case .alert: return "Alert"
        case .excited: return "Excited"
        case .happy: return "Happy"
        case .content: return "Content"
        case .relaxed: return "Relaxed"
        case .calm: return "Calm"
        case .bored: return "Bored"
        case .depressed: return "Depressed"
        case .sad: return "Sad"
        case .anxious: return "Anxious"
        case .angry: return "Angry"
        case .stressed: return "Stressed"
        case .neutral: return "Neutral"
        }
    }

    var systemIconName: String {
         switch self {
         case .alert: return "exclamationmark.circle"
         case .excited: return "star"
         case .happy: return "face.smiling" // Consider face.smiling.fill
         case .content: return "heart" // Consider heart.fill
         case .relaxed: return "leaf" // Consider leaf.fill
         case .calm: return "water.waves"
         case .bored: return "hourglass"
         case .depressed: return "cloud.rain" // Consider cloud.rain.fill
         case .sad: return "cloud.heavyrain" // Differentiate from depressed? Consider cloud.heavyrain.fill
         case .anxious: return "exclamationmark.triangle" // Consider exclamationmark.triangle.fill
         case .angry: return "flame" // Consider flame.fill
         case .stressed: return "bolt" // Consider bolt.fill
         case .neutral: return "face.dashed" // Consider face.dashed.fill
         }
     }

    var color: Color {
        // Reference Named Colors from Assets
        return Color("Mood\(self.name)") // e.g., Color("MoodHappy"), Color("MoodNeutral")
    }

    // Computed property for direct use in SwiftUI Views
    var icon: Image { Image(systemName: systemIconName) }

    // Add properties for the circumplex model if used by MoodWheel
    var valence: Int { /* ... implementation from original Models.swift if needed ... */ return 0 }
    var arousal: Int { /* ... implementation from original Models.swift if needed ... */ return 0 }
    static func fromCoordinates(valence: Int, arousal: Int) -> Mood { /* ... implementation ... */ return .neutral }
}


// MARK: - Subscription Status (Keep if AppState uses it)
enum SubscriptionTier: String, Codable, Hashable { // Added Hashable
    case free
    case premium

    var hasUnlimitedReflections: Bool { self == .premium }
    var hasAdvancedInsights: Bool { self == .premium }
}

// MARK: - AI Insight Models (Phase 5)

// Structure for Weekly Summary Insight
struct WeeklySummaryResult: Codable, Equatable {
    var mainSummary: String = ""
    var keyThemes: [String] = []
    var moodTrend: String = ""
    var notableQuote: String = ""

    // Example initializer for preview or default state
    static func empty() -> WeeklySummaryResult {
        WeeklySummaryResult(mainSummary: "No summary available yet.", keyThemes: [], moodTrend: "N/A", notableQuote: "")
    }
}

// Structure for Mood Trend Insight
struct MoodTrendResult: Codable, Equatable {
    var overallTrend: String = "Stable" // e.g., "Improving", "Declining", "Stable", "Fluctuating"
    var dominantMood: String = "Neutral" // Name of the most frequent mood
    var moodShifts: [String] = [] // e.g., "Shift from Happy to Stressed mid-week"
    var analysis: String = "" // A short textual analysis

    static func empty() -> MoodTrendResult {
        MoodTrendResult(overallTrend: "N/A", dominantMood: "N/A", moodShifts: [], analysis: "Not enough data for analysis.")
    }
}

// Structure for Recommendation Insight
struct RecommendationResult: Codable, Equatable {
    struct RecommendationItem: Codable, Equatable, Identifiable {
        let id: UUID // Keep Identifiable, ensure it's decodable/encodable correctly
        var title: String
        var description: String
        var category: String // e.g., "Mindfulness", "Activity", "Social"
        var rationale: String? // Why this recommendation is suggested (Changed to Optional)

        // Provide default init for Identifiable conformance if needed, or ensure JSON includes ID
         init(id: UUID = UUID(), title: String, description: String, category: String, rationale: String?) { // Updated init
             self.id = id
             self.title = title
             self.description = description
             self.category = category
             self.rationale = rationale // Assign optional value
         }
    }

    var recommendations: [RecommendationItem] = []

    static func empty() -> RecommendationResult {
        RecommendationResult(recommendations: [])
    }
}

// Structure for Streak Narrative Insight
struct StreakNarrativeResult: Codable, Equatable {
    var storySnippet: String = "Begin your story by journaling today." // For collapsed view
    var narrativeText: String = "Your journaling journey is unfolding." // For expanded view detail
    // Timeline markers (e.g., "Breakthrough", "Resilience") could be added here if AI generates them.
    // var timelineMarkers: [TimelineMarker]? = [] // Example future addition

    static func empty() -> StreakNarrativeResult {
        StreakNarrativeResult(storySnippet: "Journal consistently to build your narrative.", narrativeText: "Your detailed storyline will appear here with more data.")
    }
}

// Structure for AI Reflection Insight
struct AIReflectionResult: Codable, Equatable {
    var insightMessage: String = "How are you feeling today?" // Main insight for collapsed/expanded
    var reflectionPrompts: [String] = [ // Prompts for expanded view
        "What's been on your mind lately?",
        "What are you grateful for today?",
        "What challenge are you currently facing?"
    ]

    static func empty() -> AIReflectionResult {
        AIReflectionResult(insightMessage: "Unlock AI reflections by journaling.", reflectionPrompts: ["What would you like to reflect on?"])
    }
}


// Structure for Forecast Insight (Refined Structure)
struct ForecastResult: Codable, Equatable { // Conformance should now be automatic
    // Mood Prediction
    var moodPredictionText: String? = "Stable mood expected." // Textual summary (e.g., "Upbeat", "Potential dip mid-week")
    // Optional: Add structured data for charts if needed later
    // var moodPredictionChartData: [ForecastDataPoint]?

    // General Trends
    var emergingTopics: [String]? = [] // e.g., ["Wellness", "Work/Life Balance"]
    var consistencyForecast: String? = "Journaling consistency likely stable." // e.g., "Likely stable", "Potential decrease"

    // Preemptive Action Plan
    var actionPlanItems: [ActionPlanItem]? = [] // Renamed from preemptiveActionPlan for clarity

    // Nested struct for action plan items
    struct ActionPlanItem: Codable, Equatable, Identifiable { // Added Identifiable
        let id: UUID // Added for Identifiable
        var title: String // e.g., "Schedule Short Break"
        var description: String // e.g., "Plan a 10-min break tomorrow afternoon to maintain energy."
        var rationale: String? // Optional: Why this is suggested based on forecast

        // Init for Identifiable conformance
        init(id: UUID = UUID(), title: String, description: String, rationale: String? = nil) {
            self.id = id
            self.title = title
            self.description = description
            self.rationale = rationale
        }
    }

    // Nested struct for potential future chart data
    // struct ForecastDataPoint: Codable, Equatable { ... }

    // Corrected empty() function - ensure it's inside the struct
    static func empty() -> ForecastResult {
        // Directly initialize with nil values matching the optional properties
        ForecastResult(moodPredictionText: nil, emergingTopics: nil, consistencyForecast: nil, actionPlanItems: nil)
    }
}


// MARK: - Insight Card Helper Structs

// Defined here for global access
struct CalendarDay: Hashable {
    let day: Int
    let date: Date
}

// Defined here for global access - ENSURE THIS IS THE ONLY DEFINITION
struct MoodDataPoint: Identifiable, Codable, Equatable { // Added Codable, Equatable
    var id: UUID // Changed to var to allow decoding
    let date: Date
    let value: Double

    // Explicit init to handle default UUID generation if needed when decoding/creating
     init(id: UUID = UUID(), date: Date, value: Double) {
         self.id = id
         self.date = date
         self.value = value
     }
}


// MARK: - App State (Keep if used globally)
@MainActor // Ensure @Published vars are updated on main thread
class AppState: ObservableObject {
    @Published var journalEntries: [JournalEntry] = [] // Now uses the struct defined above
    @Published var journalExpandedEntryId: UUID? = nil // State for expanded journal entry ID
    @Published var subscriptionTier: SubscriptionTier = .free // Uses enum defined above
    @Published var hasSeenOnboarding: Bool = false // Keep for onboarding logic

    // Keep canUseReflections logic if needed elsewhere, but ChatManager enforces limit
    let freeReflectionsLimit = 3
    var dailyReflectionsUsed: Int { // Computed from ChatManager's persisted count
        // This assumes ChatManager's @AppStorage is the source of truth
        // We might need a more direct way if ChatManager isn't always loaded
        @AppStorage("chatDailyFreeMessageCount") var count: Int = 0
        return count
    }
    var canUseReflections: Bool {
        return subscriptionTier == .premium || dailyReflectionsUsed < freeReflectionsLimit
    }

    // Keep currentStreak logic
    var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())

        let hasTodayEntry = journalEntries.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
        // Streak requires *today's* entry to count
        guard hasTodayEntry else { return 0 }

        streak = 1
        checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)! // Start checking yesterday

        // Efficient check using a Set of entry dates
        let entryDatesSet = Set(journalEntries.map { calendar.startOfDay(for: $0.date) })

        while entryDatesSet.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }

    // REMOVED triggerAllInsightGenerations function - moved to InsightUtils.swift
}