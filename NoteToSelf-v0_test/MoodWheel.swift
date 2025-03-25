import SwiftUI

struct MoodWheel: View {
    @Binding var selectedMood: Mood
    @State private var showMoodDescription: Bool = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    // Constants for wheel dimensions
    private let wheelDiameter: CGFloat = 280
    private let centerDiameter: CGFloat = 60
    private let axisThickness: CGFloat = 1.5
    
    var body: some View {
        VStack(spacing: styles.layout.spacingM) {
            // Title and instructions
            VStack(spacing: styles.layout.spacingS) {
                Text("How are you feeling?")
                    .font(styles.typography.title3)
                    .foregroundColor(styles.colors.text)
                
                Text("Tap on the wheel to select your dominant mood")
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Mood wheel
            ZStack {
                // Background circle with gradient
                CircleMoodBackground()
                
                // Coordinate axes
                VStack {
                    Text("Arousal (+)")
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.text.opacity(0.7))
                        .offset(y: -wheelDiameter/2 - 20)
                    
                    Spacer()
                    
                    Text("Arousal (-)")
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.text.opacity(0.7))
                        .offset(y: wheelDiameter/2 + 20)
                }
                
                HStack {
                    Text("Valence (-)")
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.text.opacity(0.7))
                        .offset(x: -wheelDiameter/2 - 20)
                    
                    Spacer()
                    
                    Text("Valence (+)")
                        .font(styles.typography.caption)
                        .foregroundColor(styles.colors.text.opacity(0.7))
                        .offset(x: wheelDiameter/2 + 20)
                }
                
                // Horizontal axis
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: wheelDiameter, height: axisThickness)
                
                // Vertical axis
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: axisThickness, height: wheelDiameter)
                
                // Mood labels
                ForEach(Mood.allCases.filter { $0 != .neutral }, id: \.self) { mood in
                    MoodLabel(mood: mood, wheelRadius: wheelDiameter/2, centerRadius: centerDiameter/2)
                }
                
                // Center neutral circle
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: centerDiameter, height: centerDiameter)
                    .overlay(
                        Circle()
                            .stroke(selectedMood == .neutral ? styles.colors.accent : Color.white.opacity(0.7), lineWidth: 2)
                    )
                    .overlay(
                        Text("Neutral")
                            .font(styles.typography.caption)
                            .foregroundColor(Color.white)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMood = .neutral
                        }
                    }
                
                // Selection indicator
                if selectedMood != .neutral {
                    MoodSelectionIndicator(mood: selectedMood, wheelRadius: wheelDiameter/2, centerRadius: centerDiameter/2)
                }
                
                // Tap gesture area
                Circle()
                    .fill(Color.clear)
                    .frame(width: wheelDiameter, height: wheelDiameter)
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleTap(at: value.location)
                            }
                    )
            }
            .frame(width: wheelDiameter, height: wheelDiameter)
            .padding(.vertical, styles.layout.paddingL)
            
            // Selected mood display
            VStack(spacing: styles.layout.spacingS) {
                Text("Selected Mood: \(selectedMood.name)")
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.text)
                
                // Mood color indicator
                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                    .fill(selectedMood.color)
                    .frame(width: 60, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: styles.layout.radiusM)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.top, styles.layout.paddingM)
        }
        .padding(styles.layout.paddingL)
    }
    
    private func handleTap(at location: CGPoint) {
        // Convert tap location to coordinates relative to center
        let center = CGPoint(x: wheelDiameter/2, y: wheelDiameter/2)
        let relativeX = location.x - center.x
        let relativeY = center.y - location.y // Invert Y to match coordinate system
        
        // Calculate distance from center
        let distance = sqrt(relativeX * relativeX + relativeY * relativeY)
        
        // Ignore taps in the center neutral area
        if distance < centerDiameter/2 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedMood = .neutral
            }
            return
        }
        
        // Ignore taps outside the wheel
        if distance > wheelDiameter/2 {
            return
        }
        
        // Calculate valence and arousal on a -3 to 3 scale
        let maxCoordinate: CGFloat = wheelDiameter/2 - centerDiameter/2
        let valenceRaw = relativeX / maxCoordinate * 3
        let arousalRaw = relativeY / maxCoordinate * 3
        
        // Round to nearest integer for step intervals
        let valence = Int(round(valenceRaw))
        let arousal = Int(round(arousalRaw))
        
        // Clamp values to -3 to 3 range
        let clampedValence = max(-3, min(3, valence))
        let clampedArousal = max(-3, min(3, arousal))
        
        // Set the mood based on coordinates
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedMood = Mood.fromCoordinates(valence: clampedValence, arousal: clampedArousal)
        }
    }
}

