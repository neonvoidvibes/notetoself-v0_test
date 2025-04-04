import SwiftUI

struct InsightFullScreenView<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var styles = UIStyles.shared

    let title: String
    let content: Content // The specific detail content view

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Background matches the main app background
            styles.colors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Top Navigation Bar
                HStack {
                    // Dismiss Button (Downward Chevron) - Left Aligned
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .bold)) // Match size/weight of 'x'
                            .foregroundColor(styles.colors.accent)
                            .frame(width: 44, height: 44) // Ensure sufficient tap area
                    }
                    .padding(.leading, styles.layout.paddingL) // Adjust padding as needed

                    Spacer()

                    // Title (Centered)
                    Text(title)
                        .font(styles.typography.title1) // Bold Headline
                        .foregroundColor(styles.colors.text)

                    Spacer()

                    // Placeholder for potential right-side button (keep spacing balanced)
                    Rectangle()
                         .fill(Color.clear)
                         .frame(width: 44, height: 44)
                         .padding(.trailing, styles.layout.paddingL)

                }
                .padding(.top, styles.layout.topSafeAreaPadding) // Adjust top padding for safe area
                .padding(.bottom, styles.layout.paddingS) // Padding below nav bar
                .background(styles.colors.appBackground.opacity(0.8).blur(radius: 5)) // Optional subtle background

                // Content Area
                ScrollView {
                    VStack { // Wrap content in VStack for alignment if needed
                         content
                             .padding(.horizontal, styles.layout.paddingXL) // Ample horizontal padding
                             .padding(.vertical, styles.layout.paddingL) // Ample vertical padding
                    }
                     .frame(maxWidth: .infinity) // Ensure VStack takes full width
                }
                .padding(.bottom, 30) // Padding at the bottom of the scroll view
            }
        }
        // Note: The "pop" animation is typically handled by the presentation modifier (`.fullScreenCover`)
        // or a custom transition if needed later. This view defines the static layout.
    }
}

// Preview
#Preview {
    InsightFullScreenView(title: "Sample Insight") {
        VStack(alignment: .leading) {
            Text("Detail Content Header")
                .font(.title2)
            Text("This is where the specific detail content for the insight card would go. It should be scrollable and have ample spacing.")
                .padding(.top)
            ForEach(0..<15) { i in
                Text("Scrollable Content Item \(i)")
                    .padding(.vertical, 5)
            }
        }
    }
    .environmentObject(UIStyles.shared)
    .environmentObject(ThemeManager.shared)
}