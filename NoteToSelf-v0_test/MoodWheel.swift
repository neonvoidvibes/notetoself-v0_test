import SwiftUI

struct MoodWheel: View {
    @Binding var selectedMood: Mood
    @State private var selectedIntensity: Int = 2 // Default: medium intensity
    @State private var isDragging: Bool = false
    @State private var dragLocation: CGPoint = .zero
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    // Constants for wheel dimensions
    private let wheelDiameter: CGFloat = 280
    private let centerDiameter: CGFloat = 100
    private let intensityRingThickness: CGFloat = 45
    
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
                // Background circle with gradient - dimmed when a mood is selected
                CircleMoodBackground(isDimmed: selectedMood != .neutral)
                
                // Draw segment dividing lines
                ForEach(0..<12) { index in
                    let angle = Double(index) * 30.0
                    Line(
                        from: CGPoint(
                            x: wheelDiameter/2 + centerDiameter/2 * cos(angle * .pi / 180),
                            y: wheelDiameter/2 + centerDiameter/2 * sin(angle * .pi / 180)
                        ),
                        to: CGPoint(
                            x: wheelDiameter/2 + wheelDiameter/2 * cos(angle * .pi / 180),
                            y: wheelDiameter/2 + wheelDiameter/2 * sin(angle * .pi / 180)
                        )
                    )
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
                
                // Draw the 12 mood segments (3 per quadrant)
                ForEach(0..<12) { index in
                    MoodSegment(
                        index: index,
                        totalSegments: 12,
                        mood: moodForSegment(index),
                        isSelected: selectedMood == moodForSegment(index) && selectedMood != .neutral,
                        selectedIntensity: selectedMood == moodForSegment(index) ? selectedIntensity : 0,
                        innerRadius: centerDiameter/2,
                        outerRadius: wheelDiameter/2
                    )
                }
                
                // Center neutral zone
                Circle()
                    .fill(selectedMood == .neutral ? 
                          Color.white : Color(hex: "#333333").opacity(0.7))
                    .frame(width: centerDiameter, height: centerDiameter)
                    .overlay(
                        Circle()
                            .stroke(selectedMood == .neutral ? Color.white.opacity(0.8) : Color.white.opacity(0.3), 
                                   lineWidth: selectedMood == .neutral ? 3 : 1)
                    )
                
                // Center label for selected mood
                VStack(spacing: 4) {
                    Text(selectedMood.name)
                        .font(styles.typography.title3)
                        .foregroundColor(selectedMood == .neutral ? Color.black : Color.white)
                        .fontWeight(.bold)
                    
                    if selectedMood != .neutral {
                        Text(intensityText(selectedIntensity))
                            .font(styles.typography.caption)
                            .foregroundColor(selectedMood == .neutral ? Color.black.opacity(0.7) : Color.white.opacity(0.7))
                    }
                }
                .offset(y: selectedMood == .neutral ? 0 : -5) // Slight adjustment if showing intensity
                
                // Invisible tap/drag area
                Circle()
                    .fill(Color.clear)
                    .frame(width: wheelDiameter, height: wheelDiameter)
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                dragLocation = value.location
                                updateMoodFromLocation(value.location)
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
            }
            .frame(width: wheelDiameter, height: wheelDiameter)
            .padding(.vertical, styles.layout.paddingL)
            
            // Color indicator
            RoundedRectangle(cornerRadius: styles.layout.radiusM)
                .fill(selectedMood.color)
                .frame(width: 60, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: styles.layout.radiusM)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(styles.layout.paddingL)
    }
    
    private func moodForSegment(_ index: Int) -> Mood {
        switch index {
        // Bottom-right (0° = right, going clockwise)
        case 0: return .content
        case 1: return .relaxed
        case 2: return .calm
        
        // Bottom-left quadrant
        case 3: return .bored
        case 4: return .depressed
        case 5: return .sad
        
        // Top-left quadrant
        case 6: return .stressed
        case 7: return .angry
        case 8: return .tense
        
        // Top-right quadrant
        case 9: return .alert
        case 10: return .excited
        case 11: return .happy
        
        default: return .neutral
        }
    }
    
    private func intensityText(_ intensity: Int) -> String {
        switch intensity {
        case 1: return "Slight"
        case 2: return "Moderate"
        case 3: return "Strong"
        default: return ""
        }
    }
    
    private func updateMoodFromLocation(_ location: CGPoint) {
        // Calculate coordinates relative to center
        let center = CGPoint(x: wheelDiameter/2, y: wheelDiameter/2)
        let relativeX = location.x - center.x
        let relativeY = location.y - center.y
        
        // Calculate distance from center
        let distance = sqrt(relativeX * relativeX + relativeY * relativeY)
        
        // Check if tap is in neutral zone
        if distance < centerDiameter/2 {
            selectedMood = .neutral
            selectedIntensity = 2 // Default medium intensity
            return
        }
        
        // If outside the wheel, ignore
        if distance > wheelDiameter/2 {
            return
        }
        
        // Calculate angle in degrees (0-360, where 0 is to the right, going clockwise)
        var angle = atan2(relativeY, relativeX) * 180 / .pi
        if angle < 0 {
            angle += 360
        }
        
        // Map angle to segment (0-11)
        // Each segment is 30 degrees, starting from the right (0°) and going clockwise
        let segment = Int(angle / 30)
        
        // Calculate intensity (1-3) based on distance from center
        let availableRadius = (wheelDiameter - centerDiameter) / 2
        let intensityPosition = (distance - centerDiameter/2) / availableRadius
        let intensity: Int
        
        if intensityPosition < 0.33 {
            intensity = 1 // Slight
        } else if intensityPosition < 0.66 {
            intensity = 2 // Moderate
        } else {
            intensity = 3 // Strong
        }
        
        // Update selected mood and intensity
        selectedMood = moodForSegment(segment)
        selectedIntensity = intensity
    }
}

