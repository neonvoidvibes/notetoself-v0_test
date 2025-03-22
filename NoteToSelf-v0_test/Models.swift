import SwiftUI

// MARK: - Journal Entry Model

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let text: String
    let mood: Mood
    let date: Date
    
    init(id: UUID = UUID(), text: String, mood: Mood, date: Date) {
        self.id = id
        self.text = text
        self.mood = mood
        self.date = date
    }
    
    var isLocked: Bool {
        let hoursSinceCreation = Calendar.current.dateComponents([.hour], from: date, to: Date()).hour ?? 0
        return hoursSinceCreation >= 24
    }
}

// MARK: - Mood Enum

enum Mood: String, CaseIterable, Codable {
    case happy, neutral, sad, anxious, excited
    
    var name: String {
        switch self {
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .sad: return "Sad"
        case .anxious: return "Anxious"
        case .excited: return "Excited"
        }
    }
    
    var systemIconName: String {
        switch self {
        case .happy: return "face.smiling"
        case .neutral: return "face.dashed"
        case .sad: return "cloud.rain"
        case .anxious: return "exclamationmark.triangle"
        case .excited: return "star"
        }
    }
    
    var color: Color {
        let styles = UIStyles.shared
        
        switch self {
        case .happy: return styles.colors.moodHappy
        case .neutral: return styles.colors.moodNeutral
        case .sad: return styles.colors.moodSad
        case .anxious: return styles.colors.moodAnxious
        case .excited: return styles.colors.moodExcited
        }
    }
    
    var icon: some View {
        Image(systemName: systemIconName)
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
            return 0 // No entry today means streak is 0 or not yet updated for today
        }
        
        streak = 1 // Count today
        
        // Check previous days
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
        
        // Journal entries
        journalEntries = [
            JournalEntry(
                text: "Completed the new design for the journaling app today. Really proud of how the dark theme turned out.",
                mood: .happy,
                date: Date()
            ),
            JournalEntry(
                text: "Worked on wireframes all day. Feeling a bit drained but making good progress.",
                mood: .neutral,
                date: calendar.date(byAdding: .day, value: -1, to: Date())!
            ),
            JournalEntry(
                text: "Started the new project today. Excited about the possibilities but also feeling a bit overwhelmed by the scope.",
                mood: .anxious,
                date: calendar.date(byAdding: .day, value: -2, to: Date())!
            ),
            JournalEntry(
                text: "Taking a short break from work to recharge. Spent the day hiking and it was exactly what I needed.",
                mood: .happy,
                date: calendar.date(byAdding: .day, value: -7, to: Date())!
            )
        ]
        
        // Chat messages
        chatMessages = [
            ChatMessage(text: "I've been feeling stressed about my upcoming presentation. Any advice?", isUser: true),
            ChatMessage(text: "It's natural to feel stressed about presentations. Try breaking your preparation into smaller tasks and practice in front of a mirror or trusted friend. Remember that being prepared is the best way to reduce anxiety.", isUser: false),
            ChatMessage(text: "That's helpful. I'll try to practice more.", isUser: true),
            ChatMessage(text: "Great plan. Also, remember to take deep breaths before you start. Is there a specific part of the presentation that concerns you most?", isUser: false)
        ]
    }
}
