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
            .padding(.top, 8)
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
            
            // Content - Use List instead of ScrollView for better swipe actions and sticky headers
            List {
                // Extra top padding
                Section {
                    EmptyView()
                }
                .frame(height: 20)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // Group chats by time period
                if filteredChats.isEmpty {
                    Text("No matching chats")
                        .foregroundColor(styles.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(styles.colors.menuBackground)
                        .listRowInsets(EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 0))
                } else {
                    ForEach(filteredGroupedChats, id: \.0) { section, chats in
                        // Section header - Use the RENAMED component, passing the correct background
                        Section(header: SharedSectionHeader(title: section, backgroundColor: styles.colors.menuBackground)) {
                            // Chats in this section
                            ForEach(chats) { chat in
                                ChatHistoryItem(chat: chat, onStar: {
                                    chatManager.toggleStarChat(chat)
                                })
                                .onTapGesture {
                                    onSelectChat(chat)
                                }
                                .listRowBackground(styles.colors.menuBackground)
                                .listRowInsets(EdgeInsets(top: 4, leading: styles.layout.paddingL, bottom: 4, trailing: styles.layout.paddingL))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        chatToDelete = chat
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Bottom padding
                Section {
                    EmptyView()
                }
                .frame(height: 50)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .listStyle(PlainListStyle())
            .background(styles.colors.menuBackground)
            // Remove separators
            .environment(\.defaultMinListRowHeight, 1)
            // Dismiss keyboard when scrolling
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
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
      .padding(styles.layout.paddingL) // Restored original padding
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
    
    // Constants
    private let deleteWidth: CGFloat = 80
    private let styles = UIStyles.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Main content
            content()
            
            // Delete button
            Button(action: deleteAction) {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: deleteWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                    .cornerRadius(styles.layout.radiusM)
            }
            .frame(width: deleteWidth)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cornerRadius(styles.layout.radiusM)
        .contentShape(Rectangle())
    }
}