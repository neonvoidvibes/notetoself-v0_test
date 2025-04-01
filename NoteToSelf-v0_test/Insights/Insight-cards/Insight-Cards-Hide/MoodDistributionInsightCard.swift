import SwiftUI

struct MoodDistributionInsightCard: View {
    let entries: [JournalEntry]
    @State private var isExpanded: Bool = false

    // Access to shared styles
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    private var moodCounts: [Mood: Int] {
        entries.reduce(into:[Mood: Int]()) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
    }

    private var topMoods: [(mood: Mood, count: Int)] {
        moodCounts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Mood Distribution")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)

                        Spacer()
                    }

                    // Top moods
                    HStack(spacing: styles.layout.spacingL) {
                        ForEach(topMoods, id: \.mood) { moodData in
                            VStack(spacing: 8) {
                                Image(systemName: moodData.mood.systemIconName)
                                    .foregroundColor(moodData.mood.color)
                                    .font(.system(size: 24))

                                Text(moodData.mood.name)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.text)

                                Text("\(moodData.count)")
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        // Add placeholders if fewer than 3 top moods
                         ForEach(0..<(3 - topMoods.count), id: \.self) { _ in
                             VStack(spacing: 8) {
                                 Image(systemName: "circle.dashed")
                                     .foregroundColor(styles.colors.textSecondary)
                                     .font(.system(size: 24))
                                 Text("N/A")
                                     .font(styles.typography.bodyFont)
                                     .foregroundColor(styles.colors.textSecondary)
                                 Text(" ") // Placeholder for count
                                     .font(styles.typography.caption)
                                     .foregroundColor(styles.colors.textSecondary)
                             }
                             .frame(maxWidth: .infinity)
                         }
                    }

                    // More conversational insight text
                    Text(generateDistributionInsight())
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, styles.layout.spacingS)
                        .lineLimit(2)
                }
            },
            detailContent: {
                // Expanded detail content
                VStack(spacing: styles.layout.spacingL) {
                    // Mood distribution chart
                    // MoodDistributionChart observes styles internally now
                    MoodDistributionChart(moodCounts: moodCounts, totalEntries: entries.count)
                        .padding(.vertical, styles.layout.paddingL)

                    // Mood breakdown
                    // MoodBreakdownList observes styles internally now
                    MoodBreakdownList(moodCounts: moodCounts, totalEntries: entries.count)
                        .padding(.vertical, styles.layout.paddingL)
                }
            }
        )
    }

    // Helper methods for expanded content
    private func moodDistributionForPie() -> [(mood: Mood, startAngle: Angle, endAngle: Angle)] {
        let totalEntries = entries.count
        guard totalEntries > 0 else { return [] }

        var result: [(mood: Mood, startAngle: Angle, endAngle: Angle)] = []
        var currentAngle: Double = -90 // Start from top

        for (mood, count) in moodCounts.sorted(by: { $0.value > $1.value }) {
            let percentage = Double(count) / Double(totalEntries)
            let degreesForMood = percentage * 360

            let startAngle = Angle(degrees: currentAngle)
            let endAngle = Angle(degrees: currentAngle + degreesForMood)

            result.append((mood: mood, startAngle: startAngle, endAngle: endAngle))

            currentAngle += degreesForMood
        }

        return result
    }

    private func moodDistributionForLegend() -> [(mood: Mood, percentage: Int)] {
        let totalEntries = entries.count
        guard totalEntries > 0 else { return [] }

        return moodCounts.map { mood, count in
            let percentage = Int(Double(count) / Double(totalEntries) * 100)
            return (mood: mood, percentage: percentage)
        }.sorted { $0.percentage > $1.percentage }
    }

    private func generateDetailedAnalysis() -> String {
        if entries.isEmpty {
            return "Start journaling to track your emotional patterns over time. Regular entries will help reveal your mood distribution and emotional tendencies."
        }

        let totalEntries = entries.count
        let sortedMoods = moodCounts.sorted { $0.value > $1.value }

        var analysis = ""

        // Analyze dominant mood
        if let topMood = sortedMoods.first {
            let percentage = Int(Double(topMood.value) / Double(totalEntries) * 100)

            analysis += "Your most frequent mood is \(topMood.key.name.lowercased()), appearing in \(percentage)% of your entries. "

            switch topMood.key {
            case .happy, .excited, .content, .relaxed, .calm:
                analysis += "This suggests you generally experience positive emotions, which is associated with resilience and well-being. "
            case .sad, .depressed:
                analysis += "This suggests you've been experiencing some challenging emotions lately. Remember that emotions are temporary and seeking support can be helpful. "
            case .anxious, .stressed:
                analysis += "This suggests you may be experiencing some ongoing stressors. Consider what might be contributing to these feelings and what coping strategies might help. "
            default:
                analysis += "Understanding your emotional patterns can help you respond more intentionally to different situations. "
            }
        }

        // Analyze emotional range
        if moodCounts.count >= 3 {
            analysis += "Your emotional landscape shows variety, with \(moodCounts.count) different moods recorded. This emotional range is normal and healthy, reflecting your responsiveness to different life experiences. "
        } else if moodCounts.count == 2 {
            analysis += "Your entries show a somewhat narrow emotional range, with just two moods recorded. Consider whether you might be overlooking more subtle emotional states. "
        } else if moodCounts.count == 1 {
            analysis += "Your entries show only one mood. Consider whether you might be simplifying your emotional experience or overlooking more nuanced feelings. "
        }

        // Add general insight
        analysis += "Tracking your moods over time helps build emotional awareness, which is a key component of emotional intelligence and well-being."

        return analysis
    }

    // Generate distribution insight for preview
    private func generateDistributionInsight() -> String {
        if topMoods.isEmpty {
            return "Start journaling to track your emotional patterns over time."
        }

        if let topMood = topMoods.first {
            let percentage = Float(topMood.count) / Float(entries.count) * 100
            let formattedPercentage = Int(percentage)

            switch topMood.mood {
            case .happy, .excited, .content, .relaxed, .calm:
                return "You feel \(topMood.mood.name.lowercased()) about \(formattedPercentage)% of the time. This positive outlook can help build resilience."
            case .sad, .depressed:
                return "You've recorded feeling \(topMood.mood.name.lowercased()) frequently. Consider what patterns might be contributing to this."
            case .anxious, .stressed:
                return "Stress appears in \(formattedPercentage)% of your entries. Identifying triggers can help manage these feelings."
            default:
                return "Your most common mood is \(topMood.mood.name.lowercased()). Understanding your patterns helps build emotional awareness."
            }
        } else {
            // This case should technically not be reached if topMoods is not empty, but added for safety.
            return "Your emotional landscape is diverse. This awareness helps you understand yourself better."
        }
    }
}

// REMOVED duplicate definitions of MoodDistributionChart and MoodBreakdownList.
// They are correctly defined in MoodDistributionDetailContent.swift.