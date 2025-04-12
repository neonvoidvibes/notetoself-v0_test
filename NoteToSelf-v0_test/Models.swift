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

    // New adaptive color property for Journal Card context
    var journalColor: Color {
        return Color("Mood\(self.name)Journal") // e.g., Color("MoodHappyJournal")
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
    case pro // Renamed from premium

    var hasUnlimitedReflections: Bool { self == .pro }
    var hasAdvancedInsights: Bool { self == .pro }
}

// MARK: - AI Insight Models

// Existing - Weekly Summary Insight
struct WeeklySummaryResult: Codable, Equatable {
    var mainSummary: String = ""
    var keyThemes: [String] = []
    var moodTrend: String = ""
    var notableQuote: String = ""

    static func empty() -> WeeklySummaryResult {
        WeeklySummaryResult(mainSummary: "No summary available yet.", keyThemes: [], moodTrend: "N/A", notableQuote: "")
    }
}

// Existing - Mood Trend Insight (Original Version)
struct MoodTrendResult: Codable, Equatable {
    var overallTrend: String = "Stable" // e.g., "Improving", "Declining", "Stable", "Fluctuating"
    var dominantMood: String = "Neutral" // Name of the most frequent mood
    var moodShifts: [String] = [] // e.g., "Shift from Happy to Stressed mid-week"
    var analysis: String = "" // A short textual analysis

    static func empty() -> MoodTrendResult {
        MoodTrendResult(overallTrend: "N/A", dominantMood: "N/A", moodShifts: [], analysis: "Not enough data for analysis.")
    }
}

// Existing - Recommendation Insight
struct RecommendationResult: Codable, Equatable {
    struct RecommendationItem: Codable, Equatable, Identifiable {
        let id: UUID
        var title: String
        var description: String
        var category: String
        var rationale: String?

         init(id: UUID = UUID(), title: String, description: String, category: String, rationale: String?) {
             self.id = id
             self.title = title
             self.description = description
             self.category = category
             self.rationale = rationale
         }
    }

    var recommendations: [RecommendationItem] = []

    static func empty() -> RecommendationResult {
        RecommendationResult(recommendations: [])
    }
}

// Existing - Streak Narrative Insight
struct StreakNarrativeResult: Codable, Equatable {
    var storySnippet: String = "Begin your story by journaling today."
    var narrativeText: String = "Your journaling journey is unfolding."

    static func empty() -> StreakNarrativeResult {
        StreakNarrativeResult(storySnippet: "Journal consistently to build your narrative.", narrativeText: "Your detailed storyline will appear here with more data.")
    }
}

// Existing - AI Reflection Insight
struct AIReflectionResult: Codable, Equatable {
    var insightMessage: String = "How are you feeling today?"
    var reflectionPrompts: [String] = [
        "What's been on your mind lately?",
        "What are you grateful for today?",
        "What challenge are you currently facing?"
    ]

    static func empty() -> AIReflectionResult {
        AIReflectionResult(insightMessage: "Unlock AI reflections by journaling.", reflectionPrompts: ["What would you like to reflect on?"])
    }
}


// Existing - Forecast Insight
struct ForecastResult: Codable, Equatable {
    var moodPredictionText: String? = "Stable mood expected."
    var emergingTopics: [String]? = []
    var consistencyForecast: String? = "Journaling consistency likely stable."
    var actionPlanItems: [ActionPlanItem]? = []

    struct ActionPlanItem: Codable, Equatable, Identifiable {
        let id: UUID
        var title: String
        var description: String
        var rationale: String?

        init(id: UUID = UUID(), title: String, description: String, rationale: String? = nil) {
            self.id = id
            self.title = title
            self.description = description
            self.rationale = rationale
        }
    }

    static func empty() -> ForecastResult {
        ForecastResult(moodPredictionText: nil, emergingTopics: nil, consistencyForecast: nil, actionPlanItems: nil)
    }
}

// MARK: - Feel, Think, Act, Learn Insights (Grouped Cards)