// Background gradient circle for the mood wheel
struct CircleMoodBackground: View {
    var body: some View {
        ZStack {
            // Rotated 90 degrees so Alert/Excited/Happy are on yellow
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#CCFF00"), // Alert (yellow-green)
                            Color(hex: "#99FF33"), // Excited
                            Color(hex: "#66FF66"), // Happy
                            Color(hex: "#33FFCC"), // Content
                            Color(hex: "#33CCFF"), // Relaxed
                            Color(hex: "#3399FF"), // Calm
                            Color(hex: "#6666FF"), // Bored
                            Color(hex: "#9933FF"), // Depressed
                            Color(hex: "#CC33FF"), // Sad
                            Color(hex: "#FF3399"), // Distressed
                            Color(hex: "#FF3333"), // Angry
                            Color(hex: "#FF9900"), // Tense
                            Color(hex: "#CCFF00")  // Back to Alert
                        ]),
                        center: .center,
                        startAngle: .degrees(90),
                        endAngle: .degrees(450)
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// Individual mood label positioned on the wheel
struct MoodLabel: View {
    let mood: Mood
    let wheelRadius: CGFloat
    let centerRadius: CGFloat
    
    private let styles = UIStyles.shared
    
    var body: some View {
        let valence = CGFloat(mood.valence)
        let arousal = CGFloat(mood.arousal)
        
        // Skip neutral which is in the center
        if valence == 0 && arousal == 0 {
            return EmptyView().eraseToAnyView()
        }
        
        // Calculate position
        let maxCoordinate: CGFloat = 3.0
        let radius = wheelRadius - centerRadius
        let distance = sqrt(valence * valence + arousal * arousal) / maxCoordinate
        let angle = atan2(arousal, valence)
        
        let x = cos(angle) * radius * distance
        let y = sin(angle) * radius * distance
        
        return Text(mood.name)
            .font(styles.typography.caption)
            .foregroundColor(Color.white)
            .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
            .offset(x: x, y: -y) // Negate y to match SwiftUI coordinate system
            .eraseToAnyView()
    }
}

// Selection indicator that shows the currently selected mood
struct MoodSelectionIndicator: View {
    let mood: Mood
    let wheelRadius: CGFloat
    let centerRadius: CGFloat
    
    private let styles = UIStyles.shared
    
    var body: some View {
        let valence = CGFloat(mood.valence)
        let arousal = CGFloat(mood.arousal)
        
        // Skip neutral which is in the center
        if valence == 0 && arousal == 0 {
            return EmptyView().eraseToAnyView()
        }
        
        // Calculate position
        let maxCoordinate: CGFloat = 3.0
        let radius = wheelRadius - centerRadius
        let distance = sqrt(valence * valence + arousal * arousal) / maxCoordinate
        let angle = atan2(arousal, valence)
        
        let x = cos(angle) * radius * distance
        let y = sin(angle) * radius * distance
        
        return Circle()
            .fill(styles.colors.accent)
            .frame(width: 24, height: 24)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
            .offset(x: x, y: -y) // Negate y to match SwiftUI coordinate system
            .eraseToAnyView()
    }
}

// Helper extension to erase view type
extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

struct MoodWheel_Previews: PreviewProvider {
    static var previews: some View {
        MoodWheel(selectedMood: .constant(.happy))
            .preferredColorScheme(.dark)
            .background(Color.black)
    }
}

