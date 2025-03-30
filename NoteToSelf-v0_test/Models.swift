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

    init(id: UUID = UUID(), text: String, mood: Mood, date: Date, intensity: Int = 2) {
        self.id = id
        self.text = text
        self.mood = mood
        self.date = date
        // Ensure intensity is within a valid range if necessary, e.g., 1-3
        self.intensity = max(1, min(intensity, 3))
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
         // Using hex initializer assumes it exists (it's in UIStyles.swift, but keep here for model independence if needed)
         // Or define colors directly here. Let's use direct definition for robustness.
         switch self {
         case .alert: return Color(red: 0.8, green: 1.0, blue: 0.0) // #CCFF00 Limish Yellow
         case .excited: return Color(red: 0.6, green: 1.0, blue: 0.2) // #99FF33 Bright Green
         case .happy: return Color(red: 0.4, green: 1.0, blue: 0.4) // #66FF66 Green
         case .content: return Color(red: 0.2, green: 1.0, blue: 0.8) // #33FFCC Turquoise
         case .relaxed: return Color(red: 0.2, green: 0.8, blue: 1.0) // #33CCFF Light Blue
         case .calm: return Color(red: 0.2, green: 0.6, blue: 1.0) // #3399FF Blue
         case .bored: return Color(red: 0.4, green: 0.4, blue: 1.0) // #6666FF Indigo
         case .depressed: return Color(red: 0.6, green: 0.2, blue: 1.0) // #9933FF Purple
         case .sad: return Color(red: 0.8, green: 0.2, blue: 1.0) // #CC33FF Magenta
         case .anxious: return Color(red: 1.0, green: 0.2, blue: 0.6) // #FF3399 Pink
         case .angry: return Color(red: 1.0, green: 0.2, blue: 0.2) // #FF3333 Red
         case .stressed: return Color(red: 1.0, green: 0.6, blue: 0.0) // #FF9900 Orange
         case .neutral: return Color(red: 0.8, green: 0.8, blue: 0.8) // #CCCCCC Light Gray
         }
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
        let id = UUID() // Add identifiable conformance for UI lists
        var title: String
        var description: String
        var category: String // e.g., "Mindfulness", "Activity", "Social"
        var rationale: String // Why this recommendation is suggested
    }

    var recommendations: [RecommendationItem] = []

    static func empty() -> RecommendationResult {
        RecommendationResult(recommendations: [])
    }
}


// MARK: - App State (Keep if used globally)
// Note: AppState itself doesn't need Codable unless you save/load it directly
class AppState: ObservableObject {
    @Published var journalEntries: [JournalEntry] = [] // Now uses the struct defined above
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

    // --- Insight Generation Trigger ---
    // Call this after saving a journal entry
    func triggerAllInsightGenerations(llmService: LLMService, databaseService: DatabaseService) async {
        print("[AppState] Triggering background insight generation...")

        // Check subscription status - only generate if premium
        guard subscriptionTier == .premium else {
            print("[AppState] Skipping insight generation (Free tier).")
            return
        }

        // Create generators (consider dependency injection if AppState gets complex)
        let summaryGenerator = WeeklySummaryGenerator(llmService: llmService, databaseService: databaseService)
        let moodTrendGenerator = MoodTrendGenerator(llmService: llmService, databaseService: databaseService)
        let recommendationGenerator = RecommendationGenerator(llmService: llmService, databaseService: databaseService)

        // Run generators concurrently
        async let summaryTask: Void = summaryGenerator.generateAndStoreIfNeeded()
        async let moodTrendTask: Void = moodTrendGenerator.generateAndStoreIfNeeded()
        async let recommendationTask: Void = recommendationGenerator.generateAndStoreIfNeeded()

        // Await completion (errors are handled within each generator)
        _ = await [summaryTask, moodTrendTask, recommendationTask]

        print("[AppState] Background insight generation finished.")
        // Optionally: Post a notification for UI refresh if needed, although InsightsView reloads on appear.
        // await MainActor.run { NotificationCenter.default.post(name: .insightsUpdated, object: nil) }
    }
}

// Notification name for UI updates (optional)
// extension Notification.Name {
//     static let insightsUpdated = Notification.Name("insightsUpdated")
// }

// Helper Color Extension (if not already defined elsewhere, e.g., UIStyles)
// If UIStyles already defines this, remove it from here.
/*
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
*/