import SwiftUI

struct WeeklySummaryInsightCard: View {
    // Input: Raw JSON string, generation date, and subscription status
    let jsonString: String?
    let generatedDate: Date?
    let isFresh: Bool
    let subscriptionTier: SubscriptionTier

    // Local state for decoded result
    @State private var decodedSummary: WeeklySummaryResult? = nil
    @State private var decodingError: Bool = false
    @State private var isHovering: Bool = false

    // Scroll behavior properties
    var scrollProxy: ScrollViewProxy? = nil
    var cardId: String? = nil

    @State private var isExpanded: Bool = false
    private let styles = UIStyles.shared

    // Computed properties based on the DECODED result
    private var summaryPeriod: String {
        let calendar = Calendar.current
        let endDate = generatedDate ?? Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
    }

    private var dominantMood: String? {
        guard let result = decodedSummary, !result.moodTrend.isEmpty, result.moodTrend != "N/A" else { return nil }
        let trendLower = result.moodTrend.lowercased()
        if let range = trendLower.range(of: "predominantly ") {
            return String(trendLower[range.upperBound...]).capitalized
        }
        return result.moodTrend.contains("positive") || result.moodTrend.contains("Improving") ? "Positive" :
               result.moodTrend.contains("negative") || result.moodTrend.contains("Declining") ? "Negative" :
               result.moodTrend == "Stable" ? "Stable" : nil
    }

    private func moodColor(forName moodName: String?) -> Color {
         guard let name = moodName else { return styles.colors.textSecondary }
         if let moodEnum = Mood.allCases.first(where: { $0.name.lowercased() == name.lowercased() }) {
             return moodEnum.color
         }
         switch name.lowercased() {
         case "positive", "improving": return styles.colors.moodHappy
         case "negative", "declining": return styles.colors.moodSad
         case "neutral", "stable", "mixed": return styles.colors.moodNeutral
         default: return styles.colors.textSecondary
         }
     }

    // Placeholder message logic remains similar, but based on jsonString presence
    private var placeholderMessage: String {
        if jsonString == nil {
            return "Keep journaling this week to generate your first summary!"
        } else if decodedSummary == nil && !decodingError {
             return "Loading summary..." // Indicates decoding is happening or pending
        } else if decodingError {
            return "Could not load summary. Please try again later."
        } else {
            // Should have decodedSummary if no error and jsonString exists
            return "Weekly summary is not available yet."
        }
    }

