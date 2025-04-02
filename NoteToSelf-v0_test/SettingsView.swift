import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.settingsScrollingDisabled) private var settingsScrollingDisabled
    @State private var notificationTime: Date = Date() // Should load saved time
    @State private var notificationsEnabled: Bool = false // Should load saved state

    // Access shared styles - Use @ObservedObject
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        ZStack {
            styles.colors.menuBackground // Use styles instance
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: styles.layout.spacingXL) {
                    // Subscription section
                    // SubscriptionSection observes styles internally now
                    SubscriptionSection(subscriptionTier: appState.subscriptionTier)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.top, 40)

                    // Notifications section
                    // NotificationsSection observes styles internally now
                    NotificationsSection(
                        notificationsEnabled: $notificationsEnabled,
                        notificationTime: $notificationTime
                    )
                    .transition(.scale.combined(with: .opacity))

                    // Privacy & Export section
                    // PrivacySection observes styles internally now
                    PrivacySection()
                        .transition(.scale.combined(with: .opacity))

                    // About section
                    // AboutSection observes styles internally now
                    AboutSection()
                        .transition(.scale.combined(with: .opacity))

                }
                .padding(.horizontal, styles.layout.paddingL)
                .padding(.top, styles.layout.topSafeAreaPadding) // Use top padding from styles
                .padding(.bottom, 50)
            }
            .disabled(settingsScrollingDisabled)
        }
        // .preferredColorScheme(.dark) // REMOVED - Let theme handle it
    }
}

// MARK: - Subscription Section
struct SubscriptionSection: View {
    let subscriptionTier: SubscriptionTier
    // Access shared styles - Use @ObservedObject
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text("Subscription")
                .font(styles.typography.title3) // Use styles instance
                .foregroundColor(styles.colors.text) // Use styles instance

            styles.card( // Use styles instance method
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        VStack(alignment: .leading, spacing: styles.layout.spacingS) {
                            Text(subscriptionTier == .premium ? "Premium" : "Free")
                                .font(styles.typography.title3) // Use styles instance
                                .foregroundColor(styles.colors.text) // Use styles instance

                            Text(subscriptionTier == .premium ? "Unlimited reflections and advanced insights" : "Basic features with limited reflections")
                                .font(styles.typography.bodySmall) // Use styles instance
                                .foregroundColor(styles.colors.textSecondary) // Use styles instance
                        }

                        Spacer()

                        if subscriptionTier == .premium {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: styles.layout.iconSizeL))
                                .foregroundColor(styles.colors.accent) // Use styles instance
                                .shadow(color: styles.colors.accent.opacity(0.5), radius: 5, x: 0, y: 0) // Use styles instance
                        }
                    }

                    if subscriptionTier == .free {
                         Button {
                             // Show subscription options
                         } label: {
                              Text("Upgrade to Premium")
                                  .foregroundColor(styles.colors.primaryButtonText) // Apply color directly to Text
                         }
                          // Pass the styles instance to the button style initializer
                         .buttonStyle(GlowingButtonStyle()) // Style observes internally
                    } else {
                        Button {
                            // Show subscription management
                        } label: {
                             Text("Manage Subscription") // Example: Assuming Text is label
                                 .foregroundColor(styles.colors.text) // Secondary style uses text color
                        }
                        // Pass the styles instance to the button style initializer
                        .buttonStyle(UIStyles.SecondaryButtonStyle()) // Style observes internally
                    }

                    Button {
                         // Restore purchases logic
                    } label: {
                         Text("Restore Purchases") // Example: Assuming Text is label
                             .foregroundColor(styles.colors.accent) // Ghost style uses accent color
                    }
                    // Pass the styles instance to the button style initializer
                    .buttonStyle(UIStyles.GhostButtonStyle()) // Style observes internally
                }
                .padding(styles.layout.paddingL)
                .frame(maxWidth: .infinity)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8) // Shadow color can be themed
        }
    }
}

// Ensure Button Styles observe UIStyles internally
struct GlowingButtonStyle: ButtonStyle {
    @ObservedObject var styles = UIStyles.shared // Observe singleton

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(styles.typography.bodyFont)
            .padding(styles.layout.paddingM)
            .background(
                RoundedRectangle(cornerRadius: styles.layout.radiusM)
                    .fill(styles.colors.accent) // Use styles instance
                    .shadow(color: styles.colors.accent.opacity(configuration.isPressed ? 0.3 : 0.6), radius: configuration.isPressed ? 5 : 10, x: 0, y: 0) // Use styles instance
            )
            .foregroundColor(.black) // Contrast color
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Notifications Section
struct NotificationsSection: View {
    @Binding var notificationsEnabled: Bool
    @Binding var notificationTime: Date
    // Access shared styles - Use @ObservedObject
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text("Notifications")
                .font(styles.typography.title3) // Use styles instance
                .foregroundColor(styles.colors.text) // Use styles instance

