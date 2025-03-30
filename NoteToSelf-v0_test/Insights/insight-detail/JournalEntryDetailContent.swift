import SwiftUI

struct JournalEntryDetailContent: View {
    let entry: JournalEntry
    private let styles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingL) {
            // Entry header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(entry.date))
                        .font(styles.typography.bodyFont)
                        .foregroundColor(styles.colors.textSecondary)

                    HStack {
                        entry.mood.icon
                            .foregroundColor(entry.mood.color)

                        Text(formattedMoodText(entry.mood, intensity: entry.intensity))
                            .font(styles.typography.bodyFont)
                            .foregroundColor(entry.mood.color)
                    }
                }

                Spacer()

                if entry.isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(styles.colors.textSecondary)
                }
            }

            // Entry text
            Text(entry.text)
                .font(styles.typography.bodyLarge)
                .foregroundColor(styles.colors.text)
                .lineSpacing(8)

            // Entry stats
            HStack(spacing: styles.layout.spacingXL) {
                StatItem(
                    value: "\(entry.text.split(separator: " ").count)",
                    label: "Words",
                    icon: "text.word.spacing"
                )

                StatItem(
                    value: "\(entry.text.count)",
                    label: "Characters",
                    icon: "character"
                )
            }
            .padding(.top, styles.layout.paddingL)
        }
    }

    private func formatDate(_ date: Date) -> String {
         // Corrected: Use .shortened instead of .short
         return date.formatted(date: .long, time: .shortened)
     }


    private func formattedMoodText(_ mood: Mood, intensity: Int = 2) -> String {
        switch intensity {
        case 1: return "Slightly \(mood.name)"
        case 3: return "Very \(mood.name)"
        default: return mood.name
        }
    }
}