import SwiftUI

struct FilterPanel: View {
    @Binding var searchText: String
    @Binding var searchTags: [String]
    @Binding var selectedMoods: Set<Mood>
    @Binding var dateFilterType: DateFilterType
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date
    var onClearFilters: () -> Void
    
    @State private var activeTab: FilterTab = .keywords

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    enum FilterTab {
        case keywords, mood, date
    }
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            // Tab selector
            HStack {
                FilterTabButton(title: "Keywords", isSelected: activeTab == .keywords) {
                    withAnimation { activeTab = .keywords }
                }
                
                FilterTabButton(title: "Mood", isSelected: activeTab == .mood) {
                    withAnimation { activeTab = .mood }
                }
                
                FilterTabButton(title: "Date", isSelected: activeTab == .date) {
                    withAnimation { activeTab = .date }
                }
            }
            .padding(.horizontal, styles.layout.paddingM)
            
            // Tab content
            VStack(spacing: styles.layout.spacingM) {
                switch activeTab {
                case .keywords:
                    keywordsTab
                case .mood:
                    moodTab
                case .date:
                    dateTab
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
                
                Text("\(searchTags.count + selectedMoods.count + (dateFilterType != .all ? 1 : 0)) active filters")
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
            }
            .padding(.horizontal, styles.layout.paddingM)
        }
        .padding(styles.layout.paddingM)
        .background(styles.colors.reflectionsNavBackground) // Use theme color (similar context)
        .cornerRadius(styles.layout.radiusL)
        // REMOVED: .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
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
                    // REMOVED: .modifier(AdaptiveColorSchemeModifier())
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
    
    private var moodTab: some View {
        VStack(spacing: styles.layout.spacingS) {
            Text("Select moods to filter by:")
                .font(styles.typography.bodySmall)
                .foregroundColor(styles.colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Grid layout for mood selection to accommodate all emotions
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    Button(action: {
                        toggleMood(mood)
                    }) {
                        Text(mood.name)
                            .font(styles.typography.caption)
                            .foregroundColor(selectedMoods.contains(mood) ? styles.colors.text : styles.colors.textSecondary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                    .fill(selectedMoods.contains(mood) ? 
                                          mood.color.opacity(0.3) : 
                                          styles.colors.appBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                    .stroke(selectedMoods.contains(mood) ? 
                                            mood.color.opacity(0.5) : 
                                            Color.clear, lineWidth: 1)
                            )
                    }
                }
            }
            
            // Clear all button
            if !selectedMoods.isEmpty {
                Button("Clear All") {
                    selectedMoods.removeAll()
                }
                .font(styles.typography.bodySmall)
                .foregroundColor(styles.colors.accent)
                .padding(.top, 8)
            }
        }
    }
    
    private var dateTab: some View {
        VStack(spacing: styles.layout.spacingS) {
            // Regular date filter options
            ForEach(DateFilterType.allCases.filter { $0 != .custom }, id: \.self) { filterType in
                Button(action: {
                    dateFilterType = filterType
                }) {
                    HStack {
                        Text(filterType.rawValue)
                            .font(styles.typography.bodySmall)
                            .foregroundColor(styles.colors.text)
                    
                        Spacer()
                    
                        if dateFilterType == filterType {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(styles.colors.accent)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: styles.layout.radiusM)
                            .fill(dateFilterType == filterType ? styles.colors.secondaryBackground : Color.clear) // Use Color.clear for unselected
                    )
                }
            }
            
            // Custom date range as a special expandable option
            Button(action: {
                dateFilterType = .custom
            }) {
                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text(DateFilterType.custom.rawValue)
                            .font(styles.typography.bodySmall)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                        
                        if dateFilterType == .custom {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(styles.colors.accent)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    
                    // Expanded content when selected
                    if dateFilterType == .custom {
                        Divider()
                            .background(styles.colors.divider)
                            .padding(.horizontal, 8)
                        
                        VStack(alignment: .leading, spacing: styles.layout.spacingS) { // Use standard spacing
                            // Start date row
                            HStack(alignment: .center) {
                                Text("Start:")
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .frame(width: 50, alignment: .leading)
                                
                                StyledDatePicker(selection: $customStartDate, displayedComponents: .date)
                                
                                Spacer()
                            }
                            
                            // End date row
                            HStack(alignment: .center) {
                                Text("End:")
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .frame(width: 50, alignment: .leading)
                                
                                StyledDatePicker(selection: $customEndDate, displayedComponents: .date)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 12) // Add horizontal padding to inner VStack
                        .padding(.vertical, 8) // Add vertical padding to inner VStack
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: styles.layout.radiusM)
                        .fill(dateFilterType == .custom ? styles.colors.secondaryBackground : Color.clear) // Use Color.clear for unselected
                )
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
    
    private func toggleMood(_ mood: Mood) {
        withAnimation {
            if selectedMoods.contains(mood) {
                selectedMoods.remove(mood)
            } else {
                selectedMoods.insert(mood)
            }
        }
    }
}

// Update the FilterTabButton to be more compact and visually distinct
struct FilterTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(styles.typography.bodySmall)
                .foregroundColor(isSelected ? styles.colors.accent : styles.colors.textSecondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    isSelected ?
                        RoundedRectangle(cornerRadius: styles.layout.radiusM)
                        .fill(styles.colors.secondaryBackground) : nil
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Update the Array extension to filter by mood regardless of intensity

// Helper extension to filter journal entries
extension Array where Element == JournalEntry {
    func filtered(
        by searchTags: [String],
        moods: Set<Mood>,
        dateFilter: DateFilterType,
        customStartDate: Date,
        customEndDate: Date
    ) -> [JournalEntry] {
        var entries = self
        
        // Filter by search tags
        if !searchTags.isEmpty {
            entries = entries.filter { entry in
                searchTags.contains { tag in
                    entry.text.lowercased().contains(tag.lowercased())
                }
            }
        }
        
        // Filter by mood - match base mood regardless of intensity
        if !moods.isEmpty {
            entries = entries.filter { entry in
                moods.contains(entry.mood)
            }
        }
        
        // Filter by date
        switch dateFilter {
        case .today:
            entries = entries.filter { Calendar.current.isDateInToday($0.date) }
        case .thisWeek:
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            entries = entries.filter { $0.date >= startOfWeek }
        case .thisMonth:
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: Date())
            let startOfMonth = calendar.date(from: components)!
            entries = entries.filter { $0.date >= startOfMonth }
        case .custom:
            entries = entries.filter {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: customStartDate)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEndDate))!
                // Ensure comparison includes start day and excludes day after end day
                return $0.date >= startOfDay && $0.date < endOfDay
            }
        case .all:
            // No date filtering
            break
        }
        
        return entries
    }
}