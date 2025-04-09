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

        loadChatsFromDBSync()
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

        resetDailyCountIfNeeded()

        #if !DEBUG
        let isSubscribed = subscriptionManager.isUserSubscribed
        let currentCount = self.dailyFreeMessageCount
        if !isSubscribed && currentCount >= maxFreeMessagesPerDay {
            print("‼️ [ChatPipeline] Daily free message limit reached (\(currentCount)/\(maxFreeMessagesPerDay)). Subscription required.")
            // TODO: Signal UI to show alert (Consider using a Combine publisher or delegate)
            return
        }
        #else
        print("⚠️ [ChatPipeline] DEBUG build: Bypassing daily free message limit check.")
        #endif

        print("[ChatPipeline] User message received: '\(originalUserMessageText.prefix(50))...'")

        let userMessage = ChatMessage(text: originalUserMessageText, isUser: true)
        addMessageToCurrentChat(userMessage)

        if !subscriptionManager.isUserSubscribed {
            #if DEBUG
            print("[ChatPipeline] DEBUG: Incrementing daily count (but limit is bypassed).")
            #endif
            self.dailyFreeMessageCount += 1
            self.updateLastUsageDate()
            print("[ChatPipeline] Daily free message count incremented: \(self.dailyFreeMessageCount)/\(maxFreeMessagesPerDay)")
        }

        self.isTyping = true
        print("[ChatPipeline] AI processing started.")

        // Capture necessary dependencies for the Task
        let dbService = self.databaseService
        let llmSvc = self.llmService

        Task {
            var ragContextString = ""
            var retrievalError: Error? = nil

            // --- RAG Context Retrieval ---
            print("[ChatPipeline] Attempting embedding generation for RAG...")
            let queryEmbedding = await generateEmbedding(for: originalUserMessageText)
            if let queryEmbedding = queryEmbedding {
                print("[ChatPipeline] Embedding generated. Retrieving RAG context...")
                do {
                    // Concurrent lookups
                    async let similarEntriesFetch = dbService.findSimilarJournalEntries(to: queryEmbedding, limit: 3)
                    async let similarMessagesFetch = dbService.findSimilarChatMessages(to: queryEmbedding, limit: 5)
                    async let latestSummaryFetch = try? dbService.loadLatestInsight(type: "weeklySummary") // Use try? for non-critical insights
                    async let latestMoodTrendFetch = try? dbService.loadLatestInsight(type: "moodTrend")
                    async let latestRecsFetch = try? dbService.loadLatestInsight(type: "recommendation")

                    // Await results
                    let entries = try await similarEntriesFetch // ContextItems from Journal
                    let messages = try await similarMessagesFetch // ContextItems from Chat
                    let summaryData = await latestSummaryFetch // Optional tuple
                    let moodTrendData = await latestMoodTrendFetch // Optional tuple
                    let recommendationsData = await latestRecsFetch // Optional tuple

                    print("[ChatPipeline] RAG retrieval success: \(entries.count) entries, \(messages.count) messages, \(summaryData != nil ? 1 : 0) summary, \(moodTrendData != nil ? 1 : 0) trend, \(recommendationsData != nil ? 1 : 0) recs.")

                    var allContextItems: [ContextItem] = []
                    allContextItems.append(contentsOf: entries) // Add similar entries
                    allContextItems.append(contentsOf: messages) // Add similar messages

                    // Add latest insights as ContextItems
                    if let insight = summaryData { allContextItems.append(insight.contextItem) }
                    if let insight = moodTrendData { allContextItems.append(insight.contextItem) }
                    if let insight = recommendationsData { allContextItems.append(insight.contextItem) }

                    // --- Weighting and Sorting ---
                    let weightedItems = allContextItems.map { item -> (item: ContextItem, weight: Double) in
                        let weight = calculateWeight(for: item)
                        return (item, weight)
                    }.sorted { $0.weight > $1.weight } // Sort descending by weight

                    print("[ChatPipeline] Calculated weights for \(weightedItems.count) context items.")
                    // Log top 3 weighted items for debugging
                    // weightedItems.prefix(3).forEach { print("  - Item ID: \($0.item.id), Type: \($0.item.sourceType.rawValue), Weight: \($0.weight)") }

                    // Select top N items (e.g., top 8)
                    let topItems = weightedItems.prefix(8).map { $0.item }

                    // --- Format Context String with Metadata ---
                    var contextStrings: [String] = ["Context items (most relevant first):"]
                    for item in topItems {
                        let filteredText = filterPII(text: item.text)
                        var metadataString = "(\(item.sourceType.rawValue), \(item.date.formatted(date: .numeric, time: .shortened))"
                        if let mood = item.mood {
                            metadataString += ", Mood: \(mood.name)"
                            if let intensity = item.moodIntensity { metadataString += "/\(intensity)"} // Add intensity if available
                        }
                        if item.isStarred { metadataString += ", STARRED" }
                        if let cardType = item.insightCardType { metadataString += ", Insight: \(cardType)" }
                        metadataString += ")"
                        contextStrings.append("- \(metadataString): \(filteredText)")
                    }

                    ragContextString = contextStrings.joined(separator: "\n")
                    print("[ChatPipeline] Weighted context formatting complete. Context length: \(ragContextString.count) chars.")

                } catch {
                    print("‼️ [ChatPipeline] RAG DB retrieval or processing failed: \(error)")
                    retrievalError = error
                    ragContextString = ""
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
            \(ragContextString.isEmpty ? "" : "\(ragContextString)\n\n---\n\n")User: \(filteredUserMessage)
            """
            print("[ChatPipeline] Sending prompt to LLM (Context included: \(ragContextString.isEmpty ? "No" : "Yes")).")

            // --- Call LLM & Handle Response ---
            var assistantMessage: ChatMessage?
            var llmError: Error?

            do {
                let assistantReplyText = try await llmSvc.generateChatResponse(
                    systemPrompt: SystemPrompts.chatAgentPrompt,
                    userMessage: finalPrompt
                )
                print("[ChatPipeline] LLM response received.")
                assistantMessage = ChatMessage(text: assistantReplyText, isUser: false)

            } catch {
                print("‼️ [ChatPipeline] LLM Service failed: \(error)")
                llmError = error
                // Provide a more user-friendly error message
                let displayError = (error as? LLMService.LLMError)?.localizedDescription ?? "Sorry, I encountered an error."
                assistantMessage = ChatMessage(text: displayError, isUser: false, isStarred: true) // Star error messages?
            }

            // --- Update UI (must switch back to MainActor) ---
            await MainActor.run {
                if let msg = assistantMessage {
                    addMessageToCurrentChat(msg)
                }
                self.isTyping = false
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
        self.currentChat.messages.append(message)
        self.currentChat.lastUpdatedAt = Date()

        if self.currentChat.title == "New Chat" && message.isUser && self.currentChat.messages.filter({ $0.isUser }).count == 1 {
            self.currentChat.generateTitle()
        }

        if let index = self.chats.firstIndex(where: { $0.id == self.currentChat.id }) {
            self.chats[index] = self.currentChat
        } else {
            self.chats.insert(self.currentChat, at: 0)
        }
        self.chats.sort { $0.lastUpdatedAt > $1.lastUpdatedAt }

        let chatId = self.currentChat.id
        let messageToSave = message // Capture the message itself

        Task.detached(priority: .background) { [databaseService] in
            print("[ChatDB] Generating embedding & saving message \(messageToSave.id) to DB...")
            let embedding = await generateEmbedding(for: messageToSave.text)
            do {
                try databaseService.saveChatMessage(messageToSave, chatId: chatId, embedding: embedding)
                print("✅ [ChatDB] Successfully saved message \(messageToSave.id) to DB.")
            } catch {
                print("‼️ [ChatDB] Error saving message \(messageToSave.id) to DB: \(error)")
            }
        }
    }


    // MARK: - Chat Lifecycle Management

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
            let newStarStatus = !self.chats[index].isStarred // Calculate the new status
            self.chats[index].isStarred = newStarStatus // Update chat star status locally
            print("[ChatManager] Toggling star for chat \(chat.id) to \(newStarStatus)")

            // Update all messages within this chat locally
            for msgIndex in 0..<self.chats[index].messages.count {
                self.chats[index].messages[msgIndex].isStarred = newStarStatus
            }

            // Update currentChat if it's the one being toggled
            if self.currentChat.id == chat.id {
                self.currentChat.isStarred = newStarStatus
                for msgIndex in 0..<self.currentChat.messages.count {
                    self.currentChat.messages[msgIndex].isStarred = newStarStatus
                }
            }

            // Get message IDs to update in DB
            let messageIdsToUpdate = self.chats[index].messages.map { $0.id }

            // Update all messages in the DB in the background
            Task.detached(priority: .background) { [databaseService] in
                var errors: [Error] = []
                for messageId in messageIdsToUpdate {
                    do {
                        try databaseService.toggleMessageStarInDB(id: messageId, isStarred: newStarStatus)
                    } catch {
                        print("‼️ [ChatManager] Error toggling star for message \(messageId) in DB: \(error)")
                        errors.append(error)
                    }
                }
                if errors.isEmpty {
                    print("✅ [ChatManager] Successfully toggled star for all messages in chat \(chat.id) in DB.")
                } else {
                    print("‼️ [ChatManager] Encountered \(errors.count) errors while toggling stars for messages in chat \(chat.id).")
                }
            }
        }
    }

    func toggleStarMessage(_ message: ChatMessage) {
        let messageId = message.id
        var newStarStatus: Bool? = nil
        var chatToUpdate: Chat? = nil

        // Find the message and its chat, update the message star status
        if let chatIdx = self.chats.firstIndex(where: { $0.messages.contains(where: { $0.id == messageId }) }) {
            if let msgIdx = self.chats[chatIdx].messages.firstIndex(where: { $0.id == messageId }) {
                self.chats[chatIdx].messages[msgIdx].isStarred.toggle()
                newStarStatus = self.chats[chatIdx].messages[msgIdx].isStarred
                chatToUpdate = self.chats[chatIdx] // Keep track of the chat that needs its star status potentially updated
                if self.currentChat.id == chatToUpdate?.id {
                    self.currentChat = self.chats[chatIdx] // Update currentChat if it's the one being modified
                }
            }
        } else if let msgIdx = self.currentChat.messages.firstIndex(where: { $0.id == messageId }) {
            self.currentChat.messages[msgIdx].isStarred.toggle()
            newStarStatus = self.currentChat.messages[msgIdx].isStarred
            chatToUpdate = self.currentChat
            // If currentChat is not in the main chats list yet (e.g., new chat), handle appropriately
             if let chatIdx = self.chats.firstIndex(where: { $0.id == self.currentChat.id }) {
                 self.chats[chatIdx] = self.currentChat
             } else {
                 // This case might need review depending on when chats are added to the list
                 print("Warning: Toggled star on message in currentChat not yet present in main chats list.")
             }
        }

        // Update the containing chat's overall star status if needed
        if let chat = chatToUpdate, let status = newStarStatus {
            let chatIsNowStarred = chat.messages.contains { $0.isStarred }
            if chat.isStarred != chatIsNowStarred {
                if let chatIdx = self.chats.firstIndex(where: { $0.id == chat.id }) {
                    self.chats[chatIdx].isStarred = chatIsNowStarred
                }
                if self.currentChat.id == chat.id {
                     self.currentChat.isStarred = chatIsNowStarred
                }
            }

            // Persist the individual message star change
            print("[ChatManager] Toggling star for message \(messageId) to \(status)")
            Task.detached(priority: .background) { [databaseService] in
                do {
                    try databaseService.toggleMessageStarInDB(id: messageId, isStarred: status)
                    print("✅ [ChatManager] Successfully toggled star for message \(messageId) in DB.")
                } catch {
                    print("‼️ [ChatManager] Error toggling star for message \(messageId) in DB: \(error)")
                    // Consider reverting UI?
                }
            }
        } else if newStarStatus == nil {
            print("⚠️ [ChatManager] Could not find message \(messageId) to star.")
        }
    }


    // MARK: - Data Loading & Grouping

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

    private func resetDailyCountIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = dateFromString(lastUsageDateString) ?? .distantPast

        if !Calendar.current.isDate(lastDate, inSameDayAs: today) {
            print("[ChatManager] New day detected. Resetting daily free message count.")
            dailyFreeMessageCount = 0
            updateLastUsageDate()
        }
    }

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

    // MARK: - Context Weighting

    /// Calculates a relevance weight for a given context item.
    /// Higher weight means more relevant.
    private func calculateWeight(for item: ContextItem) -> Double {
        var score: Double = 1.0 // Base score

        // --- Time Decay ---
        // Exponential decay: weight = base * decayRate ^ ageInDays
        // Example: decayRate = 0.95 -> 5% decay per day
        // Adjust decayRate to make newer items significantly more important
        let decayRate: Double = 0.90 // 10% decay per day, faster decay
        let ageFactor = pow(decayRate, Double(item.ageInDays))
        score *= ageFactor

        // --- Starred Boost ---
        if item.isStarred {
            score *= 2.5 // Increase boost for starred items
        }

        // --- Source Type Weighting ---
        switch item.sourceType {
        case .journalEntry: score *= 1.0 // Base weight for journal entries
        case .chatMessage: score *= 0.8 // Slightly less weight for chats? Adjust as needed.
        case .insight: score *= 1.2 // Slightly boost insights? Adjust as needed.
        }

        // --- Mood Intensity Weighting ---
        if let intensity = item.moodIntensity {
            // Example: Intensity 1 (Slight) = 0.9x, Intensity 2 (Moderate) = 1.0x, Intensity 3 (Strong) = 1.1x
            score *= (1.0 + (Double(intensity - 2) * 0.1))
        }

        // Ensure score is non-negative
        return max(0, score)
    }
}