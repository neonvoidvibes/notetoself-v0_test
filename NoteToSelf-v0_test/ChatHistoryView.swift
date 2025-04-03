import SwiftUI

struct ChatHistoryView: View {
  @EnvironmentObject var appState: AppState
  @ObservedObject var chatManager: ChatManager
  var onSelectChat: (Chat) -> Void
  var onDismiss: () -> Void
  
  // Filter state variables
  @State private var showingFilterPanel = false
  @State private var searchText = ""
  @State private var searchTags: [String] = []
  @State private var showStarredOnly = false
  @State private var dateFilterType: DateFilterType = .all
  @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
  @State private var customEndDate: Date = Date()
  
  // Expanded chat state - moved from AppState to local state
  @State private var expandedChatId: UUID? = nil
  
  // Confirmation modal state
  @State private var showingDeleteConfirmation = false
  @State private var chatToDelete: Chat? = nil

  // Header animation state
  @State private var headerAppeared = false

  // Access to shared styles
  @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

  var body: some View {
      ZStack {
        styles.colors.menuBackground
            .ignoresSafeArea()
        
        VStack(spacing: 0) {
            // Header
            headerView()
            
            // Filter panel
            if showingFilterPanel {
                ChatFilterPanel(
                    searchText: $searchText,
                    searchTags: $searchTags,
                    showStarredOnly: $showStarredOnly,
                    dateFilterType: $dateFilterType,
                    customStartDate: $customStartDate,
                    customEndDate: $customEndDate,
                    onClearFilters: {
                        clearFilters()
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Content - Use ScrollView with LazyVStack like JournalView
            chatListView()
        }
        
        // Confirmation modal
        if showingDeleteConfirmation, let chat = chatToDelete {
            ConfirmationModal(
                title: "Delete Chat",
                message: "Are you sure you want to delete this chat? This action cannot be undone.",
                confirmText: "Delete",
                confirmAction: {
                    chatManager.deleteChat(chat)
                    showingDeleteConfirmation = false
                    chatToDelete = nil
                },
                cancelAction: {
                    showingDeleteConfirmation = false
                    chatToDelete = nil
                },
                isDestructive: true
            )
            .animation(.spring(), value: showingDeleteConfirmation)
        }
    }
    .onAppear {
        // Set the first chat as expanded by default if there are any chats
        if expandedChatId == nil, let firstChat = filteredChats.first {
            expandedChatId = firstChat.id
          }
      }
    .onAppear { // Trigger animation when view appears
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
             headerAppeared = true
         }
     }
}

// Header view with title and buttons
  private func headerView() -> some View {
      ZStack(alignment: .center) {
          // Title truly centered
          VStack(spacing: 8) {
              Text("Chats")
                  .font(styles.typography.title1)
                  .foregroundColor(styles.colors.text)

               // Animated accent bar
               Rectangle()
                   .fill(
                       LinearGradient(
                           gradient: Gradient(colors: [
                               styles.colors.accent.opacity(0.7),
                               styles.colors.accent
                           ]),
                           startPoint: .leading,
                           endPoint: .trailing
                       )
                   )
                   .frame(width: headerAppeared ? 30 : 0, height: 3)
                   .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: headerAppeared)
          }

          // Left-aligned back button
          HStack {
              // Back button (double chevron left) at left side
              Button(action: {
                  onDismiss()  // Use the passed in dismiss action
              }) {
                  Image(systemName: "chevron.left.2")
                      .font(.system(size: 20, weight: .bold))
                      .foregroundColor(styles.colors.accent)
                      .frame(width: 36, height: 36)
              }
              
              Spacer()
          }
          .padding(.horizontal, styles.layout.paddingXL)
          
          // Right-aligned action buttons in a menu
          HStack {
              Spacer()
              
              // Filter button
              Button(action: {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                      showingFilterPanel.toggle()
                  }
              }) {
                  Image(systemName: "slider.horizontal.2.square")
                      .font(.system(size: 20))
                      .foregroundColor(showingFilterPanel || !searchTags.isEmpty || showStarredOnly || dateFilterType != .all ? styles.colors.accent : styles.colors.text)
              }
          }
          .padding(.horizontal, styles.layout.paddingXL)
      }
      .padding(.top, 8)
      .padding(.bottom, 8)
  }
  
  // Chat list view with ScrollView and LazyVStack
  private func chatListView() -> some View {
      ScrollView {
          // Group chats by time period
          if filteredChats.isEmpty {
              emptyStateView()
          } else {
              chatSectionsList()
          }
      }
      .background(styles.colors.menuBackground)
      // Dismiss keyboard when scrolling
      .simultaneousGesture(
          DragGesture(minimumDistance: 20)
              .onChanged { _ in
                  UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
              }
      )
  }
  
