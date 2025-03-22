import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Note to Self")
                UIStyles.shared.headingFont
                UIStyles.shared.textColor
            Text("Capture your day in under 30 seconds. No sign-ups, no hassle, just quick reflections.")
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.textColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Button(action: {
                // Action to dismiss onboarding and move to main interface
            }) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .bold))
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(UIStyles.PrimaryButtonStyle())
        }
        .padding()
        UIStyles.shared.appBackground
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}