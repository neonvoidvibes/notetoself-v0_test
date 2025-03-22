import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            styles.colors.appBackground
                .ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .foregroundColor(styles.colors.accent)
                    .padding(.trailing, styles.layout.paddingL)
                    .padding(.top, styles.layout.paddingL)
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    TabsOverviewPage()
                        .tag(1)
                    
                    PrivacyPage()
                        .tag(2)
                    
                    SubscriptionPage()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // Navigation buttons
                HStack {
                    // Back button (hidden on first page)
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(styles.colors.accent)
                    }
                    
                    Spacer()
                    
                    // Next/Get Started button
                    Button(currentPage == 3 ? "Get Started" : "Next") {
                        if currentPage == 3 {
                            hasSeenOnboarding = true
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
.buttonStyle(UIStyles.PrimaryButtonStyle(
                        colors: styles.colors,
                        typography: styles.typography,
                        layout: styles.layout
                    ))
                    .frame(width: 150)
                }
                .padding(.horizontal, styles.layout.paddingL)
                .padding(.bottom, styles.layout.paddingL)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Onboarding Pages

struct WelcomePage: View {
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingXL) {
            Spacer()
            
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundColor(styles.colors.accent)
            
            VStack(spacing: styles.layout.spacingM) {
                Text("Welcome to Note to Self")
                    .font(styles.typography.title1)
                    .foregroundColor(styles.colors.text)
                    .multilineTextAlignment(.center)
                
                Text("Capture your day in under 30 seconds")
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(styles.layout.paddingL)
    }
}

struct TabsOverviewPage: View {
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingXL) {
            Spacer()
            
            Text("Three Simple Tabs")
                .font(styles.typography.title1)
                .foregroundColor(styles.colors.text)
                .multilineTextAlignment(.center)
            
            VStack(spacing: styles.layout.spacingXL) {
                FeatureItem(
                    icon: "book.fill",
                    title: "Journal",
                    description: "Quick daily entries with optional mood tracking"
                )
                
                FeatureItem(
                    icon: "chart.bar.fill",
                    title: "Insights",
                    description: "Track your mood trends and journaling streaks"
                )
                
                FeatureItem(
                    icon: "bubble.left.fill",
                    title: "Reflections",
                    description: "AI-powered chat for deeper self-reflection"
                )
            }
            
            Spacer()
            Spacer()
        }
        .padding(styles.layout.paddingL)
    }
}

struct PrivacyPage: View {
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingXL) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(styles.colors.accent)
            
            VStack(spacing: styles.layout.spacingM) {
                Text("Your Privacy Matters")
                    .font(styles.typography.title1)
                    .foregroundColor(styles.colors.text)
                    .multilineTextAlignment(.center)
                
                Text("No account required. Your journal entries are stored locally on your device.")
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Text("Optional iCloud sync available in settings.")
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, styles.layout.spacingS)
            }
            
            Spacer()
            Spacer()
        }
        .padding(styles.layout.paddingL)
    }
}

struct SubscriptionPage: View {
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: styles.layout.spacingXL) {
            Spacer()
            
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundColor(styles.colors.accent)
            
            VStack(spacing: styles.layout.spacingM) {
                Text("Premium Features")
                    .font(styles.typography.title1)
                    .foregroundColor(styles.colors.text)
                    .multilineTextAlignment(.center)
                
                Text("Basic journaling is always free")
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                    PremiumFeatureItem(text: "Advanced analytics and insights")
                    PremiumFeatureItem(text: "Unlimited AI reflections")
                    PremiumFeatureItem(text: "Additional themes and customization")
                }
                .padding(.top, styles.layout.spacingM)
            }
            
            Spacer()
            Spacer()
        }
        .padding(styles.layout.paddingL)
    }
}

// MARK: - Helper Components

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        HStack(spacing: styles.layout.spacingL) {
            Image(systemName: icon)
                .font(.system(size: styles.layout.iconSizeXL))
                .foregroundColor(styles.colors.accent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: styles.layout.spacingXS) {
                Text(title)
                    .font(styles.typography.title3)
                    .foregroundColor(styles.colors.text)
                
                Text(description)
                    .font(styles.typography.bodySmall)
                    .foregroundColor(styles.colors.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct PremiumFeatureItem: View {
    let text: String
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        HStack(spacing: styles.layout.spacingM) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(styles.colors.accent)
            
            Text(text)
                .font(styles.typography.bodyFont)
                .foregroundColor(styles.colors.text)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(hasSeenOnboarding: .constant(false))
    }
}