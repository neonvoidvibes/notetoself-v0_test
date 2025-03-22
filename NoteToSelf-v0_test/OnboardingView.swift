// OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Note to Self")
                .font(UIStyles.shared.typography.headingFont)
                .foregroundColor(UIStyles.shared.colors.text)
            Text("Capture your day in under 30 seconds. No sign-ups, no hassle, just quick reflections.")
                .font(UIStyles.shared.typography.bodyFont)
                .foregroundColor(UIStyles.shared.colors.text.opacity(0.8))
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
            .buttonStyle(UIStyles.shared.PrimaryButtonStyle())
        }
        .padding()
        .background(UIStyles.shared.colors.appBackground)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}