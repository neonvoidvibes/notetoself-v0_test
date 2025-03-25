import SwiftUI

struct ChatHistoryView: View {
  @EnvironmentObject var appState: AppState
  @ObservedObject var chatManager: ChatManager
  var onSelectChat: (Chat) -> Void
  var onDismiss: () -> Void  // Add this line
  
  // Add filter state variables
  @State private var showingFilterPanel = false
  @State private var searchText = ""
  @State private var searchTags: [String] = []
  @State private var showStarredOnly = false
  
  // Access to shared styles
  private let styles = UIStyles.shared
  
  var body: some View {
      ZStack {
          styles.colors.menuBackground
              .ignoresSafeArea()
          
          VStack(spacing: 0) {
              // Header
              ZStack(alignment: .center) {
                  // Title truly centered
                  VStack(spacing: 8) {
                      Text("Chats")
                          .font(styles.typography.title1)
                          .foregroundColor(styles.colors.text)
                      
                      Rectangle()
                          .fill(styles.colors.accent)
                          .frame(width: 20, height: 3)
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
                      
                      Menu {
                          Button(action: {
                              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                  showingFilterPanel.toggle()
                              }
                          }) {
                              Label("Filter Chats", systemImage: "slider.horizontal.2.square")
                          }
                          
                          Button(action: {
                              // Start a new chat and close the history view
                              chatManager.startNewChat()
                              onDismiss()  // Use the passed in dismiss action
                          }) {
                              Label("New Chat", systemImage: "square.and.pencil")
                          }
                      } label: {
                          Image(systemName: "ellipsis.circle")
                              .font(.system(size: 22))
                              .foregroundColor(styles.colors.text)
                              .frame(width: 36, height: 36)
                      }
                  }
                  .padding(.horizontal, styles.layout.paddingXL)
              }
              .padding(.top, 8) // Same top padding as other views
              .padding(.bottom, 8)
              
              // Filter panel
              if showingFilterPanel {
                  ChatFilterPanel(
                      searchText: $searchText,
                      searchTags: $searchTags,
                      showStarredOnly: $showStarredOnly,
                      onClearFilters: {
                          clearFilters()
                      }
                  )
                  .transition(.move(edge: .top).combined(with: .opacity))
              }
              
              // Content
              ScrollView {
                  VStack(alignment: .leading, spacing: 0) {
                      // Extra top padding
                      Spacer()
                          .frame(height: 30)
                      
                      // Group chats by time period
                      let groupedChats = chatManager.groupChatsByTimePeriod()
                      
                      if filteredChats.isEmpty {
                          Text("No matching chats")
                              .foregroundColor(styles.colors.textSecondary)
                              .padding(.top, 40)
                              .frame(maxWidth: .infinity, alignment: .center)
                      } else {
                          ForEach(filteredGroupedChats, id: \.0) { section, chats in
                              // Section header - aligned with text inside cards
                              Text(section)
                                  .font(styles.typography.title3)
                                  .foregroundColor(styles.colors.text)
                                  .frame(maxWidth: .infinity, alignment: .leading)
                                  .padding(.leading, styles.layout.paddingL + styles.layout.paddingM) // Align with text inside cards
                                  .padding(.trailing, styles.layout.paddingL)
                                  .padding(.top, 20)
                                  .padding(.bottom, 10)
                              
                              // Chats in this section
                              ForEach(chats) { chat in
                                  Button(action: {
                                      onSelectChat(chat)
                                  }) {
                                      ChatHistoryItem(
                                          chat: chat,
                                          onStar: {
                                              chatManager.toggleStarChat(chat)
                                          }
                                      )
                                  }
                                  .buttonStyle(PlainButtonStyle())
                                  .padding(.horizontal, styles.layout.paddingL)
                                  .padding(.vertical, 4)
                              }
                          }
                      }
                      
                      Spacer(minLength: 50)
                  }
                  .padding(.top, styles.headerPadding.top)
              }
          }
      }
  }
  
  private func clearFilters() {
      searchText = ""
      searchTags = []
      showStarredOnly = false
      
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          showingFilterPanel = false
      }
  }
  
  // Computed property to filter chats
  private var filteredChats: [Chat] {
      chatManager.chats.filter { chat in
          // If we're only showing starred, check if the chat is starred
          if showStarredOnly && !chat.isStarred {
              return false
          }
          
          // If we have search tags, check if any message in the chat contains the tags
          if !searchTags.isEmpty {
              return chat.messages.contains { message in
                  searchTags.contains { tag in
                      message.text.lowercased().contains(tag.lowercased())
                  }
              }
          }
          
          // If no filters are applied, show all chats
          return true
      }
  }
  
  // Filtered and grouped chats
  private var filteredGroupedChats: [(String, [Chat])] {
      let groupedChats = chatManager.groupChatsByTimePeriod()
      
      return groupedChats.compactMap { section, chats in
          let filteredSectionChats = chats.filter { chat in
              // If we're only showing starred, check if the chat is starred
              if showStarredOnly && !chat.isStarred {
                  return false
              }
              
              // If we have search tags, check if any message in the chat contains the tags
              if !searchTags.isEmpty {
                  return chat.messages.contains { message in
                      searchTags.contains { tag in
                          message.text.lowercased().contains(tag.lowercased())
                      }
                  }
              }
              
              // If no filters are applied, show all chats
              return true
          }
          
          // Only return sections that have chats after filtering
          return filteredSectionChats.isEmpty ? nil : (section, filteredSectionChats)
      }
  }
}

struct ChatHistoryItem: View {
  let chat: Chat
  var onStar: () -> Void
  private let styles = UIStyles.shared
  
  var body: some View {
      VStack(alignment: .leading, spacing: 8) {
          HStack {
              Text(chat.title)
                  .font(styles.typography.bodyFont)
                  .foregroundColor(styles.colors.text)
                  .lineLimit(1)
              
              Spacer()
              
              if chat.isStarred {
                  Image(systemName: "star.fill")
                      .font(.system(size: 14))
                      .foregroundColor(styles.colors.accent)
                      .padding(.trailing, 4)
              }
              
              Text(formatDate(chat.lastUpdatedAt))
                  .font(styles.typography.caption)
                  .foregroundColor(styles.colors.textSecondary)
          }
          
          // Show the last message if available
          if let lastMessage = chat.messages.last {
              HStack(spacing: 2) {
                  Text(lastMessage.isUser ? "You: " : "AI: ")
                      .font(styles.typography.bodySmall)
                      .foregroundColor(lastMessage.isUser ? styles.colors.accent : styles.colors.textSecondary)
                  
                  Text(lastMessage.text)
                      .font(styles.typography.bodySmall)
                      .foregroundColor(styles.colors.textSecondary)
                      .lineLimit(2)
                      .truncationMode(.tail)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
          }
      }
      .padding(styles.layout.paddingM) // Restored original padding
      .background(styles.colors.secondaryBackground)
      .cornerRadius(styles.layout.radiusM)
      .overlay(
          RoundedRectangle(cornerRadius: styles.layout.radiusM)
              .stroke(Color(hex: "#222222"), lineWidth: 1) // Same border as JournalView
      )
      .contentShape(Rectangle())
      .onLongPressGesture {
          onStar()
      }
  }
  
  private func formatDate(_ date: Date) -> String {
      let formatter = DateFormatter()
      formatter.dateFormat = "MMM d, h:mm a"
      return formatter.string(from: date)
  }
}