            styles.card( // Use styles instance method
                VStack(spacing: styles.layout.spacingM) {
                    // Toggle with fixed width
                    Toggle("Daily Reminder", isOn: $notificationsEnabled)
                        .font(styles.typography.bodyFont) // Use styles instance
                        .foregroundColor(styles.colors.text) // Use styles instance
                        // Pass styles instance to toggle style
                        .toggleStyle(ModernToggleStyle()) // Style observes internally

                    // Conditionally show time picker with transition
                    if notificationsEnabled {
                        HStack {
                            Text("Reminder Time")
                                .font(styles.typography.bodyFont) // Use styles instance
                                .foregroundColor(styles.colors.text) // Use styles instance

                            Spacer()

                            // Use StyledDatePicker for consistency
                            // StyledDatePicker observes styles internally
                            StyledDatePicker(selection: $notificationTime, displayedComponents: .hourAndMinute)
                        }
                        .transition(.opacity.combined(with: .slide))
                    }
                }
                .padding(styles.layout.paddingL)
                .frame(maxWidth: .infinity)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8) // Shadow color can be themed
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: notificationsEnabled)
    }
}

// Ensure Toggle Style observes UIStyles internally
struct ModernToggleStyle: ToggleStyle {
    @ObservedObject var styles = UIStyles.shared // Observe singleton

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? styles.colors.accent : Color.gray.opacity(0.3)) // Use styles instance
                    .frame(width: 50, height: 30)

                Circle()
                    .fill(Color.white) // Knob color can be themed later if needed
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
    // Access shared styles - Use @ObservedObject
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text("Privacy & Data")
                .font(styles.typography.title3) // Use styles instance
                .foregroundColor(styles.colors.text) // Use styles instance

            styles.card( // Use styles instance method
                VStack(spacing: styles.layout.spacingM) {
                    Text("Your journal entries are stored locally on your device. No account is required to use Note to Self.")
                        .font(styles.typography.bodySmall) // Use styles instance
                        .foregroundColor(styles.colors.textSecondary) // Use styles instance
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Export Journal Data") {
                        // Export data logic
                    }
                     // Pass the styles instance to the button style initializer
                    .buttonStyle(UIStyles.SecondaryButtonStyle()) // Style observes internally
                    .frame(maxWidth: .infinity)

                    Button("Delete All Data") {
                        // Delete data logic with confirmation
                    }
                    .foregroundColor(styles.colors.error) // Use styles instance
                     // Pass the styles instance to the button style initializer
                    .buttonStyle(UIStyles.GhostButtonStyle()) // Style observes internally
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(styles.layout.paddingL)
                .frame(maxWidth: .infinity)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8) // Shadow color can be themed
        }
    }
}

// MARK: - About Section
struct AboutSection: View {
    // Access shared styles - Use @ObservedObject
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text("About")
                .font(styles.typography.title3) // Use styles instance
                .foregroundColor(styles.colors.text) // Use styles instance

            styles.card( // Use styles instance method
                VStack(spacing: styles.layout.spacingM) {
                    HStack {
                        Text("Version")
                            .foregroundColor(styles.colors.text) // Use styles instance

                        Spacer()

                        Text("1.0.0") // TODO: Replace with dynamic version
                            .foregroundColor(styles.colors.textSecondary) // Use styles instance
                    }

                    Divider()
                        .background(styles.colors.divider) // Use styles instance

                    Button(action: {
                        // Open privacy policy
                    }) {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundColor(styles.colors.accent) // Use styles instance

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(styles.colors.textSecondary) // Use styles instance
                        }
                    }

                    Divider()
                        .background(styles.colors.divider) // Use styles instance

                    Button(action: {
                        // Open terms of service
                    }) {
                        HStack {
                            Text("Terms of Service")
                                .foregroundColor(styles.colors.accent) // Use styles instance

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(styles.colors.textSecondary) // Use styles instance
                        }
                    }

                    Divider()
                        .background(styles.colors.divider) // Use styles instance

                    Button(action: {
                        // Reset onboarding flag
                    }) {
                        HStack {
                            Text("Reset Onboarding")
                                .foregroundColor(styles.colors.accent) // Use styles instance

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(styles.colors.textSecondary) // Use styles instance
                        }
                    }
                }
                .padding(styles.layout.paddingL)
                .frame(maxWidth: .infinity)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8) // Shadow color can be themed
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState())
            .environmentObject(UIStyles.shared) // Provide UIStyles for preview
            // Removed preferredColorScheme, let preview system decide
    }
}