    var body: some View {
        styles.expandableCard(
            isExpanded: $isExpanded,
            isPrimary: isFresh && subscriptionTier == .premium, // Only highlight if premium and fresh
            scrollProxy: scrollProxy, // Pass proxy
            cardId: cardId,           // Pass ID
            content: {
                // Preview content
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Weekly Summary")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                            .shadow(color: isFresh && subscriptionTier == .premium ? styles.colors.accent.opacity(0.3) : .clear, radius: 1, x: 0, y: 0)
                        
                        if isFresh && subscriptionTier == .premium {
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [styles.colors.accent, styles.colors.accent.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: styles.colors.accent.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        
                        Spacer()
                        
                        if subscriptionTier == .free {
                            ZStack {
                                Circle()
                                    .fill(styles.colors.tertiaryBackground)
                                    .frame(width: 24, height: 24)
                                
                                Image(systemName: "lock.fill")
                                    .foregroundColor(styles.colors.textSecondary)
                                    .font(.system(size: 12))
                            }
                        }
                    }

                    // Conditional display
                    if subscriptionTier == .premium {
                        Text(summaryPeriod)
                            .font(styles.typography.insightCaption)
                            .foregroundColor(styles.colors.accent.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Use decodedSummary for display
                        if let result = decodedSummary {
                            Text(result.mainSummary)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .fixedSize(horizontal: false, vertical: true)

                            if !result.keyThemes.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(result.keyThemes.prefix(3), id: \.self) { theme in
                                            Text(theme)
                                                .font(styles.typography.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(
                                                    RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                                        .fill(styles.colors.tertiaryBackground)
                                                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                                        .strokeBorder(styles.colors.accent.opacity(0.2), lineWidth: 1)
                                                )
                                                .foregroundColor(styles.colors.text)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } else {
                            // Premium user, but no decoded data yet or error
                            VStack(spacing: 12) {
                                Text(placeholderMessage)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                                    .multilineTextAlignment(.center)
                                
                                // Optionally show ProgressView if jsonString exists but decoded is nil
                                if jsonString != nil && decodedSummary == nil && !decodingError {
                                    ProgressView()
                                        .tint(styles.colors.accent)
                                        .scaleEffect(1.2)
                                }
                            }
                        }
                    } else {
                        // Free tier locked state with enhanced styling
                        VStack(spacing: 16) {
                            Text("Unlock weekly summaries and deeper insights with Premium.")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                                .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                // Upgrade action would go here
                            }) {
                                Text("Upgrade to Premium")
                                    .font(styles.typography.bodySmall.weight(.medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [styles.colors.accent, styles.colors.accent.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: styles.colors.accent.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                            .scaleEffect(isHovering ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
                            .onHover { hovering in
                                isHovering = hovering
                            }
                        }
                    }
                }
            },
            detailContent: {
                // Expanded detail content (Only show if premium and data exists)
                if subscriptionTier == .premium, let result = decodedSummary {
                    VStack(spacing: styles.layout.spacingL) {
                        // Summary section with enhanced styling
                        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                            HStack {
                                Text("Summary")
                                    .font(styles.typography.title3)
                                    .foregroundColor(styles.colors.text)
                                
                                Spacer()
                                
                                Text(summaryPeriod)
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.accent.opacity(0.8))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(styles.colors.tertiaryBackground.opacity(0.5))
                                    )
                            }
                            
                            Text(result.mainSummary)
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                        .fill(styles.colors.secondaryBackground.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                        .strokeBorder(styles.colors.tertiaryBackground, lineWidth: 1)
                                )
                        }

                        // Key Themes section with enhanced styling
                        if !result.keyThemes.isEmpty {
                            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                Text("Key Themes")
                                    .font(styles.typography.title3)
                                    .foregroundColor(styles.colors.text)
                                
                                FlowLayout(spacing: 10) {
                                    ForEach(result.keyThemes, id: \.self) { theme in
                                        Text(theme)
                                            .font(styles.typography.bodySmall)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                                    .fill(styles.colors.secondaryBackground)
                                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                                    .strokeBorder(styles.colors.accent.opacity(0.2), lineWidth: 1)
                                            )
                                            .foregroundColor(styles.colors.text)
                                    }
                                }
                            }
                        }

                        // Mood Trend section with enhanced styling
                        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                            Text("Mood Trend")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)
                            
                            HStack(spacing: 12) {
                                let color = moodColor(forName: dominantMood)
                                
                                ZStack {
                                    Circle()
                                        .fill(color.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    
                                    Circle()
                                        .fill(color)
                                        .frame(width: 16, height: 16)
                                }
                                
                                Text(result.moodTrend)
                                    .font(styles.typography.bodyFont)
                                    .foregroundColor(styles.colors.textSecondary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                    .fill(styles.colors.secondaryBackground.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                    .strokeBorder(styles.colors.tertiaryBackground, lineWidth: 1)
                            )
                        }

                        // Notable Quote section with enhanced styling
                        if !result.notableQuote.isEmpty {
                            VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                                Text("Notable Quote")
                                    .font(styles.typography.title3)
                                    .foregroundColor(styles.colors.text)
                                
                                Text("\"\(result.notableQuote)\"")
                                    .font(styles.typography.bodyFont.italic())
                                    .foregroundColor(styles.colors.accent)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                            .fill(styles.colors.secondaryBackground.opacity(0.5))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: styles.layout.radiusM)
                                            .strokeBorder(styles.colors.tertiaryBackground, lineWidth: 1)
                                    )
                            }
                        }

                        // Generation timestamp with enhanced styling
                        if let date = generatedDate {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                                    .font(.system(size: 12))
                                
                                Text("Generated on \(date.formatted(date: .long, time: .shortened))")
                                    .font(styles.typography.caption)
                                    .foregroundColor(styles.colors.textSecondary.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top)
                        }
                    }
                } else if subscriptionTier == .free {
                    // Free tier expanded state with enhanced styling
                    VStack(spacing: styles.layout.spacingL) {
                        // Lock icon with glow effect
                        ZStack {
                            Circle()
                                .fill(styles.colors.accent.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .fill(styles.colors.accent.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "lock.fill")
                                .font(.system(size: 30))
                                .foregroundColor(styles.colors.accent)
                                .shadow(color: styles.colors.accent.opacity(0.5), radius: 5, x: 0, y: 0)
                        }
                        
                        Text("Upgrade for Details")
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                            .shadow(color: styles.colors.accent.opacity(0.3), radius: 1, x: 0, y: 0)
                        
                        Text("Unlock detailed weekly summaries and insights with Premium.")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        // Premium upgrade button with hover effect
                        Button(action: {
                            // Upgrade action would go here
                        }) {
                            Text("Upgrade to Premium")
                                .font(styles.typography.bodyFont.weight(.medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [styles.colors.accent, styles.colors.accent.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: styles.colors.accent.opacity(0.3), radius: 3, x: 0, y: 2)
                        }
                        .scaleEffect(isHovering ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
                        .onHover { hovering in
                            isHovering = hovering
                        }
                    }
                    .padding(.vertical, 20)
                } else {
                    // Premium, but no data with enhanced styling
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 40))
                            .foregroundColor(styles.colors.accent.opacity(0.7))
                            .shadow(color: styles.colors.accent.opacity(0.3), radius: 3, x: 0, y: 0)
                        
                        Text("Weekly summary details are not available yet.")
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Keep journaling to generate your first weekly summary!")
                            .font(styles.typography.bodySmall)
                            .foregroundColor(styles.colors.accent.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                }
            }
        )
        .onChange(of: jsonString) { oldValue, newValue in
            decodeJSON(json: newValue)
        }
        .onAppear {
            decodeJSON(json: jsonString)
        }
    }

    // Decoding function
    private func decodeJSON(json: String?) {
        guard let json = json, !json.isEmpty else {
            if decodedSummary != nil { decodedSummary = nil }
            decodingError = false
            return
        }

        decodingError = false

        guard let data = json.data(using: .utf8) else {
            print("⚠️ [WeeklySummaryCard] Failed to convert JSON string to Data.")
            if decodedSummary != nil { decodedSummary = nil }
            decodingError = true
            return
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(WeeklySummaryResult.self, from: data)
            if result != decodedSummary {
                decodedSummary = result
                print("[WeeklySummaryCard] Successfully decoded new summary.")
            }
        } catch {
            print("‼️ [WeeklySummaryCard] Failed to decode WeeklySummaryResult: \(error). JSON: \(json)")
            if decodedSummary != nil { decodedSummary = nil }
            decodingError = true
        }
    }
}

