import SwiftUI

struct JournalView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingNewEntrySheet = false
    @State private var expandedEntryId: UUID? = nil
    // Access to shared styles
    private let styles = UIStyles.shared

    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Journal")
                        .font(styles.typography.headingFont)
                        .foregroundColor(styles.colors.text)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Journal entries
                ScrollView {
                    LazyVStack(spacing: styles.layout.radiusM) {
                        ForEach(appState.journalEntries) { entry in
                            JournalEntryCard(
                                entry: entry,
                                isExpanded: expandedEntryId == entry.id
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    expandedEntryId = expandedEntryId == entry.id ? nil : entry.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Extra padding for floating button
                }
            }
            
            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingNewEntrySheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(styles.colors.appBackground)
                            .frame(width: 60, height: 60)
                            .background(styles.colors.accent)
                            .clipShape(Circle())
                            .shadow(color: styles.colors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showingNewEntrySheet) {
            NewEntryView(onSave: { text, mood in
                let newEntry = JournalEntry(text: text, mood: mood, date: Date())
                appState.journalEntries.insert(newEntry, at: 0)
                expandedEntryId = newEntry.id // Auto-expand new entry
            })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct JournalEntryCard: View {
    let entry: JournalEntry
    let isExpanded: Bool
    let onTap: () -> Void

    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header always visible
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatDate(entry.date))
                        .font(styles.typography.smallLabelFont)
                        .foregroundColor(styles.colors.secondaryAccent)
                    
                    if !isExpanded {
                        Text(entry.text)
                        Text(entry.text)
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.text)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Mood icon
                    entry.mood.icon
                        .foregroundColor(entry.mood.color)
                        .font(.system(size: 20))
                    
                    // Lock icon if needed
                    if entry.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#FF6B6B"))
                    }
                    
                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(styles.colors.secondaryAccent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Expanded content
            if isExpanded {
                Divider()
                    .background(Color(hex: "#222222"))
                    .padding(.horizontal, 16)
                
                Text(entry.text)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.text)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: styles.layout.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .stroke(Color(hex: "#222222"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onTapGesture {
            onTap()
        }
    }
    
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.loadSampleData()
        return JournalView().environmentObject(appState)
    }
}