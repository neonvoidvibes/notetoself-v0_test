import SwiftUI

struct FullscreenEntryView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background
            styles.colors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom navigation bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: styles.layout.spacingS) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(styles.colors.accent)
                    }
                    
                    Spacer()
                    
                    // Date display
                    Text(formatDate(entry.date))
                        .font(styles.typography.smallLabelFont)
                        .foregroundColor(styles.colors.textSecondary)
                }
                .padding(.horizontal, styles.layout.paddingXL)
                .padding(.top, styles.layout.topSafeAreaPadding)
                .padding(.bottom, styles.layout.paddingM)
                
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: styles.layout.spacingXL) {
                        // Mood indicator
                        HStack(spacing: styles.layout.spacingM) {
                            entry.mood.icon
                                .font(.system(size: 32))
                                .foregroundColor(entry.mood.color)
                            
                            Text(entry.mood.name)
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)
                            
                            Spacer()
                            
                            if entry.isLocked {
                                HStack(spacing: styles.layout.spacingS) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14))
                                    Text("Locked")
                                }
                                .font(styles.typography.caption)
                                .foregroundColor(styles.colors.textSecondary)
                            }
                        }
                        .padding(.horizontal, styles.layout.paddingXL)
                        .padding(.top, styles.layout.paddingL)
                        
                        // Entry text
                        Text(entry.text)
                            .font(styles.typography.bodyLarge)
                            .foregroundColor(styles.colors.text)
                            .lineSpacing(8)
                            .padding(.horizontal, styles.layout.paddingXL)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FullscreenEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntry = JournalEntry(
            text: "This is a sample journal entry with some text to preview how it would look in the fullscreen view. The text should be displayed prominently and be easy to read.",
            mood: .happy,
            date: Date()
        )
        
        FullscreenEntryView(entry: sampleEntry)
    }
}