  // Extracted chat sections list to simplify the view hierarchy
  private func chatSectionsList() -> some View {
      LazyVStack(spacing: styles.layout.radiusM, pinnedViews: [.sectionHeaders]) {
          ForEach(filteredGroupedChats, id: \.0) { section, chats in
              // Section header - Use the SharedSectionHeader component
              Section(header: SharedSectionHeader(title: section, backgroundColor: styles.colors.menuBackground)
                                  .id("header-\(section)")
              ) {
                  // Chats in this section
                  ForEach(chats) { chat in
                      chatCard(for: chat)
                  }
              }
          }
      }
      .padding(.bottom, 50)
  }
  
  // Extracted chat card creation to simplify the view hierarchy
  private func chatCard(for chat: Chat) -> some View {
      ChatHistoryCard(
          chat: chat,
          isExpanded: expandedChatId == chat.id,
          onTap: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                  expandedChatId = expandedChatId == chat.id ? nil : chat.id
              }
          },
          onOpen: {
              onSelectChat(chat)
          },
          onStar: {
              chatManager.toggleStarChat(chat)
          },
          onDelete: {
              // Set the chat to delete and show the confirmation modal
              chatToDelete = chat
              showingDeleteConfirmation = true
          }
      )
      .padding(.horizontal, styles.layout.paddingL)
      .transition(.opacity.combined(with: .move(edge: .top)))
  }
  
  // Empty state view when no chats match filters
  private func emptyStateView() -> some View {
      VStack(alignment: .center, spacing: 16) {
          if !searchTags.isEmpty || showStarredOnly || dateFilterType != .all {
              Text("No Matching Chats")
                  .font(styles.typography.bodyFont)
                  .foregroundColor(styles.colors.text)
                  .padding(.top, 60)
              Text("Try adjusting your filters")
                  .font(styles.typography.bodySmall)
                  .foregroundColor(styles.colors.textSecondary)
              Button("Clear Filters") { clearFilters(closePanel: true) }
                  .font(styles.typography.bodyFont)
                  .foregroundColor(styles.colors.accent)
                  .padding(.top, 8)
          } else {
              Text("No chats yet.")
                  .font(styles.typography.headingFont)
                  .foregroundColor(styles.colors.text)
                  .padding(.top, 60)
              Text("Start a new conversation to begin.")
                  .font(styles.typography.bodyFont)
                  .foregroundColor(styles.colors.textSecondary)
          }
          Spacer()
      }
      .frame(maxWidth: .infinity)
      .padding()
  }
  
  // Clear filters function
  private func clearFilters(closePanel: Bool = false) {
      searchText = ""
      searchTags = []
      showStarredOnly = false
      dateFilterType = .all
      
      if closePanel {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              showingFilterPanel = false
          }
      }
  }
  
  // Computed property to filter chats - simplified
  private var filteredChats: [Chat] {
      return chatManager.chats.filter { chat in
          passesAllFilters(chat)
      }
  }
  
  // Helper function to check if a chat passes all filters
  private func passesAllFilters(_ chat: Chat) -> Bool {
      // Check if starred filter passes
      if showStarredOnly && !chat.isStarred {
          return false
      }
      
      // Check if tag filter passes
      if !searchTagFilterPasses(chat) {
          return false
      }
      
      // Check if date filter passes
      if !dateFilterPasses(chat.lastUpdatedAt) {
          return false
      }
      
      return true
  }
  
  // Helper function to check if a chat passes the search tag filter
  private func searchTagFilterPasses(_ chat: Chat) -> Bool {
    if searchTags.isEmpty {
        return true
    }
    
    return chat.messages.contains { message in
        searchTags.contains { tag in
            (message as? MessageDisplayable)?.text.lowercased().contains(tag.lowercased()) ?? false
        }
    }
  }
  
  // Helper function to check if a date passes the date filter
  private func dateFilterPasses(_ date: Date) -> Bool {
      switch dateFilterType {
      case .today:
          return Calendar.current.isDateInToday(date)
      case .thisWeek:
          let calendar = Calendar.current
          let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
          return date >= startOfWeek
      case .thisMonth:
          let calendar = Calendar.current
          let components = calendar.dateComponents([.year, .month], from: Date())
          let startOfMonth = calendar.date(from: components)!
          return date >= startOfMonth
      case .custom:
          let calendar = Calendar.current
          let startOfDay = calendar.startOfDay(for: customStartDate)
          let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEndDate))!
          return date >= startOfDay && date < endOfDay
      case .all:
          return true
      }
  }
  
  // Filtered and grouped chats - simplified
  private var filteredGroupedChats: [(String, [Chat])] {
      // Get the grouped chats
      let groupedChats = chatManager.groupChatsByTimePeriod()
      
      // Process each group
      var result: [(String, [Chat])] = []
      
      for (section, chats) in groupedChats {
          // Filter the chats in this section
          let filteredSectionChats = filterChatsInSection(chats)
          
          // Only add sections that have chats after filtering
          if !filteredSectionChats.isEmpty {
              result.append((section, filteredSectionChats))
          }
      }
      
      return result
  }
  
  // Helper function to filter chats in a section
  private func filterChatsInSection(_ chats: [Chat]) -> [Chat] {
      return chats.filter { chat in
          passesAllFilters(chat)
      }
  }
}

