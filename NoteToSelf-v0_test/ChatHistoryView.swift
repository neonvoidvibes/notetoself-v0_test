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
  
  // Confirmation modal state
  @State private var showingDeleteConfirmation = false
  @State private var chatToDelete: Chat? = nil
  
  // Access to shared styles
  private let styles = UIStyles.shared
  
  var body: some View {
      ZStack {
          styles.colors.menuBackground
              .ignoresSafeArea()
          
          // Add a tap gesture to the entire view to dismiss keyboard
          Color.clear
              .contentShape(Rectangle())
              .ignoresSafeArea()
              .onTapGesture {
                  UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
              }
          
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
              .padding(.top, 8) // Same top padding as other views
              .padding(.bottom, 8)
              
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
              
              // Content
              ScrollView {
                  LazyVStack(alignment: .leading, spacing: 0) {
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
                                  SwipeableRow(
                                      content: {
                                          ChatHistoryItem(chat: chat, onStar: {
                                              chatManager.toggleStarChat(chat)
                                          })
                                          .onTapGesture {
                                              onSelectChat(chat)
                                          }
                                      },
                                      deleteAction: {
                                          chatToDelete = chat
                                          showingDeleteConfirmation = true
                                      }
                                  )
                                  .padding(.horizontal, styles.layout.paddingL)
                                  .padding(.vertical, 4)
                              }
                          }
                      }
                      
                      Spacer(minLength: 50)
                  }
                  .padding(.top, styles.headerPadding.top)
              }
              // Add a tap gesture to dismiss keyboard when scrolling
              .simultaneousGesture(
                  DragGesture(minimumDistance: 5)
                      .onChanged { _ in
                          UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                      }
              )
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
  }
  
  private func clearFilters() {
      searchText = ""
      searchTags = []
      showStarredOnly = false
      dateFilterType = .all
      
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
              let containsTag = chat.messages.contains { message in
                  searchTags.contains { tag in
                      message.text.lowercased().contains(tag.lowercased())
                  }
              }
              if !containsTag {
                  return false
              }
          }
          
          // Filter by date
          let chatDate = chat.lastUpdatedAt
          switch dateFilterType {
          case .today:
              if !Calendar.current.isDateInToday(chatDate) {
                  return false
              }
          case .thisWeek:
              let calendar = Calendar.current
              let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
              if chatDate < startOfWeek {
                  return false
              }
          case .thisMonth:
              let calendar = Calendar.current
              let components = calendar.dateComponents([.year, .month], from: Date())
              let startOfMonth = calendar.date(from: components)!
              if chatDate < startOfMonth {
                  return false
              }
          case .custom:
              let calendar = Calendar.current
              let startOfDay = calendar.startOfDay(for: customStartDate)
              let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEndDate))!
              if chatDate < startOfDay || chatDate >= endOfDay {
                  return false
              }
          case .all:
              // No date filtering
              break
          }
          
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
                  let containsTag = chat.messages.contains { message in
                      searchTags.contains { tag in
                          message.text.lowercased().contains(tag.lowercased())
                      }
                  }
                  if !containsTag {
                      return false
                  }
              }
              
              // Filter by date
              let chatDate = chat.lastUpdatedAt
              switch dateFilterType {
              case .today:
                  if !Calendar.current.isDateInToday(chatDate) {
                      return false
                  }
              case .thisWeek:
                  let calendar = Calendar.current
                  let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
                  if chatDate < startOfWeek {
                      return false
                  }
              case .thisMonth:
                  let calendar = Calendar.current
                  let components = calendar.dateComponents([.year, .month], from: Date())
                  let startOfMonth = calendar.date(from: components)!
                  if chatDate < startOfMonth {
                      return false
                  }
              case .custom:
                  let calendar = Calendar.current
                  let startOfDay = calendar.startOfDay(for: customStartDate)
                  let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEndDate))!
                  if chatDate < startOfDay || chatDate >= endOfDay {
                      return false
                  }
              case .all:
                  // No date filtering
                  break
              }
              
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
                  .padding(.trailing, 8) // Add extra padding to the title
              
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
              .stroke(chat.isStarred ? styles.colors.accent : Color(hex: "#222222"), lineWidth: chat.isStarred ? 2 : 1)
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

struct SwipeableRow<Content: View>: View {
    let content: () -> Content
    let deleteAction: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var showingDelete = false
    @State private var isDragging = false
    
    // Constants
    private let deleteWidth: CGFloat = 80
    private let deleteThreshold: CGFloat = 50
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button (right side)
            Button(action: deleteAction) {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: deleteWidth, height: 80)
                    .background(Color.red)
                    .cornerRadius(styles.layout.radiusM)
            }
            .opacity(offset < 0 ? 1 : 0)
            
            // Content
            content()
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { gesture in
                            isDragging = true
                            
                            // Only allow right-to-left swipe (negative values)
                            // and limit the drag to deleteWidth
                            let dragAmount = gesture.translation.width
                            if dragAmount < 0 {
                                offset = max(-deleteWidth, dragAmount)
                                showingDelete = true
                            } else if showingDelete {
                                // Allow dragging back to original position
                                offset = min(0, dragAmount)
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            
                            withAnimation(.spring()) {
                                if offset < -deleteThreshold {
                                    // Keep delete button visible
                                    offset = -deleteWidth
                                    showingDelete = true
                                } else {
                                    // Reset position
                                    offset = 0
                                    showingDelete = false
                                }
                            }
                        }
                )
                // This prevents tap gestures from being recognized during drag
                .allowsHitTesting(!isDragging)
        }
    }
}

