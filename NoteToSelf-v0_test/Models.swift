import SwiftUI

// MARK: - Journal Entry Model

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let text: String
    let mood: Mood
    let date: Date
    let intensity: Int
    
    init(id: UUID = UUID(), text: String, mood: Mood, date: Date, intensity: Int = 2) {
        self.id = id
        self.text = text
        self.mood = mood
        self.date = date
        self.intensity = intensity
    }
    
    var isLocked: Bool {
        let hoursSinceCreation = Calendar.current.dateComponents([.hour], from: date, to: Date()).hour ?? 0
        return hoursSinceCreation >= 24
    }
}

// MARK: - Mood Enum

enum Mood: String, CaseIterable, Codable {
    // High arousal, positive valence (yellow to green)
    case alert, excited, happy
    // Low arousal, positive valence (green to blue)
    case content, relaxed, calm
    // Low arousal, negative valence (blue to red)
    case bored, depressed, sad
    // High arousal, negative valence (red to yellow)
    case anxious, angry, stressed // Updated: "stressed" to "anxious", "tense" to "stressed"
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
        case .anxious: return "Anxious" // Updated from "Stressed"
        case .angry: return "Angry"
        case .stressed: return "Stressed" // Updated from "Tense"
        case .neutral: return "Neutral"
        }
    }
    
    var systemIconName: String {
        switch self {
        case .alert: return "exclamationmark.circle"
        case .excited: return "star"
        case .happy: return "face.smiling"
        case .content: return "heart"
        case .relaxed: return "leaf"
        case .calm: return "water.waves"
        case .bored: return "hourglass"
        case .depressed: return "cloud.rain"
        case .sad: return "cloud.rain"
        case .anxious: return "exclamationmark.triangle" // Updated from "Stressed"
        case .angry: return "flame"
        case .stressed: return "bolt" // Updated from "Tense"
        case .neutral: return "face.dashed"
        }
    }
    
    var color: Color {
        switch self {
        // High arousal, positive valence (yellow to green)
        case .alert: return Color(hex: "#CCFF00")
        case .excited: return Color(hex: "#99FF33")
        case .happy: return Color(hex: "#66FF66")
        // Low arousal, positive valence (green to blue)
        case .content: return Color(hex: "#33FFCC")
        case .relaxed: return Color(hex: "#33CCFF")
        case .calm: return Color(hex: "#3399FF")
        // Low arousal, negative valence (blue to red)
        case .bored: return Color(hex: "#6666FF")
        case .depressed: return Color(hex: "#9933FF")
        case .sad: return Color(hex: "#CC33FF")
        // High arousal, negative valence (red to yellow)
        case .anxious: return Color(hex: "#FF3399") // Updated from "Stressed"
        case .angry: return Color(hex: "#FF3333")
        case .stressed: return Color(hex: "#FF9900") // Updated from "Tense"
        // Center
        case .neutral: return Color(hex: "#CCCCCC")
        }
    }
    
    var icon: some View {
        Image(systemName: systemIconName)
    }
    
    // Add properties for the circumplex model
    var valence: Int {
        switch self {
        case .happy, .excited, .alert: return 3
        case .content, .relaxed, .stressed: return 2
        case .calm, .angry: return 1
        case .neutral: return 0
        case .bored, .anxious: return -1 // Updated from "Stressed"
        case .depressed: return -2
        case .sad: return -3
        }
    }
    
    var arousal: Int {
        switch self {
        case .alert, .stressed, .angry: return 3 // Updated from "Tense"
        case .excited, .anxious: return 2 // Updated from "Stressed"
        case .happy, .sad: return 1
        case .neutral: return 0
        case .content, .depressed: return -1
        case .relaxed, .bored: return -2
        case .calm: return -3
        }
    }
    
    // Get mood from valence and arousal coordinates
    static func fromCoordinates(valence: Int, arousal: Int) -> Mood {
        switch (valence, arousal) {
        case (3, 1): return .happy
        case (3, 2): return .excited
        case (2, 3): return .alert
        case (1, 3): return .stressed // Updated from "Tense"
        case (-1, 3): return .angry
        case (-2, 2): return .anxious // Updated from "Stressed"
        case (-3, 1): return .sad
        case (-2, -1): return .depressed
        case (-1, -2): return .bored
        case (1, -3): return .calm
        case (2, -2): return .relaxed
        case (3, -1): return .content
        default: return .neutral
        }
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let date: Date
    
    init(id: UUID = UUID(), text: String, isUser: Bool, date: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.date = date
    }
}

// MARK: - Subscription Status

enum SubscriptionTier: String, Codable {
    case free
    case premium
    
    var hasUnlimitedReflections: Bool {
        return self == .premium
    }
    
    var hasAdvancedInsights: Bool {
        return self == .premium
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var journalEntries: [JournalEntry] = []
    @Published var chatMessages: [ChatMessage] = []
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var dailyReflectionsUsed: Int = 0
    @Published var hasSeenOnboarding: Bool = false
    
    // Daily free limit for reflections
    let freeReflectionsLimit = 3
    
    var canUseReflections: Bool {
        return subscriptionTier == .premium || dailyReflectionsUsed < freeReflectionsLimit
    }
    
    var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        
        // Check today first
        let hasTodayEntry = journalEntries.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
        if !hasTodayEntry {
            return 0
        }
        
        streak = 1
        
        while true {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            let hasEntryForDate = journalEntries.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if hasEntryForDate {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    // Sample data for preview and testing
    func loadSampleData() {
        let calendar = Calendar.current
        journalEntries = [
            JournalEntry(
                text: "Completed the new design for the journaling app today. Really proud of how the dark theme turned out.",
                mood: .happy,
                date: Date(),
                intensity: 3
            ),
            JournalEntry(
                text: "Worked on wireframes all day. Feeling a bit drained but making good progress.",
                mood: .neutral,
                date: calendar.date(byAdding: .day, value: -1, to: Date())!,
                intensity: 2
            ),
            JournalEntry(
                text: "Started the new project today. Excited about the possibilities but also feeling a bit overwhelmed by the scope.",
                mood: .anxious, // Updated from "Stressed"
                date: calendar.date(byAdding: .day, value: -2, to: Date())!,
                intensity: 1
            ),
            JournalEntry(
                text: "Taking a short break from work to recharge. Spent the day hiking and it was exactly what I needed.",
                mood: .happy,
                date: calendar.date(byAdding: .day, value: -7, to: Date())!,
                intensity: 2
            )
        ]
        
        chatMessages = [
            ChatMessage(text: "I've been feeling stressed about my upcoming presentation. Any advice?", isUser: true),
            ChatMessage(text: "It's natural to feel stressed about presentations. Try breaking your preparation into smaller tasks and practice in front of a mirror or a trusted friend. Remember that being prepared is the best way to reduce anxiety.", isUser: false),
            ChatMessage(text: "That's helpful. I'll try to practice more.", isUser: true),
            ChatMessage(text: "Great plan. Also, remember to take deep breaths before you start. Is there a specific part of the presentation that concerns you most?", isUser: false)
        ]
    }
}

