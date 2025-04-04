import SwiftUI

struct StreakNarrativeDetailContent: View {
    let streak: Int
    let entries: [JournalEntry] // Keep entries for timeline
    let narrativeResult: StreakNarrativeResult? // Accept optional result

     // Ensure styles are observed if passed down or used globally
     @ObservedObject private var styles = UIStyles.shared

    // Use narrative text from the result, or a placeholder
    private var narrativeDisplayText: String {
        narrativeResult?.narrativeText ?? "Your detailed storyline will appear here once enough data is analyzed."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingL) {
            Text("Your Journey's Storyline")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)

            // Narrative Text (From Result)
            Text(narrativeDisplayText) // Use computed property
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.textSecondary)
                .padding(.bottom)

            Text("Timeline Highlights")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)

            // Timeline Visualization (Horizontal Scroll)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: styles.layout.spacingS) {
                    // Generate timeline items from entries
                    // For simplicity, show last 7-10 entries or key markers
                    ForEach(entries.sorted(by: { $0.date > $1.date }).prefix(10).reversed(), id: \.id) { entry in
                        TimelineItemView(entry: entry)
                    }
                }
                .padding(.vertical)
            }
            .frame(height: 100) // Fixed height for the timeline scroll

            // Optional: Add Streak Milestones or Benefits section if needed
            // StreakMilestone section (copied from old StreakDetailContent)
            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                Text("Streak Milestones")
                    .font(styles.typography.title3)
                    .foregroundColor(styles.colors.text)

                HStack(spacing: styles.layout.spacingL) {
                    StreakMilestone(days: 7, current: streak, icon: "star.fill")
                    StreakMilestone(days: 30, current: streak, icon: "star.fill")
                    StreakMilestone(days: 100, current: streak, icon: "star.fill")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top)
        }
    }
}

// Subview for individual timeline items
struct TimelineItemView: View {
    let entry: JournalEntry
    @ObservedObject private var styles = UIStyles.shared

    // Simple marker based on mood
    private var markerType: String {
        switch entry.mood {
        case .happy, .excited, .content: return "sparkle" // Positive
        case .sad, .depressed, .angry: return "exclamationmark.triangle.fill" // Negative/Challenging
        case .anxious, .stressed: return "bolt.fill" // High energy/stress
        default: return "circle.fill" // Neutral/Other
        }
    }

    private var markerColor: Color {
        entry.mood.color
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Marker
            Image(systemName: markerType)
                .font(.system(size: 16))
                .foregroundColor(markerColor)
                .frame(height: 20)

            // Line connecting markers (optional, might need complex geometry)
            Rectangle()
                .fill(styles.colors.divider)
                .frame(width: 1, height: 30)

            // Date
            Text(dateString)
                .font(.caption)
                .foregroundColor(styles.colors.textSecondary)
        }
        .frame(width: 50) // Fixed width for each item
    }
}

// Re-include StreakMilestone from old StreakDetailContent for preview/use
struct StreakMilestone: View {
    let days: Int
    let current: Int
    let icon: String
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(styles.colors.accent.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)

                if current >= days {
                    Circle()
                        .fill(styles.colors.accent.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .foregroundColor(styles.colors.accent)
                        .font(.system(size: 24))
                }
            }

            Text("\(days) days")
                .font(styles.typography.caption)
                .foregroundColor(current >= days ? styles.colors.accent : styles.colors.textSecondary)
        }
    }
}

#Preview {
    // Create mock entries for preview
    let mockEntries = [
        JournalEntry(text: "Entry 1", mood: .happy, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        JournalEntry(text: "Entry 2", mood: .stressed, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        JournalEntry(text: "Entry 3", mood: .content, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
    ]
    let mockResult = StreakNarrativeResult(storySnippet: "Snippet preview", narrativeText: "Longer narrative preview text goes here.")
    ScrollView {
        StreakNarrativeDetailContent(streak: 5, entries: mockEntries, narrativeResult: mockResult)
            .padding()
    }
    .environmentObject(AppState()) // Provide mock AppState
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
}