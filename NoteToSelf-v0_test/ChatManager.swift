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

    // UserDefaults key is no longer needed
    private let databaseService: DatabaseService // Add DatabaseService dependency

    // Update init to accept DatabaseService and load from DB
    init(databaseService: DatabaseService) {
        self.databaseService = databaseService // Store the service
        // Initialize with a new empty chat before loading
        self.currentChat = Chat()
        // Load chats from the database asynchronously
        loadChatsFromDB()
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
                // Remove await if the method isn't actually async
                try databaseService.saveChatMessage(message, chatId: currentChat.id, embedding: embedding)
                print("Successfully saved chat message \(message.id) to DB.")
            } catch {
                // Handle or log the error appropriately
                print("‼️ Error saving chat message \(message.id) to DB: \(error)")
                // Consider showing an alert to the user or implementing retry logic
            }
        }

        // 4. Update local state for the main list if the chat already exists
        if let index = chats.firstIndex(where: { $0.id == currentChat.id }) {
            chats[index] = currentChat
            // Re-sort if needed, although adding a message keeps it recent
            chats.sort { $0.lastUpdatedAt > $1.lastUpdatedAt }
        } else {
            // If it's a new chat (first message), add it to the list
            chats.insert(currentChat, at: 0) // Add to the beginning as it's the newest
        }
    }

    // Start a new chat
    func startNewChat() {
        // No need to explicitly save the old chat here anymore,
        // as messages were saved to DB individually.
        // Just ensure the UI reflects the new empty chat.

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

        // Call database service to delete chat messages
        Task {
            do {
                // Remove await if the method isn't actually async
                try databaseService.deleteChatFromDB(id: chat.id)
                print("Successfully deleted chat \(chat.id) from DB.")
            } catch {
                print("‼️ Error deleting chat \(chat.id) from DB: \(error)")
                // Consider adding error handling for the UI
            }
        }
    }

    // Load chats from Database asynchronously
    private func loadChatsFromDB() {
        Task { // Run in a background task
            do {
                // Remove await if the method isn't actually async
                let loadedChats = try databaseService.loadAllChats()
                // Switch back to main thread to update @Published properties
                // Add await since MainActor.run is async
                await MainActor.run {
                    self.chats = loadedChats
                    // Set currentChat to the most recent one if available, otherwise keep the new empty one
                    if let mostRecentChat = loadedChats.first {
                        self.currentChat = mostRecentChat
                    } else {
                        // Ensure currentChat is a fresh empty one if DB is empty
                        self.currentChat = Chat()
                    }
                    print("Successfully loaded \(loadedChats.count) chats into ChatManager from DB.")
                }
            } catch {
                print("‼️ ERROR loading chats into ChatManager from DB: \(error)")
                // Handle error appropriately, maybe show an alert or load empty state
                await MainActor.run {
                    self.chats = [] // Ensure chats is empty on error
                    self.currentChat = Chat() // Ensure currentChat is empty on error
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
        if let chatIndex = chats.firstIndex(where: { $0.id == currentChat.id }),
           let messageIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == message.id }) {
            
            chats[chatIndex].messages[messageIndex].isStarred.toggle()
            currentChat = chats[chatIndex] // Ensure currentChat reflects the change
            let newStarStatus = chats[chatIndex].messages[messageIndex].isStarred

            // Call database service to update star status
            Task {
                do {
                    // Remove await if the method isn't actually async
                    try databaseService.toggleMessageStarInDB(id: message.id, isStarred: newStarStatus)
                    print("Successfully toggled star for message \(message.id) in DB to \(newStarStatus).")
                } catch {
                    print("‼️ Error toggling star for message \(message.id) in DB: \(error)")
                    // Revert UI change on error? Or show alert?
                    // MainActor.run { chats[chatIndex].messages[messageIndex].isStarred.toggle() }
                }
            }
        } else if let messageIndex = currentChat.messages.firstIndex(where: { $0.id == message.id }) {
             // If the chat wasn't in the main list yet
             currentChat.messages[messageIndex].isStarred.toggle()
             let newStarStatus = currentChat.messages[messageIndex].isStarred
             // Call database service to update star status
             Task {
                 do {
                     // Remove await if the method isn't actually async
                     try databaseService.toggleMessageStarInDB(id: message.id, isStarred: newStarStatus)
                     print("Successfully toggled star for message \(message.id) (current chat only) in DB to \(newStarStatus).")
                 } catch {
                     print("‼️ Error toggling star for message \(message.id) (current chat only) in DB: \(error)")
                     // Revert UI change on error?
                     // MainActor.run { currentChat.messages[messageIndex].isStarred.toggle() }
                 }
             }
        }
    }

    // Delete a message
    // TODO: Update this later in Phase 5 to delete from DB as well
    func deleteMessage(_ message: ChatMessage) {
        if let chatIndex = chats.firstIndex(where: { $0.id == currentChat.id }),
           let messageIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == message.id }) {
            
            chats[chatIndex].messages.remove(at: messageIndex)
            currentChat = chats[chatIndex] // Ensure currentChat reflects the change

            // Call database service to delete message
            Task {
                do {
                    // Remove await if the method isn't actually async
                    try databaseService.deleteMessageFromDB(id: message.id)
                    print("Successfully deleted message \(message.id) from DB.")
                } catch {
                    print("‼️ Error deleting message \(message.id) from DB: \(error)")
                    // Consider adding error handling for the UI (e.g., re-inserting the message)
                }
            }
        } else if let messageIndex = currentChat.messages.firstIndex(where: { $0.id == message.id }) {
            // If the chat wasn't in the main list yet
            let messageToDeleteId = currentChat.messages[messageIndex].id
            currentChat.messages.remove(at: messageIndex)
            // Call database service to delete message
            Task {
                do {
                    // Remove await if the method isn't actually async
                    try databaseService.deleteMessageFromDB(id: messageToDeleteId)
                    print("Successfully deleted message \(messageToDeleteId) (current chat only) from DB.")
                } catch {
                    print("‼️ Error deleting message \(messageToDeleteId) (current chat only) from DB: \(error)")
                    // Consider adding error handling for the UI
                }
            }
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
            let newStarStatus = chats[index].isStarred

            // Call database service to update star status for all messages in the chat
            Task {
                do {
                    // Remove await if the method isn't actually async
                    try databaseService.toggleChatStarInDB(id: chat.id, isStarred: newStarStatus)
                    print("Successfully toggled star for chat \(chat.id) in DB to \(newStarStatus).")
                } catch {
                    print("‼️ Error toggling star for chat \(chat.id) in DB: \(error)")
                    // Revert UI change on error? Or show alert?
                    // MainActor.run {
                    //     if let revertIndex = chats.firstIndex(where: { $0.id == chat.id }) {
                    //         chats[revertIndex].isStarred.toggle()
                    //         if currentChat.id == chat.id { currentChat.isStarred.toggle() }
                    //     }
                    // }
                }
            }
        }
    }
}
