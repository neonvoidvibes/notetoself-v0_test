import SwiftUI

/// A view representing a milestone, showing an icon within a circle and a label.
struct MilestoneView: View {
    let label: String
    let icon: String
    let isAchieved: Bool
    let achievedColor: Color // Color for text/icon when achieved
    let defaultColor: Color  // Color for text/icon when not achieved (or for dimmed elements)

    @ObservedObject private var styles = UIStyles.shared // Need styles for typography

    var body: some View {
        VStack(spacing: 8) { // Consistent spacing
            ZStack {
                // Border circle using defaultColor (dim)
                Circle()
                    .stroke(defaultColor.opacity(0.5), lineWidth: 2)
                    .frame(width: 60, height: 60)

                if isAchieved {
                    // Faint fill using defaultColor when achieved
                    Circle()
                        .fill(defaultColor.opacity(0.3))
                        .frame(width: 60, height: 60)

                    // Icon using achievedColor when achieved
                    Image(systemName: icon)
                        .foregroundColor(achievedColor)
                        .font(.system(size: 24))
                } else {
                    // Optional: show a different icon or placeholder if needed when not achieved
                     Image(systemName: "circle.dashed") // Example placeholder
                         .foregroundColor(defaultColor.opacity(0.5))
                         .font(.system(size: 24))
                }
            }
            // Text label using appropriate color based on achievement
            Text(label)
                .font(styles.typography.caption)
                .foregroundColor(isAchieved ? achievedColor : defaultColor)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        MilestoneView(
            label: "7 Days",
            icon: "star.fill",
            isAchieved: true,
            achievedColor: Color.yellow,
            defaultColor: Color.gray
        )
        MilestoneView(
            label: "30 Days",
            icon: "star.fill",
            isAchieved: false,
            achievedColor: Color.yellow,
            defaultColor: Color.gray
        )
    }
    .padding()
    .background(Color.black)
    .environmentObject(UIStyles.shared)
}