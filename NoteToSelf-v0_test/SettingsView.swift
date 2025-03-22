import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var notificationTime: Date = Date()
    @State private var notificationsEnabled: Bool = false
    
    // Access to shared styles
    private let styles = UIStyles.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                styles.colors.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: styles.layout.spacingXL) {
                        // Subscription section
                        SubscriptionSection(subscriptionTier: appState.subscriptionTier)
                        
                        // Notifications section
                        NotificationsSection(
                            notificationsEnabled: $notificationsEnabled,
                            notificationTime: $notificationTime
                        )
                        
                        // Privacy & Export section
                        PrivacySection()
                        
                        // About section
                        AboutSection()
                    }
                    .padding(styles.layout.paddingL)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(styles.colors.accent)
                }
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
                        }
                    }
                    
                    if subscriptionTier == .free {
                        Button("Upgrade to Premium") {
                            // Show subscription options
                        }
                        .buttonStyle(UIStyles.PrimaryButtonStyle(
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
        }
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
                    
                    if notificationsEnabled {
                        DatePicker("Reminder Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .foregroundColor(styles.colors.text)
                    }
                }
                .padding(styles.layout.paddingL)
            )
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
                    
                    Button("Privacy Policy") {
                        // Open privacy policy
                    }
                    .foregroundColor(styles.colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Terms of Service") {
                        // Open terms of service
                    }
                    .foregroundColor(styles.colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Reset Onboarding") {
                        // Reset onboarding flag
                    }
                    .foregroundColor(styles.colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(styles.layout.paddingL)
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        
        return SettingsView()
            .environmentObject(appState)
            .preferredColorScheme(.dark)
    }
}