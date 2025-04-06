import SwiftUI

/// A view representing a milestone, showing an icon within a circle and a label.
struct MilestoneView: View {
    let label: String
    let icon: String
    let isAchieved: Bool
    let accentColor: Color       // Color for icon/text when achieved
    let defaultStrokeColor: Color // Color for stroke/dimmed text when not achieved

    @ObservedObject private var styles = UIStyles.shared // Need styles for typography

    var body: some View {
        VStack(spacing: 8) { // Consistent spacing
            ZStack {
                // Border circle using defaultStrokeColor (dim)
                Circle()
                    .stroke(defaultStrokeColor.opacity(0.5), lineWidth: 2)
                    .frame(width: 60, height: 60)

                if isAchieved {
                    // Faint fill using accentColor when achieved
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    // Icon using accentColor when achieved
                    Image(systemName: icon)
                        .foregroundColor(accentColor)
                        .font(.system(size: 24))
                } else {
                    // Dimmed placeholder icon using defaultStrokeColor
                     Image(systemName: "circle.dashed") // Example placeholder
                         .foregroundColor(defaultStrokeColor.opacity(0.5))
                         .font(.system(size: 24))
                }
            }
            // Text label using appropriate color based on achievement
            Text(label)
                .font(styles.typography.caption)
                .foregroundColor(isAchieved ? accentColor : defaultStrokeColor)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        MilestoneView(
            label: "7 Days",
            icon: "star.fill",
            isAchieved: true,
            accentColor: Color.yellow, // Example accent
            defaultStrokeColor: Color.gray // Example default
        )
        MilestoneView(
            label: "30 Days",
            icon: "star.fill",
            isAchieved: false,
            accentColor: Color.yellow,
            defaultStrokeColor: Color.gray
        )
    }
    .padding()
    .background(Color.black)
    .environmentObject(UIStyles.shared)
}