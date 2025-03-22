import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var notificationTime: Date = Date()
    @State private var notificationsEnabled: Bool = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            styles.colors.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: styles.layout.spacingXL) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(styles.typography.title1)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                    }
                    .padding(.top, styles.layout.topSafeAreaPadding)
                    
                    // Subscription section
                    SubscriptionSection(subscriptionTier: appState.subscriptionTier)
                        .transition(.scale.combined(with: .opacity))
                    
                    // Notifications section
                    NotificationsSection(
                        notificationsEnabled: $notificationsEnabled,
                        notificationTime: $notificationTime
                    )
                    .transition(.scale.combined(with: .opacity))
                    
                    // Privacy & Export section
                    PrivacySection()
                        .transition(.scale.combined(with: .opacity))
                    
                    // About section
                    AboutSection()
                        .transition(.scale.combined(with: .opacity))
                }
                .padding(styles.layout.paddingL)
            }
        }
    }
}

// MARK: - Subscription Section

struct SubscriptionSection: View {
    let subscriptionTier: SubscriptionTier
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text("Subscription")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
            
            styles.card(
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                            Text(subscriptionTier == .premium ? "Premium" : "Free")
                                .font(styles.typography.title3)
                                .foregroundColor(styles.colors.text)
                            
                            Text(subscriptionTier == .premium ? "Unlimited reflections and advanced insights" : "Basic features with limited reflections")
                                .font(styles.typography.bodySmall)
                                .foregroundColor(styles.colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if subscriptionTier == .premium {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: styles.layout.iconSizeL))
                                .foregroundColor(styles.colors.accent)
                                .shadow(color: styles.colors.accent.opacity(0.5), radius: 5, x: 0, y: 0)
                        }
                    }
                    
                    if subscriptionTier == .free {
                        Button("Upgrade to Premium") {
                            // Show subscription options
                        }
                        .buttonStyle(GlowingButtonStyle(
                            colors: styles.colors,
                            typography: styles.typography,
                            layout: styles.layout
                        ))
                    } else {
                        Button("Manage Subscription") {
                            // Show subscription management
                        }
                        .buttonStyle(UIStyles.SecondaryButtonStyle(
                            colors: styles.colors,
                            typography: styles.typography,
                            layout: styles.layout
                        ))
                    }
                    
                    Button("Restore Purchases") {
                        // Restore purchases logic
                    }
                    .buttonStyle(UIStyles.GhostButtonStyle(
                        colors: styles.colors,
                        typography: styles.typography,
                        layout: styles.layout
                    ))
                }
                .padding(styles.layout.paddingL)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
    }
}

struct GlowingButtonStyle: ButtonStyle {
    let colors: UIStyles.Colors
    let typography: UIStyles.Typography
    let layout: UIStyles.Layout
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(typography.bodyFont)
            .padding(layout.paddingM)
            .background(
                RoundedRectangle(cornerRadius: layout.radiusM)
                    .fill(colors.accent)
                    .shadow(color: colors.accent.opacity(configuration.isPressed ? 0.3 : 0.6), radius: configuration.isPressed ? 5 : 10, x: 0, y: 0)
            )
            .foregroundColor(.black)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Notifications Section

struct NotificationsSection: View {
    @Binding var notificationsEnabled: Bool
    @Binding var notificationTime: Date
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text("Notifications")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
            
            styles.card(
                VStack(spacing: styles.layout.spacingM) {
                    Toggle("Daily Reminder", isOn: $notificationsEnabled)
                        .foregroundColor(styles.colors.text)
                        .toggleStyle(ModernToggleStyle(colors: styles.colors))
                    
                    if notificationsEnabled {
                        DatePicker("Reminder Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .foregroundColor(styles.colors.text)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(styles.layout.paddingL)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: notificationsEnabled)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
    }
}

struct ModernToggleStyle: ToggleStyle {
    let colors: UIStyles.Colors
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? colors.accent : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .frame(width: 26, height: 26)
                    .offset(x: configuration.isOn ? 10 : -10)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

// MARK: - Privacy Section

struct PrivacySection: View {
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text("Privacy & Data")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
            
            styles.card(
                VStack(spacing: styles.layout.spacingM) {
                    Text("Your journal entries are stored locally on your device. No account is required to use Note to Self.")
                        .font(styles.typography.bodySmall)
                        .foregroundColor(styles.colors.textSecondary)
                    
                    Button("Export Journal Data") {
                        // Export data logic
                    }
                    .buttonStyle(UIStyles.SecondaryButtonStyle(
                        colors: styles.colors,
                        typography: styles.typography,
                        layout: styles.layout
                    ))
                    
                    Button("Delete All Data") {
                        // Delete data logic with confirmation
                    }
                    .foregroundColor(styles.colors.error)
                    .buttonStyle(UIStyles.GhostButtonStyle(
                        colors: styles.colors,
                        typography: styles.typography,
                        layout: styles.layout
                    ))
                }
                .padding(styles.layout.paddingL)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text("About")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)
            
            styles.card(
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Version")
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .foregroundColor(styles.colors.textSecondary)
                    }
                    
                    Divider()
                        .background(styles.colors.divider)
                    
                    Button(action: {
                        // Open privacy policy
                    }) {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundColor(styles.colors.accent)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(styles.colors.textSecondary)
                        }
                    }
                    
                    Divider()
                        .background(styles.colors.divider)
                    
                    Button(action: {
                        // Open terms of service
                    }) {
                        HStack {
                            Text("Terms of Service")
                                .foregroundColor(styles.colors.accent)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(styles.colors.textSecondary)
                        }
                    }
                    
                    Divider()
                        .background(styles.colors.divider)
                    
                    Button(action: {
                        // Reset onboarding flag
                    }) {
                        HStack {
                            Text("Reset Onboarding")
                                .foregroundColor(styles.colors.accent)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(styles.colors.textSecondary)
                        }
                    }
                }
                .padding(styles.layout.paddingL)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState())
    }
}
