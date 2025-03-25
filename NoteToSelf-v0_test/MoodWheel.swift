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
                
                // Mood labels - including neutral
                ForEach(Mood.allCases, id: \.self) { mood in
                    MoodLabel(
                        mood: mood,
                        wheelRadius: wheelDiameter/2,
                        centerRadius: centerDiameter/2,
                        isSelected: selectedMood == mood
                    )
                }
                
                // Tap gesture area
                Circle()
                    .fill(Color.clear)
                    .frame(width: wheelDiameter, height: wheelDiameter)
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Dismiss keyboard
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                
                                handleTap(at: value.location)
                            }
                    )
            }
            .frame(width: wheelDiameter, height: wheelDiameter)
            .padding(.vertical, styles.layout.paddingL)
            .onAppear {
                // Dismiss keyboard when wheel appears
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
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
        
        // Ignore taps outside the wheel
        if distance > wheelDiameter/2 {
            return
        }
        
        // Handle taps in the center neutral area
        if distance < centerDiameter/2 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedMood = .neutral
            }
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

// Update the CircleMoodBackground to ensure correct color placement in quadrants
struct CircleMoodBackground: View {
  var body: some View {
      ZStack {
          // Rotated to align colors with the correct quadrants
          Circle()
              .fill(
                  AngularGradient(
                      gradient: Gradient(colors: [
                          // Top left (red quadrant)
                          Color(hex: "#FF3399"), // Stressed
                          Color(hex: "#FF3333"), // Angry
                          Color(hex: "#FF9900"), // Tense
                          
                          // Top right (yellow quadrant)
                          Color(hex: "#CCFF00"), // Alert
                          Color(hex: "#99FF33"), // Excited
                          Color(hex: "#66FF66"), // Happy
                          
                          // Bottom right (green quadrant)
                          Color(hex: "#33FFCC"), // Content
                          Color(hex: "#33CCFF"), // Relaxed
                          Color(hex: "#3399FF"), // Calm
                          
                          // Bottom left (blue quadrant)
                          Color(hex: "#6666FF"), // Bored
                          Color(hex: "#9933FF"), // Depressed
                          Color(hex: "#CC33FF"), // Sad
                          
                          // Back to start to complete the circle
                          Color(hex: "#FF3399")  // Stressed
                      ]),
                      center: .center,
                      startAngle: .degrees(135),
                      endAngle: .degrees(495)
                  )
              )
              .overlay(
                  Circle()
                      .stroke(Color.white.opacity(0.3), lineWidth: 1)
              )
      }
  }
}

// Completely revised MoodLabel with fixed positioning
struct MoodLabel: View {
    let mood: Mood
    let wheelRadius: CGFloat
    let centerRadius: CGFloat
    let isSelected: Bool
    
    private let styles = UIStyles.shared
    
    var body: some View {
        // Skip rendering if it's neutral - we'll handle it separately
        if mood == .neutral {
            return Text(mood.name)
                .font(styles.typography.moodLabel)
                .foregroundColor(isSelected ? Color.black : Color.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    isSelected ? 
                        Color.white : 
                        Color(hex: "#333333").opacity(0.7)
                )
                .cornerRadius(4)
                .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                .position(x: wheelRadius, y: wheelRadius)
                .eraseToAnyView()
        }
        
        // Get fixed position based on mood
        let position = fixedPositionForMood(mood: mood, wheelRadius: wheelRadius)
        
        return Text(mood.name)
            .font(styles.typography.moodLabel)
            .foregroundColor(isSelected ? Color.black : Color.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isSelected ? 
                    Color.white : 
                    Color(hex: "#333333").opacity(0.7)
            )
            .cornerRadius(4)
            .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
            .position(position)
            .eraseToAnyView()
    }
    
    // Use fixed positions for each mood to ensure proper spacing
    private func fixedPositionForMood(mood: Mood, wheelRadius: CGFloat) -> CGPoint {
        let center = CGPoint(x: wheelRadius, y: wheelRadius)
        let radius = wheelRadius * 0.78 // Reduced from 0.85 to pull labels in slightly
        
        switch mood {
        // Top left quadrant (negative valence, positive arousal)
        case .stressed:
            return CGPoint(x: center.x - radius * 0.7, y: center.y - radius * 0.7)
        case .angry:
            return CGPoint(x: center.x - radius * 0.25, y: center.y - radius * 0.95)
        case .tense:
            return CGPoint(x: center.x + radius * 0.25, y: center.y - radius * 0.95)
            
        // Top right quadrant (positive valence, positive arousal)
        case .alert:
            return CGPoint(x: center.x + radius * 0.7, y: center.y - radius * 0.7)
        case .excited:
            return CGPoint(x: center.x + radius * 0.95, y: center.y - radius * 0.25)
        case .happy:
            return CGPoint(x: center.x + radius * 0.95, y: center.y + radius * 0.25)
            
        // Bottom right quadrant (positive valence, negative arousal)
        case .content:
            return CGPoint(x: center.x + radius * 0.7, y: center.y + radius * 0.7)
        case .relaxed:
            return CGPoint(x: center.x + radius * 0.25, y: center.y + radius * 0.95)
        case .calm:
            return CGPoint(x: center.x - radius * 0.25, y: center.y + radius * 0.95)
            
        // Bottom left quadrant (negative valence, negative arousal)
        case .bored:
            return CGPoint(x: center.x - radius * 0.7, y: center.y + radius * 0.7)
        case .depressed:
            return CGPoint(x: center.x - radius * 0.95, y: center.y + radius * 0.25)
        case .sad:
            return CGPoint(x: center.x - radius * 0.95, y: center.y - radius * 0.25)
            
        // Neutral (center) - handled separately
        case .neutral:
            return center
        }
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