// New ChatHistoryCard component modeled after JournalEntryCard
struct ChatHistoryCard: View {
    let chat: Chat
    let isExpanded: Bool
    let onTap: () -> Void
    let onOpen: () -> Void
    let onStar: () -> Void
    let onDelete: () -> Void  // Add this new parameter

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header always visible
            cardHeader()
            
            // Expanded content
            if isExpanded {
                Divider()
                    .background(styles.colors.divider) // Use theme color
                    .padding(.horizontal, 16)

                expandedContent()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .fill(styles.colors.cardBackground) // Use theme color
                // REMOVED: .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                // Use divider color for default border
                .stroke(chat.isStarred ? styles.colors.accent : styles.colors.divider, lineWidth: chat.isStarred ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onStar()
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // Card header view
    private func cardHeader() -> some View {
        HStack(alignment: .center) {
            // Date/Time and truncated text (if not expanded)
            VStack(alignment: .leading, spacing: 6) {
                Text(formatDate(chat.lastUpdatedAt))
                    .font(styles.typography.smallLabelFont)
                    .foregroundColor(styles.colors.secondaryAccent)
                
                if !isExpanded {
                    // Use the first user message for the preview text when collapsed
                    if let firstUserMessage = findFirstUserMessage() {
                        Text(firstUserMessage.text)
                            .lineLimit(1)
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.text)
                    }
                }
            }
            
            Spacer()
            
            // Icons on the right
            HStack(spacing: 12) {
                // Star icon if starred
                if chat.isStarred {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(styles.colors.accent)
                        .padding(.trailing, -4)
                }
                
                // Message count
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(styles.colors.accent)
                        .font(.system(size: 16))
                    
                    if isExpanded {
                        Text("\(chat.messages.count)")
                            .font(styles.typography.caption)
                            .foregroundColor(styles.colors.accent)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                
                // Expand/collapse chevron with rotation
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(styles.colors.secondaryAccent)
                    .rotationEffect(Angle(degrees: isExpanded ? 180 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // Expanded content view
    private func expandedContent() -> some View {
        VStack(spacing: 0) {
            // Show the FIRST user message and AI response
            if let firstUserMessage = findFirstUserMessage(), // Use first user message
               let firstAIMessage = findFirstAIMessage() { // Use first AI message (if available)
                
                // User message
                userMessageView(text: firstUserMessage.text)
                
                // AI message - Use the correct variable name
                aiMessageView(text: firstAIMessage.text)
            }
            
            // Action button - Open chat
            actionButtonView()
        }
    }
    
    // User message view
    private func userMessageView(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("You:")
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.accent)
                Spacer()
            }
            
            Text(text)
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.text)
                .lineLimit(3)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // AI message view
    private func aiMessageView(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AI:")
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
                Spacer()
            }
            
            Text(text)
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.textSecondary)
                .lineLimit(3)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // Action button view
    private func actionButtonView() -> some View {
        HStack {
            // Add delete button on the left with a more subtle gray color
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: styles.layout.iconSizeS))
                    .foregroundColor(styles.colors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            Spacer()
            
            // Continue button (existing)
            Button(action: onOpen) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: styles.layout.iconSizeS))
                    Text("Continue")
                        .font(styles.typography.smallLabelFont)
                }
                .foregroundColor(styles.colors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(styles.colors.secondaryBackground)
                .cornerRadius(styles.layout.radiusM)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // Helper function to find the FIRST user message
    private func findFirstUserMessage() -> ChatMessage? { // Return concrete type
        return chat.messages.first { $0.isUser } // Directly filter and find first
    }
    
    // Helper function to find the FIRST AI message
    private func findFirstAIMessage() -> ChatMessage? { // Return concrete type
        return chat.messages.first { !$0.isUser } // Directly filter and find first
    }
    
    // Format date similar to JournalEntryCard
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today, \(formatTime(date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(formatTime(date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy • h:mm a"
            return formatter.string(from: date)
        }
    }
    
    // Helper for formatting time
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// Define a protocol that matches the properties we need
protocol MessageDisplayable {
    var text: String { get }
    var isUser: Bool { get }
    var id: UUID { get }
}

// Extend ChatMessage to conform to our protocol if needed
extension ChatMessage: MessageDisplayable {}