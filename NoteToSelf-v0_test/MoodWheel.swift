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

// Completely revised MoodLabel with consistent spacing and selection styling
struct MoodLabel: View {
  let mood: Mood
  let wheelRadius: CGFloat
  let centerRadius: CGFloat
  let isSelected: Bool
  
  private let styles = UIStyles.shared
  
  var body: some View {
      let position = calculatePosition(mood: mood, wheelRadius: wheelRadius, centerRadius: centerRadius)
      
      return Text(mood.name)
          .font(styles.typography.moodLabel) // Using the new larger font size
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
  
  // Calculate precise positions for each mood with consistent spacing
  private func calculatePosition(mood: Mood, wheelRadius: CGFloat, centerRadius: CGFloat) -> CGPoint {
      let center = CGPoint(x: wheelRadius, y: wheelRadius)
      
      // For neutral mood, place it at the center
      if mood == .neutral {
          return center
      }
      
      // For other moods, use a consistent radial placement
      // Use a radius multiplier of 0.85 to push labels closer to the edge
      let radiusMultiplier: CGFloat = 0.85
      let radius = wheelRadius * radiusMultiplier
      
      // Calculate angle based on mood position in the circumplex
      let angle = calculateAngle(for: mood)
      
      // Convert angle to x,y coordinates
      let x = center.x + radius * cos(angle)
      let y = center.y - radius * sin(angle) // Negate y to match SwiftUI coordinate system
      
      return CGPoint(x: x, y: y)
  }
  
  // Calculate the angle for each mood to ensure even spacing
  private func calculateAngle(for mood: Mood) -> CGFloat {
      // Define angles in radians (0 = right, π/2 = top, π = left, 3π/2 = bottom)
      switch mood {
      // Top left quadrant (negative valence, positive arousal)
      case .stressed: return 2.35 // ~135 degrees
      case .angry: return 2.09 // ~120 degrees
      case .tense: return 1.83 // ~105 degrees
          
      // Top right quadrant (positive valence, positive arousal)
      case .alert: return 1.31 // ~75 degrees
      case .excited: return 1.05 // ~60 degrees
      case .happy: return 0.79 // ~45 degrees
          
      // Bottom right quadrant (positive valence, negative arousal)
      case .content: return 0.52 // ~30 degrees
      case .relaxed: return 0.26 // ~15 degrees
      case .calm: return 6.02 // ~345 degrees
          
      // Bottom left quadrant (negative valence, negative arousal)
      case .bored: return 5.50 // ~315 degrees
      case .depressed: return 5.24 // ~300 degrees
      case .sad: return 4.97 // ~285 degrees
          
      // Neutral (center) - not used in this function but included for completeness
      case .neutral: return 0
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