// Feel Insight (Card #3)
struct MoodTrendPoint: Identifiable, Codable, Equatable {
    let id: UUID // Initialize locally, don't decode/encode
    let date: Date
    let moodValue: Double
    let label: String

    // Coding keys to exclude 'id' from JSON
    enum CodingKeys: String, CodingKey {
        case date, moodValue, label
    }

    // Initialize with a new UUID
    init(id: UUID = UUID(), date: Date, moodValue: Double, label: String) {
        self.id = id
        self.date = date
        self.moodValue = moodValue
        self.label = label
    }

     // Custom Decoder to handle date string from LLM
     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)

         // Decode other properties normally
         moodValue = try container.decode(Double.self, forKey: .moodValue)
         label = try container.decode(String.self, forKey: .label)

         // Decode date as String and parse
         let dateString = try container.decode(String.self, forKey: .date)
         let formatter = ISO8601DateFormatter()
         // Attempt multiple formats if necessary, start with the most likely one
         formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Common format with optional milliseconds
         if let decodedDate = formatter.date(from: dateString) {
              self.date = decodedDate
         } else {
              // Try without fractional seconds
              formatter.formatOptions = [.withInternetDateTime]
              if let decodedDate = formatter.date(from: dateString) {
                  self.date = decodedDate
              } else {
                   // Throw error if parsing fails after trying formats
                   throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Date string '\(dateString)' does not match expected ISO8601 format.")
              }
         }

         // Generate a new ID upon decoding
         id = UUID()
     }

     // Encoder can often use the default implementation if only decoding is custom
     // func encode(to encoder: Encoder) throws { ... } // Keep default unless specific encoding needed
}

struct FeelInsightResult: Codable, Equatable {
    var moodTrendChartData: [MoodTrendPoint]?
    var moodSnapshotText: String?
    var dominantMood: String?

    static func empty() -> FeelInsightResult { FeelInsightResult(moodTrendChartData: nil, moodSnapshotText: nil, dominantMood: nil) }
}

// Think Insight (Card #4)
struct ThinkInsightResult: Codable, Equatable {
    var themeOverviewText: String?
    var valueReflectionText: String?
    static func empty() -> ThinkInsightResult { ThinkInsightResult(themeOverviewText: nil, valueReflectionText: nil) }
}

// Act Insight (Card #5)
struct ActInsightResult: Codable, Equatable {
    var actionForecastText: String?
    var personalizedRecommendations: [RecommendationResult.RecommendationItem]? // Reuse Item struct
    static func empty() -> ActInsightResult { ActInsightResult(actionForecastText: nil, personalizedRecommendations: nil) }
}

// Learn Insight (Card #6)
struct LearnInsightResult: Codable, Equatable {
    var takeawayText: String?
    var beforeAfterText: String?
    var nextStepText: String?
    static func empty() -> LearnInsightResult { LearnInsightResult(takeawayText: nil, beforeAfterText: nil, nextStepText: nil) }
}

// --- NEW Daily & Weekly Insight Structures ---

// MARK: - Daily Reflection Insight (Card #1)
struct DailyReflectionResult: Codable, Equatable {
    var snapshotText: String? // Brief commentary summarizing signals from latest entry
    var reflectionPrompts: [String]? // 2 specific prompts based on the entry
    static func empty() -> DailyReflectionResult { DailyReflectionResult(snapshotText: nil, reflectionPrompts: nil) }
}

// MARK: - Week in Review Insight (Card #2)
struct WeekInReviewResult: Codable, Equatable {
    var startDate: Date? // Start of the reviewed week (Sunday)
    var endDate: Date? // End of the reviewed week (Saturday)
    var summaryText: String? // One-paragraph overview of the week
    var keyThemes: [String]? // Common ideas/topics for the week
    var moodTrendChartData: [MoodTrendPoint]? // 7-day chart data (same structure as Feel)
    var recurringThemesText: String? // Summary of Think themes/values for the week
    var actionHighlightsText: String? // Summary of Act highlights for the week
    var takeawayText: String? // Most meaningful Learn takeaway for the week

