import SwiftUI

struct StreakNarrativeDetailContent: View {
    let streak: Int
    let entries: [JournalEntry] // Keep entries for timeline
    let narrativeResult: StreakNarrativeResult? // Accept optional result
    let generatedDate: Date? // Accept date
     // Ensure styles are observed if passed down or used globally
     @ObservedObject private var styles = UIStyles.shared

    // Use narrative text from the result, or a placeholder
    private var narrativeDisplayText: String {
        narrativeResult?.narrativeText ?? "Your detailed storyline will appear here once enough data is analyzed."
    }

    var body: some View {
         ScrollView {
             VStack(alignment: .leading, spacing: styles.layout.spacingXL) { // Main spacing between sections

                 // --- Narrative Text Section ---
                 VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     Text("Narrative") // Section Title
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)

                     Text(narrativeDisplayText) // Content
                         .font(styles.typography.bodyFont)
                         .foregroundColor(styles.colors.textSecondary)
                         .frame(maxWidth: .infinity, alignment: .leading) // Ensure text takes width
                 }
                 .padding() // Apply styling to the section VStack
                 .background(styles.colors.secondaryBackground.opacity(0.5))
                 .cornerRadius(styles.layout.radiusM)


                 // --- Timeline Highlights Section ---
                 VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     Text("Timeline Highlights")
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)

                     // Timeline Visualization (Horizontal Scroll)
                     ScrollViewReader { proxy in // Add ScrollViewReader
                         ScrollView(.horizontal, showsIndicators: false) {
                             HStack(alignment: .bottom, spacing: styles.layout.spacingS) {
                                 let timelineEntries = entries.sorted(by: { $0.date > $1.date }).prefix(10).reversed().map { $0 }
                                 ForEach(timelineEntries, id: \.id) { entry in
                                     TimelineItemView(entry: entry)
                                         .id(entry.id) // Assign ID for scrolling
                                 }
                             }
                             .padding(.vertical)
                              // Add horizontal padding so last item isn't at edge
                              .padding(.horizontal, styles.layout.paddingL)
                         }
                         .onAppear {
                              // Scroll to the last item on appear
                              if let lastId = entries.sorted(by: { $0.date > $1.date }).first?.id { // Get ID of most recent entry
                                  print("[StreakNarrativeDetail] Scrolling timeline to end: \(lastId)")
                                  proxy.scrollTo(lastId, anchor: .trailing)
                              }
                          }
                     } // End ScrollViewReader
                     .frame(height: 100) // Fixed height for the timeline scroll
                 }
                 // No background needed for the timeline section itself, just title

                 // --- Streak Milestones Section ---
                 VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                     Text("Streak Milestones")
                         .font(styles.typography.title3)
                         .foregroundColor(styles.colors.text)

                     HStack(spacing: styles.layout.spacingL) {
                         StreakMilestone(days: 7, current: streak, icon: "star.fill")
                         StreakMilestone(days: 30, current: streak, icon: "star.fill")
                         StreakMilestone(days: 100, current: streak, icon: "star.fill")
                     }
                     .frame(maxWidth: .infinity, alignment: .center) // Center milestones
                     .padding(.top, styles.layout.spacingS) // Add padding above milestones
                 }
                 .padding() // Apply styling to the section VStack
                 .background(styles.colors.secondaryBackground.opacity(0.5))
                 .cornerRadius(styles.layout.radiusM)


                  Spacer(minLength: styles.layout.spacingXL) // Add spacer before timestamp

                  // Generated Date Timestamp (Outside styled sections)
                  if let date = generatedDate {
                      HStack {
                          Spacer() // Center align
                          Image(systemName: "clock")
                              .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                              .font(.system(size: 12))
                          Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                              .font(styles.typography.caption)
                              .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                          Spacer()
                      }
                      .padding(.top) // Padding above timestamp
                  }
             } // End Main VStack
             .padding(.bottom, styles.layout.paddingL) // Bottom padding inside scrollview
        } // End ScrollView
    } // End body
} // End struct

// Subview for individual timeline items (Keep as is)
struct TimelineItemView: View {
    let entry: JournalEntry
    @ObservedObject private var styles = UIStyles.shared

    private var markerType: String {
        switch entry.mood {
        case .happy, .excited, .content: return "sparkle"
        case .sad, .depressed, .angry: return "exclamationmark.triangle.fill"
        case .anxious, .stressed: return "bolt.fill"
        default: return "circle.fill"
        }
    }
    private var markerColor: Color { entry.mood.color }
    private var dateString: String {
        let formatter = DateFormatter(); formatter.dateFormat = "MMM d"; return formatter.string(from: entry.date)
    }
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: markerType).font(.system(size: 16)).foregroundColor(markerColor).frame(height: 20)
            Rectangle().fill(styles.colors.divider).frame(width: 1, height: 30)
            Text(dateString).font(.caption).foregroundColor(styles.colors.textSecondary)
        }.frame(width: 50)
    }
}

// Re-include StreakMilestone (Keep as is)
struct StreakMilestone: View {
    let days: Int
    let current: Int
    let icon: String
    @ObservedObject private var styles = UIStyles.shared
    var body: some View {
        VStack {
            ZStack {
                Circle().stroke(styles.colors.accent.opacity(0.3), lineWidth: 2).frame(width: 60, height: 60)
                if current >= days {
                    Circle().fill(styles.colors.accent.opacity(0.2)).frame(width: 60, height: 60)
                    Image(systemName: icon).foregroundColor(styles.colors.accent).font(.system(size: 24))
                }
            }
            Text("\(days) days").font(styles.typography.caption).foregroundColor(current >= days ? styles.colors.accent : styles.colors.textSecondary)
        }
    }
}

#Preview {
    let mockEntries = [
        JournalEntry(text: "Entry 1", mood: .happy, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        JournalEntry(text: "Entry 2", mood: .stressed, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        JournalEntry(text: "Entry 3", mood: .content, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
    ]
    let mockResult = StreakNarrativeResult(storySnippet: "Snippet preview", narrativeText: "Longer narrative preview text goes here about feeling happy and stressed but also content.")
    // Wrap in InsightFullScreenView for accurate preview of padding/layout
    return InsightFullScreenView(title: "Your Journey") {
        StreakNarrativeDetailContent(
            streak: 5,
            entries: mockEntries,
            narrativeResult: mockResult,
            generatedDate: Date()
        )
    }
    .environmentObject(AppState()) // Provide mock AppState
    .environmentObject(DatabaseService()) // Add missing DB service
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
}