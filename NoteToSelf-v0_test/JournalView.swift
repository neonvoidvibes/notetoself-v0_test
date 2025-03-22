import SwiftUI

struct JournalView: View {
    @State private var entries: [JournalEntry] = []
    @State private var showingNewEntrySheet = false
    @State private var expandedEntryId: UUID? = nil
    
    // Color theme
    private let colors = JournalTheme.colors
    
    var body: some View {
        ZStack {
            // Background
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Journal")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(colors.text)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Journal entries
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(entries) { entry in
                            JournalEntryCard(
                                entry: entry,
                                isExpanded: expandedEntryId == entry.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        expandedEntryId = expandedEntryId == entry.id ? nil : entry.id
                                    }
                                }
                            )
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
                            .foregroundColor(colors.background)
                            .frame(width: 60, height: 60)
                            .background(colors.accent)
                            .clipShape(Circle())
                            .shadow(color: colors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showingNewEntrySheet) {
            NewEntryView(onSave: { text, mood in
                let newEntry = JournalEntry(text: text, mood: mood, date: Date())
                entries.insert(newEntry, at: 0)
                expandedEntryId = newEntry.id // Auto-expand new entry
            })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Load sample data
            if entries.isEmpty {
                loadSampleEntries()
            }
        }
    }
    
    private func loadSampleEntries() {
        let calendar = Calendar.current
        
        // Today's entry
        entries.append(JournalEntry(
            text: "Completed the new design for the journaling app today. Really proud of how the dark theme turned out.",
            mood: .happy,
            date: Date()
        ))
        
        // Yesterday's entry
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
            entries.append(JournalEntry(
                text: "Worked on wireframes all day. Feeling a bit drained but making good progress.",
                mood: .neutral,
                date: yesterday
            ))
        }
        
        // Two days ago
        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) {
            entries.append(JournalEntry(
                text: "Started the new project today. Excited about the possibilities but also feeling a bit overwhelmed by the scope.",
                mood: .anxious,
                date: twoDaysAgo
            ))
        }
        
        // Last week
        if let lastWeek = calendar.date(byAdding: .day, value: -7, to: Date()) {
            entries.append(JournalEntry(
                text: "Taking a short break from work to recharge. Spent the day hiking and it was exactly what I needed.",
                mood: .happy,
                date: lastWeek
            ))
        }
    }
}

struct JournalEntryCard: View {
    let entry: JournalEntry
    let isExpanded: Bool
    let onTap: () -> Void
    
    // Color theme
    private let colors = JournalTheme.colors
    
    private var isLocked: Bool {
        let hoursSinceCreation = Calendar.current.dateComponents([.hour], from: entry.date, to: Date()).hour ?? 0
        return hoursSinceCreation >= 24
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header always visible
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatDate(entry.date))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(colors.secondaryText)
                    
                    if !isExpanded {
                        Text(entry.text)
                            .lineLimit(1)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(colors.text)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Mood icon
                    entry.mood.icon
                        .foregroundColor(entry.mood.color)
                        .font(.system(size: 20))
                    
                    // Lock icon if needed
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(colors.lockIcon)
                    }
                    
                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(colors.secondaryText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Expanded content
            if isExpanded {
                Divider()
                    .background(colors.divider)
                    .padding(.horizontal, 16)
                
                Text(entry.text)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(colors.text)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
        .background(colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colors.cardBorder, lineWidth: 1)
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

struct NewEntryView: View {
    let onSave: (String, Mood) -> Void
    
    @State private var entryText: String = ""
    @State private var selectedMood: Mood = .neutral
    @Environment(\.dismiss) private var dismiss
    
    // Color theme
    private let colors = JournalTheme.colors
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Text editor
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $entryText)
                            .font(.system(size: 18))
                            .padding(16)
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(colors.textEditorBackground)
                            .cornerRadius(12)
                            .foregroundColor(colors.text)
                        
                        if entryText.isEmpty {
                            Text("What's on your mind today?")
                                .font(.system(size: 18))
                                .foregroundColor(colors.placeholderText)
                                .padding(22)
                        }
                    }
                    
                    // Mood selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How are you feeling?")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(colors.secondaryText)
                        
                        HStack(spacing: 16) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                Button(action: {
                                    selectedMood = mood
                                }) {
                                    VStack(spacing: 8) {
                                        mood.icon
                                            .font(.system(size: 24))
                                            .foregroundColor(selectedMood == mood ? mood.color : colors.secondaryText)
                                        
                                        Text(mood.name)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(selectedMood == mood ? colors.text : colors.secondaryText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedMood == mood ? colors.moodSelectedBackground : colors.moodBackground)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(entryText, selectedMood)
                        dismiss()
                    }
                    .foregroundColor(colors.accent)
                    .disabled(entryText.isEmpty)
                    .opacity(entryText.isEmpty ? 0.5 : 1.0)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Models and Theme

struct JournalEntry: Identifiable {
    let id = UUID()
    let text: String
    let mood: Mood
    let date: Date
}

enum Mood: String, CaseIterable {
    case happy, neutral, sad, anxious, excited
    
    var name: String {
        switch self {
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .sad: return "Sad"
        case .anxious: return "Anxious"
        case .excited: return "Excited"
        }
    }
    
    var icon: some View {
        switch self {
        case .happy: return Image(systemName: "face.smiling")
        case .neutral: return Image(systemName: "face.dashed")
        case .sad: return Image(systemName: "cloud.rain")
        case .anxious: return Image(systemName: "exclamationmark.triangle")
        case .excited: return Image(systemName: "star")
        }
    }
    
    var color: Color {
        switch self {
        case .happy: return .yellow
        case .neutral: return .gray
        case .sad: return .blue
        case .anxious: return .orange
        case .excited: return .purple
        }
    }
}

struct JournalTheme {
    static let colors = Colors()
    
    struct Colors {
        let background = Color.black
        let cardBackground = Color(hex: "111111")
        let cardBorder = Color(hex: "222222")
        let text = Color.white
        let secondaryText = Color(hex: "999999")
        let accent = Color.yellow
        let divider = Color(hex: "222222")
        let lockIcon = Color(hex: "FF6B6B")
        let textEditorBackground = Color(hex: "111111")
        let placeholderText = Color(hex: "666666")
        let moodBackground = Color(hex: "111111")
        let moodSelectedBackground = Color(hex: "222222")
    }
}

// MARK: - Helper Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        JournalView()
    }
}
