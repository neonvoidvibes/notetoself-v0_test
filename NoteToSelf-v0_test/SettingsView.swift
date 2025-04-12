import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager // Inject ThemeManager
    @EnvironmentObject var databaseService: DatabaseService // Inject DatabaseService
    @Environment(\.settingsScrollingDisabled) private var settingsScrollingDisabled
    @State private var notificationTime: Date = Date() // Should load saved time
    @State private var notificationsEnabled: Bool = false // Should load saved state

    // Header animation state
    @State private var headerAppeared = false

    // Access shared styles - Use @ObservedObject
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        ZStack {
            styles.colors.menuBackground // Use styles instance
                .ignoresSafeArea()

            VStack(spacing: 0) { // Use VStack to hold header and ScrollView
                // Header with Title and animated accent
                 ZStack(alignment: .center) {
                     VStack(spacing: 8) {
                         Text("Settings")
                             .font(styles.typography.title1)
                             .foregroundColor(styles.colors.text)

                         // Animated accent bar
                         Rectangle()
                             .fill(
                                 LinearGradient(
                                     gradient: Gradient(colors: [
                                         styles.colors.accent.opacity(0.7),
                                         styles.colors.accent
                                     ]),
                                     startPoint: .leading,
                                     endPoint: .trailing
                                 )
                             )
                             .frame(width: headerAppeared ? 30 : 0, height: 3)
                             .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: headerAppeared)
                     }

                     // Close button HStack restored
                     HStack {
                         Spacer()

                         // Close button (double chevron) at right side
                         Button(action: {
                             // Post notification to toggle settings visibility (handled by MainTabView)
                             NotificationCenter.default.post(name: .toggleSettingsNotification, object: nil) // Use standard name
                         }) {
                             Image(systemName: "chevron.right.2")
                                 .font(.system(size: 20, weight: .bold))
                                 .foregroundColor(styles.colors.accent)
                                 .frame(width: 36, height: 36)
                         }
                     }
                     .padding(.horizontal, styles.layout.paddingXL) // Apply standard padding
                 }
                 .padding(.top, 8)
                 .padding(.bottom, 8)
                 // Add background matching the scrollview content
                 .background(styles.colors.menuBackground)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: styles.layout.spacingXL) {

                         // Appearance Section (NEW)
                         AppearanceSection() // Extracted to subview
                              .transition(.scale.combined(with: .opacity))

                        // Subscription section
                        SubscriptionSection(subscriptionTier: appState.subscriptionTier) // Pass renamed tier
                            .transition(.scale.combined(with: .opacity))
                            // .padding(.top, 40) // Removed extra top padding

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

                        // Developer Section (DEBUG ONLY)
                        #if DEBUG
                        DeveloperSection() // Now contains the toggle and sub picker
                            .transition(.scale.combined(with: .opacity))
                        #endif

                    }
                    .padding(.horizontal, styles.layout.paddingL)
                    .padding(.top, 40) // Add padding to the top of the scroll content
                    .padding(.bottom, 50)
                }
                .disabled(settingsScrollingDisabled)
            }
        }
        // .preferredColorScheme(.dark) // REMOVED - Let theme handle it
        .onAppear { // Trigger animation when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                headerAppeared = true
            }
        }
    }
}

// MARK: - Appearance Section (NEW)
struct AppearanceSection: View {
    @EnvironmentObject var themeManager: ThemeManager // Inject ThemeManager
    @ObservedObject private var styles = UIStyles.shared

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text("Appearance")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)

            styles.card(
                VStack(spacing: styles.layout.spacingM) {
                    // Theme Mode Picker
                    Picker("Color Scheme", selection: $themeManager.themeModePreference) {
                        ForEach(ThemeModePreference.allCases) { preference in
                            Text(preference.rawValue).tag(preference)
                        }
                    }
                    .pickerStyle(.segmented) // Use segmented style for concise options
                    // .colorMultiply(styles.colors.accent) // REMOVED TINT

                    // Add Theme selection later if needed
                    // Example:
                    // Picker("Theme", selection: $themeManager.activeThemeName) { ... }
                }
                .padding(styles.layout.paddingL)
                .frame(maxWidth: .infinity)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
    }
}


// MARK: - Subscription Section
struct SubscriptionSection: View {
    let subscriptionTier: SubscriptionTier // Now expects .free or .pro
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
                            Text(subscriptionTier == .pro ? "Pro" : "Free") // Updated label
                                .font(styles.typography.title3) // Use styles instance
                                .foregroundColor(styles.colors.text) // Use styles instance

