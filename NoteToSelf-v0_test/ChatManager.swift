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
                    async let latestSummaryFetch = dbService.loadLatestInsight(type: "weeklySummary")
                    async let latestMoodTrendFetch = dbService.loadLatestInsight(type: "moodTrend")
                    async let latestRecsFetch = dbService.loadLatestInsight(type: "recommendation")


                    // Await results
                    let entries = try await similarEntriesFetch
                    let messages = try await similarMessagesFetch
                    let summaryData = try? await latestSummaryFetch // Use try? to ignore errors here
                    let moodTrendData = try? await latestMoodTrendFetch
                    let recommendationsData = try? await latestRecsFetch

                    print("[ChatPipeline] RAG retrieval success: \(entries.count) entries, \(messages.count) messages, \(summaryData != nil ? 1 : 0) summary, \(moodTrendData != nil ? 1 : 0) trend, \(recommendationsData != nil ? 1 : 0) recs.")

                    var formattedContextItems: [String] = []

                    // Format Journal Entries
                    if !entries.isEmpty {
                        formattedContextItems.append("Context from recent/relevant journal entries:")
                        for entry in entries {
                            let filteredText = filterPII(text: entry.text)
                            formattedContextItems.append("- Entry (\(entry.date.formatted(date: .numeric, time: .omitted)), Mood: \(entry.mood.name)): \(filteredText.prefix(100))...")
                        }
                    }

                    // Format Chat Messages
                    if !messages.isEmpty {
                        formattedContextItems.append("\nContext from recent/relevant chat messages:")
                        for msgTuple in messages.sorted(by: { $0.message.date < $1.message.date }) {
                             let prefix = msgTuple.message.isUser ? "You" : "AI"
                             let filteredText = filterPII(text: msgTuple.message.text)
                             formattedContextItems.append("- \(prefix) (\(msgTuple.message.date.formatted(date: .omitted, time: .shortened))): \(filteredText.prefix(80))...")
                        }
                    }

                    // Format AI Insights
                    var insightContext: [String] = []
                    let decoder = JSONDecoder()

                    if let (summaryJson, _) = summaryData, let data = summaryJson.data(using: .utf8), let summary = try? decoder.decode(WeeklySummaryResult.self, from: data) {
                        insightContext.append("Last Weekly Summary: \(summary.mainSummary.prefix(100))... Themes: \(summary.keyThemes.joined(separator: ", ")). Trend: \(summary.moodTrend).")
                    }
                     if let (trendJson, _) = moodTrendData, let data = trendJson.data(using: .utf8), let trend = try? decoder.decode(MoodTrendResult.self, from: data) {
                         insightContext.append("Recent Mood Trend: \(trend.overallTrend). Dominant: \(trend.dominantMood). Analysis: \(trend.analysis.prefix(100))...")
                     }
                    if let (recsJson, _) = recommendationsData, let data = recsJson.data(using: .utf8), let recs = try? decoder.decode(RecommendationResult.self, from: data), !recs.recommendations.isEmpty {
                        let recTitles = recs.recommendations.map { $0.title }.joined(separator: ", ")
                        insightContext.append("Recent Recommendations: \(recTitles).")
                    }

                    if !insightContext.isEmpty {
                        formattedContextItems.append("\nContext from recent AI-generated insights:")
                        formattedContextItems.append(contentsOf: insightContext.map { "- \($0)" })
                    }


                    ragContextString = formattedContextItems.joined(separator: "\n")
                    print("[ChatPipeline] PII filtering & context formatting complete. Context length: \(ragContextString.count) chars.")

                } catch {
                    print("‼️ [ChatPipeline] RAG DB retrieval failed: \(error)")
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
            self.chats[index].isStarred.toggle()
            let newStarStatus = self.chats[index].isStarred
            print("[ChatManager] Toggling star for chat \(chat.id) to \(newStarStatus)")

            if self.currentChat.id == chat.id { self.currentChat.isStarred = newStarStatus }

            let chatId = chat.id
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

        if let status = newStarStatus {
            print("[ChatManager] Toggling star for message \(messageId) to \(status)")
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
}