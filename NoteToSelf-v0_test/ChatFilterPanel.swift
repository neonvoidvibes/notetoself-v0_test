import SwiftUI

struct ChatFilterPanel: View {
    @Binding var searchText: String
    @Binding var searchTags: [String]
    @Binding var showStarredOnly: Bool
    var onClearFilters: () -> Void
    
    @State private var activeTab: FilterTab = .keywords
    
    private let styles = UIStyles.shared
    
    enum FilterTab {
        case keywords, starred
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            // Tab selector
            HStack {
                FilterTabButton(title: "Keywords", isSelected: activeTab == .keywords) {
                    withAnimation { activeTab = .keywords }
                }
                
                FilterTabButton(title: "Starred", isSelected: activeTab == .starred) {
                    withAnimation { activeTab = .starred }
                }
            }
            .padding(.horizontal, styles.layout.paddingM)
            
            // Tab content
            VStack(spacing: styles.layout.spacingM) {
                switch activeTab {
                case .keywords:
                    keywordsTab
                case .starred:
                    starredTab
                }
            }
            
            // Filter actions
            HStack {
                Button(action: onClearFilters) {
                    Text("Clear Filters")
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.accent)
                }
                
                Spacer(minLength: 20) // Reduced spacer with minimum length to bring elements closer
                
                Text("\(searchTags.count + (showStarredOnly ? 1 : 0)) active filters")
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
            }
            .padding(.horizontal, styles.layout.paddingM)
        }
        .padding(styles.layout.paddingM)
        .background(Color(hex: "#1A1A1A")) // Darker gray for contrast
        .cornerRadius(styles.layout.radiusL)
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        .padding(.horizontal, styles.layout.paddingL)
        .contentShape(Rectangle()) // Make the entire filter panel tappable
        .onTapGesture {
            // Dismiss keyboard when tapping anywhere in the filter panel
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private var keywordsTab: some View {
        VStack(spacing: styles.layout.spacingM) {
            // Search input
            HStack {
                TextField("Search keywords...", text: $searchText)
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.text)
                    .padding(styles.layout.paddingS)
                    .background(styles.colors.secondaryBackground)
                    .cornerRadius(styles.layout.radiusM)
                    .onSubmit {
                        addSearchTag()
                    }
                
                Button(action: addSearchTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(styles.colors.accent)
                        .font(.system(size: 20))
                }
                .disabled(searchText.isEmpty)
                .opacity(searchText.isEmpty ? 0.5 : 1.0)
            }
            .contentShape(Rectangle()) // Ensure the HStack can receive tap gestures
        
            // Tags display
            if !searchTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: styles.layout.spacingS) {
                        ForEach(searchTags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(styles.typography.bodySmall)
                                    .foregroundColor(styles.colors.text)
                                
                                Button(action: {
                                    removeSearchTag(tag)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(styles.colors.textSecondary)
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(.horizontal, styles.layout.spacingS)
                            .padding(.vertical, 4)
                            .background(styles.colors.secondaryBackground)
                            .cornerRadius(styles.layout.radiusM)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private var starredTab: some View {
        VStack(spacing: styles.layout.spacingS) {
            Toggle("Show Starred Chats Only", isOn: $showStarredOnly)
                .font(styles.typography.bodySmall)
                .foregroundColor(styles.colors.text)
                .toggleStyle(ModernToggleStyle(colors: styles.colors))
                .padding(.vertical, 8)
            
            if showStarredOnly {
                Text("Only showing chats you've starred by long-pressing on them.")
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
                    .padding(.top, 8)
            }
        }
    }
    
    private func addSearchTag() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !searchTags.contains(trimmed) {
            withAnimation {
                searchTags.append(trimmed)
                searchText = ""
            }
        }
    }
    
    private func removeSearchTag(_ tag: String) {
        withAnimation {
            searchTags.removeAll { $0 == tag }
        }
    }
}