                            Text(subscriptionTier == .pro ? "Unlimited reflections and advanced insights" : "Basic features with limited reflections") // Updated label
                                .font(styles.typography.bodySmall) // Use styles instance
                                .foregroundColor(styles.colors.textSecondary) // Use styles instance
                        }

                        Spacer()

                        if subscriptionTier == .pro { // Updated check
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
                              Text("Upgrade to Pro") // Updated label
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
                    .frame(maxWidth: .infinity, alignment: .center)
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
            .foregroundColor(styles.colors.primaryButtonText) // Use theme color
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
                    // Use closure-based Toggle initializer to apply color directly to Text
                    Toggle(isOn: $notificationsEnabled) {
                        Text("Daily Reminder")
                            .foregroundColor(styles.colors.text) // Standard text color for label
                    }
                    .tint(styles.colors.accent) // Tint the toggle control itself
                    .font(styles.typography.bodyFont) // Apply font to the whole Toggle container
                    .toggleStyle(SwitchToggleStyle(tint: styles.colors.accent)) // Use standard switch, but tinted

                    // Conditionally show time picker with transition
                    if notificationsEnabled {
                        HStack {
                            Text("Reminder Time")
                                .font(styles.typography.bodyFont) // Use styles instance
                                .foregroundColor(styles.colors.text) // Use standard text color here

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

// MARK: - Developer Section (DEBUG ONLY)
struct DeveloperSection: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var databaseService: DatabaseService
    // Access shared styles - Use @ObservedObject
    @ObservedObject private var styles = UIStyles.shared
    @State private var isGenerating: Bool = false // State for button feedback
    @State private var generationMessage: String = "" // State for feedback message

    // Calendar instance for weekday symbols
    private var calendar: Calendar { Calendar.current }

    var body: some View {
        VStack(alignment: .leading, spacing: styles.layout.spacingM) {
            Text("Developer Options")
                .font(styles.typography.title3)
                .foregroundColor(styles.colors.text)

            styles.card(
                VStack(spacing: styles.layout.spacingM) {
                    // Force Update Button
                    Button {
                        guard !isGenerating else { return } // Prevent multiple clicks
                        isGenerating = true
                        generationMessage = "Generating..."
                        // Ensure the call is within a Task
                        Task {
                            print("DEV BUTTON: Force updating all insights...")
                            // Ensure LLMService.shared is accessible here
                            // Call with forceGeneration: true
                            await triggerAllInsightGenerations(
                                llmService: LLMService.shared,
                                databaseService: databaseService,
                                appState: appState,
                                forceGeneration: true // Pass true here
                            )
                            print("DEV BUTTON: Insight generation triggered.")
                            // Update UI on main thread after awaiting generation
                            await MainActor.run {
                                generationMessage = "Insights update triggered."
                                // Reset after another delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                     isGenerating = false
                                     generationMessage = ""
                                }
                            }
                        }
                    } label: {
                        HStack {
                             if isGenerating {
                                 ProgressView()
                                     .tint(styles.colors.accent) // Use accent for spinner
                             }
                             Text(isGenerating ? generationMessage : "Force Update All Insights")
                                 .foregroundColor(styles.colors.accent)
                        }
                    }
                    .buttonStyle(UIStyles.GhostButtonStyle()) // Use Ghost style
                    .disabled(isGenerating)
                    .frame(maxWidth: .infinity, alignment: .center)

                    Divider().background(styles.colors.divider)

                    // Subscription Tier Picker (Moved Here)
                    HStack {
                         Text("Subscription Tier:")
                             .font(styles.typography.bodyFont)
                             .foregroundColor(styles.colors.text)
                         Spacer()
                         Picker("", selection: $appState.subscriptionTier) {
                             Text("Free").tag(SubscriptionTier.free)
                             Text("Pro").tag(SubscriptionTier.pro) // Renamed
                         }
                         .pickerStyle(SegmentedPickerStyle())
                         .frame(maxWidth: 150) // Limit width
                    }

                    Divider().background(styles.colors.divider)

                    // Simulate Empty State Toggle
                    Toggle(isOn: $appState.simulateEmptyState) {
                         Text("Simulate Empty Journal State")
                             .foregroundColor(styles.colors.text)
                    }
                    .tint(styles.colors.accent)
                    .font(styles.typography.bodyFont)

                    // --- Streak Simulation ---
                    Divider().background(styles.colors.divider)

                    Toggle(isOn: $appState.overrideStreakStartDate) {
                         Text("Simulate Streak Start")
                             .foregroundColor(styles.colors.text)
                    }
                    .tint(styles.colors.accent)
                    .font(styles.typography.bodyFont)

                    if appState.overrideStreakStartDate {
                        HStack {
                            Text("Streak Starts On:")
                                .font(styles.typography.bodyFont)
                                .foregroundColor(styles.colors.text)
                            Spacer()
                            Picker("Streak Start", selection: $appState.simulatedStreakStartWeekday) {
                                // Use Calendar to get weekday symbols respecting locale and firstWeekday
                                ForEach(1...7, id: \.self) { weekday in
                                    Text(calendar.weekdaySymbols[weekday - 1]).tag(weekday)
                                }
                            }
                            .pickerStyle(MenuPickerStyle()) // Compact style
                             // Tint the picker control if needed
                             // .tint(styles.colors.accent) // Uncomment if you want the Picker button accented
                        }
                        .padding(.leading) // Indent the picker slightly
                    }
                    // --- End Streak Simulation ---

                }
                .padding(styles.layout.paddingL)
                .frame(maxWidth: .infinity)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
        // Set default subscription tier to Pro when the view appears
        .onAppear {
             #if DEBUG
             // Set default only if it's not already Pro
             if appState.subscriptionTier != .pro {
                 appState.subscriptionTier = .pro
                 print("[Dev Section] Default subscription set to Pro on appear.")
             }
             #endif
         }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // Wrap preview in NavigationView if needed for title consistency, but ZStack is fine
        SettingsView()
            .environmentObject(AppState())
            .environmentObject(ThemeManager.shared) // Provide ThemeManager for preview
            .environmentObject(DatabaseService()) // Provide DatabaseService for preview
            .environmentObject(UIStyles.shared) // Provide UIStyles for preview
            // Removed preferredColorScheme, let preview system decide
    }
}