import Foundation
import Libsql // Needed for potential error types if we get more specific

// MARK: - Chat Model
struct Chat: Identifiable, Codable {
    let id: UUID
    var messages: [ChatMessage]
    let createdAt: Date
    var lastUpdatedAt: Date
    var title: String
    var isStarred: Bool // Add this property

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
            // Take first 30 characters or less
            let maxLength = min(firstUserMessage.text.count, 30)
            let truncatedText = firstUserMessage.text.prefix(maxLength)
            title = truncatedText + (maxLength < firstUserMessage.text.count ? "..." : "")
        } else {
            title = "New Chat"
        }
    }
}

// MARK: - Chat Manager
class ChatManager: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var currentChat: Chat

    private let userDefaultsKey = "savedChats"
    private let databaseService: DatabaseService // Add DatabaseService dependency

    // Update init to accept DatabaseService
    init(databaseService: DatabaseService) {
        self.databaseService = databaseService // Store the service

        // Initialize with a new empty chat
        self.currentChat = Chat()

        // Load saved chats (from UserDefaults for now)
        loadChats()

        // Add a sample chat if there are no chats (easily removable for production)
        if chats.isEmpty {
            // Create a sample chat with the mock messages
            let sampleMessages = [
                ChatMessage(text: "I've been feeling stressed about my upcoming presentation. Any advice?", isUser: true),
                ChatMessage(text: "It's natural to feel stressed about presentations. Try breaking your preparation into smaller tasks and practice in front of a mirror or a trusted friend. Remember that being prepared is the best way to reduce anxiety.", isUser: false),
                ChatMessage(text: "That's helpful. I'll try to practice more.", isUser: true),
                ChatMessage(text: "Great plan. Also, remember to take deep breaths before you start. Is there a specific part of the presentation that concerns you most?", isUser: false)
            ]

            var sampleChat = Chat(
                messages: sampleMessages,
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                lastUpdatedAt: Date().addingTimeInterval(-1800) // 30 minutes ago
            )
            sampleChat.generateTitle()
            chats.append(sampleChat)
            // Note: Sample data won't be saved to DB here, only UserDefaults.
            // Migration step will handle existing data later.
            saveChats() // Save initial state (including sample) to UserDefaults
        }
        // Note: Initial data migration from UserDefaults to DB will be handled separately.
        // This init assumes DB might be empty or partially populated initially.
        // The loadChats() still reads from UserDefaults as per Plan Phase 3, Option A.
    }

    // Add a message to the current chat AND save to DB
    func addMessage(_ message: ChatMessage) {
        // 1. Update local state (current chat)
        currentChat.messages.append(message)
        currentChat.lastUpdatedAt = Date()

        // 2. Generate title if needed
        if currentChat.title == "New Chat" && message.isUser {
            currentChat.generateTitle()
        }

        // 3. Generate embedding (asynchronously) and save to DB
        Task {
            let embedding = generateEmbedding(for: message.text) // Use global helper
            do {
                try await databaseService.saveChatMessage(message, chatId: currentChat.id, embedding: embedding)
                print("Successfully saved chat message \(message.id) to DB.")
            } catch {
                // Handle or log the error appropriately
                print("‼️ Error saving chat message \(message.id) to DB: \(error)")
                // Consider showing an alert to the user or implementing retry logic
            }
        }

        // 4. Auto-save to UserDefaults (as per Plan Phase 3, Option A)
        saveChats()
    }

    // Start a new chat
    func startNewChat() {
        // Save current chat to UserDefaults if it has messages
        if !currentChat.messages.isEmpty {
            if !chats.contains(where: { $0.id == currentChat.id }) {
                chats.append(currentChat)
            }
            saveChats() // Save to UserDefaults
            // Note: DB saving happens message-by-message in addMessage
        }

        // Create a new chat
        currentChat = Chat()
    }

    // Load a specific chat (from the @Published chats array, sourced from UserDefaults currently)
    func loadChat(_ chat: Chat) {
        currentChat = chat
    }

    // Delete a chat (from UserDefaults only for now)
    // TODO: Update this later in Phase 5 to delete from DB as well
    func deleteChat(_ chat: Chat) {
        chats.removeAll { $0.id == chat.id }

        // If we deleted the current chat, start a new one
        if currentChat.id == chat.id {
            currentChat = Chat()
        }

        saveChats() // Save changes to UserDefaults
        // Need to add DB deletion logic later
    }

    // Save all chats to UserDefaults
    private func saveChats() {
        // Make sure current chat is in the list if it has messages
        if !currentChat.messages.isEmpty {
            // Update existing chat or add new one
            if let index = chats.firstIndex(where: { $0.id == currentChat.id }) {
                chats[index] = currentChat
            } else {
                // Only append if it's truly a new chat being saved
                // This check might be redundant if startNewChat handles adding correctly
                 if !chats.contains(where: { $0.id == currentChat.id }) {
                    chats.append(currentChat)
                 }
            }
        }

        // Sort chats by last updated date (newest first)
        chats.sort { $0.lastUpdatedAt > $1.lastUpdatedAt }

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(chats) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    // Load chats from UserDefaults
    private func loadChats() {
        if let savedChats = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedChats = try? JSONDecoder().decode([Chat].self, from: savedChats) {
                chats = decodedChats
                // If chats were loaded, set currentChat to the most recent one if available
                // Otherwise, keep the new empty chat created in init
                if let mostRecentChat = chats.first {
                    currentChat = mostRecentChat
                }
            }
        }
    }

    // Group chats by time period (similar to JournalDateGrouping)
    func groupChatsByTimePeriod() -> [(String, [Chat])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Calculate start of current week and last week
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!

        // Calculate start of current month
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!

        // Dictionary to store chats by section
        var chatsBySection: [String: [Chat]] = [:]

        for chat in chats {
            let chatDate = calendar.startOfDay(for: chat.lastUpdatedAt)
            let chatMonth = calendar.component(.month, from: chat.lastUpdatedAt)
            let chatYear = calendar.component(.year, from: chat.lastUpdatedAt)
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)

            if calendar.isDate(chatDate, inSameDayAs: today) {
                // Today
                let sectionKey = "Today"
                if chatsBySection[sectionKey] == nil { chatsBySection[sectionKey] = [] }
                chatsBySection[sectionKey]?.append(chat)
            } else if calendar.isDate(chatDate, inSameDayAs: yesterday) {
                // Yesterday
                let sectionKey = "Yesterday"
                if chatsBySection[sectionKey] == nil { chatsBySection[sectionKey] = [] }
                chatsBySection[sectionKey]?.append(chat)
            } else if chatDate >= currentWeekStart && chatDate < yesterday {
                // This Week (excluding today and yesterday)
                let sectionKey = "This Week"
                if chatsBySection[sectionKey] == nil { chatsBySection[sectionKey] = [] }
                chatsBySection[sectionKey]?.append(chat)
            } else if chatDate >= lastWeekStart && chatDate < currentWeekStart {
                // Last Week
                let sectionKey = "Last Week"
                if chatsBySection[sectionKey] == nil { chatsBySection[sectionKey] = [] }
                chatsBySection[sectionKey]?.append(chat)
            } else if chatDate >= currentMonthStart && chatDate < lastWeekStart {
                // This Month (excluding this week and last week)
                let sectionKey = "This Month"
                if chatsBySection[sectionKey] == nil { chatsBySection[sectionKey] = [] }
                chatsBySection[sectionKey]?.append(chat)
            } else if chatYear == currentYear && chatMonth != currentMonth {
                // Same year, different month
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMMM"
                let sectionKey = monthFormatter.string(from: chat.lastUpdatedAt)
                if chatsBySection[sectionKey] == nil { chatsBySection[sectionKey] = [] }
                chatsBySection[sectionKey]?.append(chat)
            } else {
                // Different year
                let yearMonthFormatter = DateFormatter()
                yearMonthFormatter.dateFormat = "yyyy\nMMMM"
                let sectionKey = yearMonthFormatter.string(from: chat.lastUpdatedAt)
                if chatsBySection[sectionKey] == nil { chatsBySection[sectionKey] = [] }
                chatsBySection[sectionKey]?.append(chat)
            }
        }

        // Sort chats within each section by date (newest first)
        for (key, value) in chatsBySection {
            chatsBySection[key] = value.sorted(by: { $0.lastUpdatedAt > $1.lastUpdatedAt })
        }

        // Sort sections by chronological order (newest first)
        let sortedSections = chatsBySection.sorted { (section1, section2) -> Bool in
            let order: [String] = ["Today", "Yesterday", "This Week", "Last Week", "This Month"]

            if let index1 = order.firstIndex(of: section1.key), let index2 = order.firstIndex(of: section2.key) {
                return index1 < index2
            } else if order.contains(section1.key) {
                return true
            } else if order.contains(section2.key) {
                return false
            } else {
                // For month and year-month sections, sort by the date of the most recent chat in the section
                let date1 = section1.value.first?.lastUpdatedAt ?? Date.distantPast
                let date2 = section2.value.first?.lastUpdatedAt ?? Date.distantPast
                // If dates are the same (unlikely but possible), fall back to key comparison
                if date1 == date2 { return section1.key > section2.key }
                return date1 > date2
            }
        }

        return sortedSections
    }

    // Toggle star status for a message
    // TODO: Update this later in Phase 5 to update DB as well
    func toggleStarMessage(_ message: ChatMessage) {
        if let index = currentChat.messages.firstIndex(where: { $0.id == message.id }) {
            currentChat.messages[index].isStarred.toggle()
            saveChats() // Save to UserDefaults
            // Need to add DB update logic later
        }
    }

    // Delete a message
    // TODO: Update this later in Phase 5 to delete from DB as well
    func deleteMessage(_ message: ChatMessage) {
        if let index = currentChat.messages.firstIndex(where: { $0.id == message.id }) {
            currentChat.messages.remove(at: index)
            saveChats() // Save to UserDefaults
            // Need to add DB deletion logic later
        }
    }

    // Add a method to toggle star status for an entire chat
    // TODO: Update this later in Phase 5 to update DB as well
    func toggleStarChat(_ chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index].isStarred.toggle()

            // If we're toggling the current chat, update it too
            if currentChat.id == chat.id {
                currentChat.isStarred.toggle()
            }

            saveChats() // Save to UserDefaults
            // Need to add DB update logic later
        }
    }
}