    static func empty() -> WeekInReviewResult {
        WeekInReviewResult(startDate: nil, endDate: nil, summaryText: nil, keyThemes: nil, moodTrendChartData: nil, recurringThemesText: nil, actionHighlightsText: nil, takeawayText: nil)
    }
}


// MARK: - Insight Card Helper Structs

struct CalendarDay: Hashable {
    let day: Int
    let date: Date
}

struct MoodDataPoint: Identifiable, Codable, Equatable {
    var id: UUID
    let date: Date
    let value: Double

     init(id: UUID = UUID(), date: Date, value: Double) {
         self.id = id
         self.date = date
         self.value = value
     }
}


// MARK: - App State
// MARK: - RAG Context Item
/// Represents a piece of context retrieved for the AI, including metadata for weighting and understanding.
struct ContextItem: Identifiable {
    let id: UUID
    let text: String
    let sourceType: ContextSourceType
    let date: Date
    let mood: Mood? // Optional for chat messages or insights without explicit mood
    let moodIntensity: Int? // Optional
    let isStarred: Bool
    let insightCardType: String? // Optional, only for insights
    let relatedChatId: UUID? // Optional, only for chat messages

    // Calculated property for age in days (used for weighting)
    var ageInDays: Int {
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }
}

// Enum to identify the source of the context item
enum ContextSourceType: String {
    case journalEntry = "Journal Entry"
    case chatMessage = "Chat Message"
    case insight = "AI Insight"
}


@MainActor
class AppState: ObservableObject {
    // The actual stored entries loaded from the database
    @Published var _journalEntries: [JournalEntry] = []
    @Published var journalExpandedEntryId: UUID? = nil
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var hasSeenOnboarding: Bool = false
    @Published var simulateEmptyState: Bool = false // Flag for developer toggle
    @Published var presentNewJournalEntrySheet: Bool = false // Flag to trigger new entry sheet
    // REMOVED: @Published var tabToSelectAfterSheetDismissal: Int? = nil
    @Published var isFadingOutForNewEntry: Bool = false // Flag to fade background

    // --- Streak Override (Developer Settings) ---
    @AppStorage("overrideStreakStartDate") var overrideStreakStartDate: Bool = false
    @AppStorage("simulatedStreakStartWeekday") var simulatedStreakStartWeekday: Int = Calendar.current.component(.weekday, from: Date()) // Default to today

    // Computed property for views to observe
    // Returns empty array if simulation is enabled, otherwise returns real entries
    var journalEntries: [JournalEntry] {
        get {
            return simulateEmptyState ? [] : _journalEntries
        }
        set {
            // Allow setting the underlying storage, but the getter handles simulation
            _journalEntries = newValue
        }
    }

    let freeReflectionsLimit = 3
    var dailyReflectionsUsed: Int {
        @AppStorage("chatDailyFreeMessageCount") var count: Int = 0
        return count
    }
    var canUseReflections: Bool {
        return subscriptionTier == .pro || dailyReflectionsUsed < freeReflectionsLimit // Updated to .pro
    }

    // Computed properties now access the potentially simulated journalEntries
    var currentStreak: Int {
        guard !journalEntries.isEmpty else { return 0 } // Use computed property
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        guard let mostRecentEntryDate = journalEntries.map({ $0.date }).max() else { return 0 }
        let startOfMostRecentEntryDay = calendar.startOfDay(for: mostRecentEntryDate)
        guard calendar.isDate(startOfMostRecentEntryDay, inSameDayAs: today) || calendar.isDate(startOfMostRecentEntryDay, inSameDayAs: yesterday) else { return 0 }
        var streak = 0
        var checkDate = startOfMostRecentEntryDay
        let entryDatesSet = Set(journalEntries.map { calendar.startOfDay(for: $0.date) })
        while entryDatesSet.contains(checkDate) {
            streak += 1
            guard streak < 1000 else { break }
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        return streak
    }

    var hasEntryToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return journalEntries.contains { calendar.isDate($0.date, inSameDayAs: today) } // Use computed property
    }
}