// Line shape for drawing segment dividers
struct Line: Shape {
    var from: CGPoint
    var to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

// Mood segment (pie slice) with intensity rings
struct MoodSegment: View {
    let index: Int
    let totalSegments: Int
    let mood: Mood
    let isSelected: Bool
    let selectedIntensity: Int
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    
    private let styles = UIStyles.shared
    
    var body: some View {
        // Calculate angle ranges for this segment
        let segmentAngle = 360.0 / Double(totalSegments)
        let startAngle = Double(index) * segmentAngle
        let endAngle = startAngle + segmentAngle
        
        ZStack {
            // Full segment highlight with white border when selected
            if isSelected {
                // Full segment with white border
                AngularArc(
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
                .stroke(Color.white, lineWidth: 3)
                
                // Background for the entire segment
                AngularArc(
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
                .fill(mood.color.opacity(0.2))
            }
            
            // Ring 1 (innermost intensity)
            if isSelected && selectedIntensity >= 1 {
                AngularArc(
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    innerRadius: innerRadius,
                    outerRadius: innerRadius + (outerRadius - innerRadius) * 0.33
                )
                .fill(mood.color.opacity(selectedIntensity == 1 ? 0.8 : 0.5))
            }
            
            // Ring 2 (middle intensity)
            if isSelected && selectedIntensity >= 2 {
                AngularArc(
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    innerRadius: innerRadius + (outerRadius - innerRadius) * 0.33,
                    outerRadius: innerRadius + (outerRadius - innerRadius) * 0.66
                )
                .fill(mood.color.opacity(selectedIntensity == 2 ? 0.8 : 0.5))
            }
            
            // Ring 3 (outermost intensity)
            if isSelected && selectedIntensity >= 3 {
                AngularArc(
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    innerRadius: innerRadius + (outerRadius - innerRadius) * 0.66,
                    outerRadius: outerRadius
                )
                .fill(mood.color.opacity(0.8))
            }
        }
    }
}

// Custom shape for drawing angular arcs (pie slices)
struct AngularArc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        
        // Starting point at inner radius
        let startInnerX = center.x + innerRadius * cos(CGFloat(startAngle.radians))
        let startInnerY = center.y + innerRadius * sin(CGFloat(startAngle.radians))
        path.move(to: CGPoint(x: startInnerX, y: startInnerY))
        
        // Line to outer radius at start angle
        let startOuterX = center.x + outerRadius * cos(CGFloat(startAngle.radians))
        let startOuterY = center.y + outerRadius * sin(CGFloat(startAngle.radians))
        path.addLine(to: CGPoint(x: startOuterX, y: startOuterY))
        
        // Arc at outer radius
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // Line to inner radius at end angle
        let endInnerX = center.x + innerRadius * cos(CGFloat(endAngle.radians))
        let endInnerY = center.y + innerRadius * sin(CGFloat(endAngle.radians))
        path.addLine(to: CGPoint(x: endInnerX, y: endInnerY))
        
        // Arc at inner radius back to start
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        return path
    }
}

// Circle mood background with dimming option
struct CircleMoodBackground: View {
    var isDimmed: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            // Top right (0-90 degrees)
                            Color(hex: "#99FF33"), // Excited
                            Color(hex: "#66FF66"), // Happy
                            Color(hex: "#33FFCC"), // Content
                            
                            // Bottom right (90-180 degrees)
                            Color(hex: "#33CCFF"), // Relaxed
                            Color(hex: "#3399FF"), // Calm
                            Color(hex: "#6666FF"), // Bored
                            
                            // Bottom left (180-270 degrees)
                            Color(hex: "#9933FF"), // Depressed
                            Color(hex: "#CC33FF"), // Sad
                            Color(hex: "#FF3399"), // Stressed
                            
                            // Top left (270-360 degrees)
                            Color(hex: "#FF3333"), // Angry
                            Color(hex: "#FF9900"), // Tense
                            Color(hex: "#CCFF00"), // Alert
                            
                            // Back to start
                            Color(hex: "#99FF33")  // Excited
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    )
                )
                .opacity(isDimmed ? 0.3 : 1.0) // Dim when a mood is selected
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

