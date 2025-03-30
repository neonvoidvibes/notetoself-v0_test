import Foundation
import Libsql
import SwiftUI
import NaturalLanguage // For filterPII

// MARK: - Chat Manager
@MainActor // Mark the whole class as MainActor to simplify state management
class ChatManager: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var currentChat: Chat
    @Published var isTyping: Bool = false

    private let databaseService: DatabaseService
    private let llmService: LLMService
    private let subscriptionManager: SubscriptionManager

    @AppStorage("chatDailyFreeMessageCount") private var dailyFreeMessageCount: Int = 0
    @AppStorage("chatLastUsageDate") private var lastUsageDateString: String = ""

    private let maxFreeMessagesPerDay: Int = 3

    init(databaseService: DatabaseService, llmService: LLMService, subscriptionManager: SubscriptionManager) {
        self.databaseService = databaseService
        self.llmService = llmService
        self.subscriptionManager = subscriptionManager
        self.currentChat = Chat()

        // Load chats synchronously now that ChatManager is @MainActor
        // This assumes loadChatsFromDB can run reasonably fast or is acceptable on launch.
        // Alternatively, keep the Task approach but manage loading state.
        loadChatsFromDBSync() // Changed to sync version for simplicity with @MainActor

        // Call resetDailyCountIfNeeded safely now within the MainActor context
        resetDailyCountIfNeeded()
        print("[ChatManager] Initialized. Daily free messages used: \(dailyFreeMessageCount)")
    }

    // MARK: - Core Message Handling

    func sendUserMessageToAI(text: String) {
        let originalUserMessageText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !originalUserMessageText.isEmpty else {
            print("[ChatPipeline] Attempted to send empty message.")
            return
        }

        // Checks now run directly as we are on MainActor
        resetDailyCountIfNeeded() // Ensure count is up-to-date

        let isSubscribed = subscriptionManager.isUserSubscribed
        let currentCount = self.dailyFreeMessageCount

        if !isSubscribed && currentCount >= maxFreeMessagesPerDay {
            print("‼️ [ChatPipeline] Daily free message limit reached (\(currentCount)/\(maxFreeMessagesPerDay)). Subscription required.")
            // TODO: Signal UI to show alert
            return
        }

        print("[ChatPipeline] User message received: '\(originalUserMessageText.prefix(50))...'")

        // 1. Create and save user message (UI update + async DB save)
        let userMessage = ChatMessage(text: originalUserMessageText, isUser: true)
        addMessageToCurrentChat(userMessage) // Handles UI update and background DB save

        // Increment usage count for free users
        if !isSubscribed {
            self.dailyFreeMessageCount += 1
            self.updateLastUsageDate()
            print("[ChatPipeline] Daily free message count incremented: \(self.dailyFreeMessageCount)/\(maxFreeMessagesPerDay)")
        }

        self.isTyping = true // Start typing indicator
        print("[ChatPipeline] AI processing started.")

        // --- Start Background Task for AI processing ---
        Task {
            var contextString = ""
            var retrievalError: Error? = nil

            // --- RAG Context Retrieval & PII Filtering ---
            print("[ChatPipeline] Attempting embedding generation for RAG...")
            let queryEmbedding = await generateEmbedding(for: originalUserMessageText) // Use await
            if let queryEmbedding = queryEmbedding { // Check the awaited result
                print("[ChatPipeline] Embedding generated successfully.")
                print("[ChatPipeline] Attempting RAG context retrieval...")
                do {
                    async let similarEntriesFetch = databaseService.findSimilarJournalEntries(to: queryEmbedding, limit: 3)
                    async let similarMessagesFetch = databaseService.findSimilarChatMessages(to: queryEmbedding, limit: 5)

                    let entries = try await similarEntriesFetch
                    let messages = try await similarMessagesFetch
                    print("[ChatPipeline] RAG retrieval success: \(entries.count) entries, \(messages.count) messages.")

                    print("[ChatPipeline] Starting PII filtering for context...")
                    var formattedContextItems: [String] = []

                    if !entries.isEmpty {
                        formattedContextItems.append("Context from past journal entries:")
                        for entry in entries {
                            let filteredText = filterPII(text: entry.text)
                            // Corrected Date Format: Use .numeric for date
                            formattedContextItems.append("- Entry (\(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.rawValue)): \(filteredText.prefix(100))...")
                        }
                    }

                    if !messages.isEmpty {
                        formattedContextItems.append("\nContext from past chat messages:")
                        for msgTuple in messages.sorted(by: { $0.message.date < $1.message.date }) {
                             let prefix = msgTuple.message.isUser ? "You" : "AI"
                             let filteredText = filterPII(text: msgTuple.message.text)
                             formattedContextItems.append("- \(prefix) (\(msgTuple.message.date.formatted(date: .omitted, time: .shortened))): \(filteredText.prefix(80))...")
                        }
                    }
                    contextString = formattedContextItems.joined(separator: "\n")
                    print("[ChatPipeline] PII filtering complete. Context length: \(contextString.count) chars.")

                } catch {
                    print("‼️ [ChatPipeline] RAG retrieval failed: \(error)")
                    retrievalError = error
                    contextString = ""
                }
            } else {
                print("‼️ [ChatPipeline] Embedding generation failed.")
            }
            // --- End RAG ---

            // --- Filter User Message & Construct Final Prompt ---
            print("[ChatPipeline] Filtering PII from user message...")
            let filteredUserMessage = filterPII(text: originalUserMessageText)
            print("[ChatPipeline] PII filtering for user message complete.")

            let finalPrompt = """
            \(contextString.isEmpty ? "" : "\(contextString)\n\n---\n\n")User: \(filteredUserMessage)
            """
            print("[ChatPipeline] Sending prompt to LLM (Context included: \(contextString.isEmpty ? "No" : "Yes")).")

            // --- Call LLM & Handle Response ---
            var assistantMessage: ChatMessage?
            var llmError: Error?

            do {
                // No need to capture self explicitly here as Task inherits actor context
                let assistantReplyText = try await llmService.generateChatResponse(
                    systemPrompt: SystemPrompts.chatAgentPrompt,
                    userMessage: finalPrompt
                )
                print("[ChatPipeline] LLM response received.")
                assistantMessage = ChatMessage(text: assistantReplyText, isUser: false)

            } catch {
                print("‼️ [ChatPipeline] LLM Service failed: \(error)")
                llmError = error
                assistantMessage = ChatMessage(text: "Sorry, I encountered an error processing your request.", isUser: false, isStarred: true)
            }

            // --- Update UI (must switch back to MainActor) ---
            await MainActor.run {
                if let msg = assistantMessage {
                    addMessageToCurrentChat(msg) // This is @MainActor, safe to call
                }
                self.isTyping = false // Stop typing indicator
                print("[ChatPipeline] AI processing finished.")
                if let err = llmError {
                     print("‼️ [ChatPipeline] Final Error State: \(err.localizedDescription)")
                }
                 if let ragErr = retrievalError {
                     print("⚠️ [ChatPipeline] Note: RAG retrieval failed earlier: \(ragErr.localizedDescription)")
                 }
            }
        } // End Task
    }

    /// Internal helper to add a message to the current chat state and save it to the database.
    /// Already marked @MainActor, so UI updates are safe. DB save dispatched.
    private func addMessageToCurrentChat(_ message: ChatMessage) {
        // 1. Update local state (current chat)
        self.currentChat.messages.append(message)
        self.currentChat.lastUpdatedAt = Date()

        // 2. Generate title
        if self.currentChat.title == "New Chat" && message.isUser && self.currentChat.messages.filter({ $0.isUser }).count == 1 {
            self.currentChat.generateTitle()
        }

        // 3. Update the chat in the main list
        if let index = self.chats.firstIndex(where: { $0.id == self.currentChat.id }) {
            self.chats[index] = self.currentChat
        } else {
            self.chats.insert(self.currentChat, at: 0)
        }
        self.chats.sort { $0.lastUpdatedAt > $1.lastUpdatedAt }

        // 4. Save to Database (Dispatch to background task)
        let chatId = self.currentChat.id
        Task.detached(priority: .background) { [databaseService] in // Capture service
            print("[ChatDB] Generating embedding & saving message \(message.id) to DB...")
            let embedding = await generateEmbedding(for: message.text) // Use await
            do {
                // Use captured self explicitly
                try databaseService.saveChatMessage(message, chatId: chatId, embedding: embedding)
                print("✅ [ChatDB] Successfully saved message \(message.id) to DB.")
            } catch {
                print("‼️ [ChatDB] Error saving message \(message.id) to DB: \(error)")
            }
        }
    }


    // MARK: - Chat Lifecycle Management

    // These are fine on MainActor as they directly modify @Published properties
    func startNewChat() {
        print("[ChatManager] Starting new chat.")
        self.currentChat = Chat()
    }

    func loadChat(_ chat: Chat) {
        print("[ChatManager] Loading chat ID: \(chat.id)")
        self.currentChat = chat
    }

    func deleteChat(_ chat: Chat) {
         print("[ChatManager] Deleting chat ID: \(chat.id)")
         let chatIdToDelete = chat.id
         self.chats.removeAll { $0.id == chatIdToDelete }

         if self.currentChat.id == chatIdToDelete {
             self.currentChat = Chat()
         }

         // Use explicit self capture
         Task.detached(priority: .background) { [databaseService] in
             do {
                 try databaseService.deleteChatFromDB(id: chatIdToDelete)
                 print("✅ [ChatManager] Successfully deleted chat \(chatIdToDelete) from DB.")
             } catch {
                 print("‼️ [ChatManager] Error deleting chat \(chatIdToDelete) from DB: \(error)")
             }
         }
    }

    func deleteMessage(_ message: ChatMessage) {
         print("[ChatManager] Deleting message ID: \(message.id)")
         let messageIdToDelete = message.id
         var chatToUpdateId: UUID? = nil

         if let chatIndex = self.chats.firstIndex(where: { $0.messages.contains(where: { $0.id == messageIdToDelete }) }) {
              self.chats[chatIndex].messages.removeAll { $0.id == messageIdToDelete }
              chatToUpdateId = self.chats[chatIndex].id
              if self.currentChat.id == chatToUpdateId {
                  self.currentChat = self.chats[chatIndex]
              }
         } else if self.currentChat.messages.contains(where: { $0.id == messageIdToDelete }) {
             self.currentChat.messages.removeAll { $0.id == messageIdToDelete }
             chatToUpdateId = self.currentChat.id
         } else {
              print("⚠️ [ChatManager] Could not find message \(messageIdToDelete) to delete in local state.")
              return
         }

         // Use explicit self capture
         Task.detached(priority: .background) { [databaseService] in
              do {
                  try databaseService.deleteMessageFromDB(id: messageIdToDelete)
                  print("✅ [ChatManager] Successfully deleted message \(messageIdToDelete) from DB.")
              } catch {
                  print("‼️ [ChatManager] Error deleting message \(messageIdToDelete) from DB: \(error)")
              }
         }
    }

    // MARK: - Star Management

    func toggleStarChat(_ chat: Chat) {
        if let index = self.chats.firstIndex(where: { $0.id == chat.id }) {
            self.chats[index].isStarred.toggle()
            let newStarStatus = self.chats[index].isStarred
            print("[ChatManager] Toggling star for chat \(chat.id) to \(newStarStatus)")

            if self.currentChat.id == chat.id { self.currentChat.isStarred = newStarStatus }

            let chatId = chat.id
            // Use explicit self capture
            Task.detached(priority: .background) { [databaseService] in
                do {
                    try databaseService.toggleChatStarInDB(id: chatId, isStarred: newStarStatus)
                    print("✅ [ChatManager] Successfully toggled star for chat \(chatId) in DB.")
                } catch {
                    print("‼️ [ChatManager] Error toggling star for chat \(chatId) in DB: \(error)")
                }
            }
        }
    }

    func toggleStarMessage(_ message: ChatMessage) {
        let messageId = message.id
        var newStarStatus: Bool? = nil

        // Find and update message in local state
        if let msgIdx = self.currentChat.messages.firstIndex(where: { $0.id == messageId }) {
             self.currentChat.messages[msgIdx].isStarred.toggle()
             newStarStatus = self.currentChat.messages[msgIdx].isStarred
             if let chatIdx = self.chats.firstIndex(where: { $0.id == self.currentChat.id }) {
                 self.chats[chatIdx] = self.currentChat
             }
        } else {
             for i in 0..<self.chats.count {
                 if let msgIdx = self.chats[i].messages.firstIndex(where: { $0.id == messageId }) {
                     self.chats[i].messages[msgIdx].isStarred.toggle()
                     newStarStatus = self.chats[i].messages[msgIdx].isStarred
                     break
                 }
             }
        }

        // If found and toggled, update DB
        if let status = newStarStatus {
            print("[ChatManager] Toggling star for message \(messageId) to \(status)")
            // Use explicit self capture
            Task.detached(priority: .background) { [databaseService] in
                do {
                    try databaseService.toggleMessageStarInDB(id: messageId, isStarred: status)
                    print("✅ [ChatManager] Successfully toggled star for message \(messageId) in DB.")
                } catch {
                    print("‼️ [ChatManager] Error toggling star for message \(messageId) in DB: \(error)")
                }
            }
        } else {
             print("⚠️ [ChatManager] Could not find message \(messageId) to star.")
        }
    }


    // MARK: - Data Loading & Grouping

    // Synchronous version for use within @MainActor init
    private func loadChatsFromDBSync() {
        print("[ChatManager] Loading chats synchronously...")
        do {
            let loadedChats = try databaseService.loadAllChats()
            self.chats = loadedChats
            if let mostRecentChat = loadedChats.first {
                self.currentChat = mostRecentChat
            } else {
                self.currentChat = Chat()
            }
            print("✅ [ChatManager] Synchronously loaded \(loadedChats.count) chats from DB.")
        } catch {
            print("‼️ [ChatManager] ERROR loading chats synchronously from DB: \(error)")
            self.chats = []
            self.currentChat = Chat()
        }
    }

    // Group chats by time period (Simplified variable usage)
    func groupChatsByTimePeriod() -> [(String, [Chat])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        var chatsBySection: [String: [Chat]] = [:]

        for chat in chats {
            let chatDate = calendar.startOfDay(for: chat.lastUpdatedAt)
            // Removed unused chatMonth, currentMonth
            let chatYear = calendar.component(.year, from: chat.lastUpdatedAt)
            let currentYear = calendar.component(.year, from: today)

            let sectionKey: String
            if calendar.isDate(chatDate, inSameDayAs: today) { sectionKey = "Today" }
            else if calendar.isDate(chatDate, inSameDayAs: yesterday) { sectionKey = "Yesterday" }
            else if chatDate >= currentWeekStart { sectionKey = "This Week" }
            else if chatDate >= lastWeekStart { sectionKey = "Last Week" }
            else if chatDate >= currentMonthStart { sectionKey = "This Month" }
            else if chatYear == currentYear {
                let monthFormatter = DateFormatter(); monthFormatter.dateFormat = "MMMM"; sectionKey = monthFormatter.string(from: chat.lastUpdatedAt)
            } else {
                let yearMonthFormatter = DateFormatter(); yearMonthFormatter.dateFormat = "yyyy MMMM"; sectionKey = yearMonthFormatter.string(from: chat.lastUpdatedAt)
            }
            chatsBySection[sectionKey, default: []].append(chat)
        }

        for (key, value) in chatsBySection { chatsBySection[key] = value.sorted { $0.lastUpdatedAt > $1.lastUpdatedAt } }

        let sortedSections = chatsBySection.sorted { (section1, section2) -> Bool in
            let order: [String] = ["Today", "Yesterday", "This Week", "Last Week", "This Month"]
            if let index1 = order.firstIndex(of: section1.key), let index2 = order.firstIndex(of: section2.key) { return index1 < index2 }
            if order.contains(section1.key) { return true }
            if order.contains(section2.key) { return false }
            let date1 = section1.value.first?.lastUpdatedAt ?? .distantPast
            let date2 = section2.value.first?.lastUpdatedAt ?? .distantPast
            if date1 == date2 { return section1.key > section2.key }
            return date1 > date2
        }
        return sortedSections
    }

    // MARK: - Daily Usage Reset Logic

    // Marked @MainActor (as class is now) - safe to access @AppStorage
    private func resetDailyCountIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = dateFromString(lastUsageDateString) ?? .distantPast

        if !Calendar.current.isDate(lastDate, inSameDayAs: today) {
            print("[ChatManager] New day detected. Resetting daily free message count.")
            dailyFreeMessageCount = 0
            updateLastUsageDate()
        }
    }

    // Marked @MainActor (as class is now) - safe to access @AppStorage
    private func updateLastUsageDate() {
        lastUsageDateString = stringFromDate(Date())
    }

    // Helper Date Formatting
    private func stringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}