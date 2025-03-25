import SwiftUI

struct ConfirmationModal: View {
    var title: String
    var message: String
    var confirmText: String
    var cancelText: String = "Cancel"
    var confirmAction: () -> Void
    var cancelAction: () -> Void
    var isDestructive: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    private let styles = UIStyles.shared
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    cancelAction()
                }
            
            // Modal content
            VStack(spacing: 20) {
                // Title
                Text(title)
                    .font(styles.typography.title1)
                    .foregroundColor(styles.colors.text)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(message)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Buttons
                VStack(spacing: 12) {
                    // Confirm button
                    Button(action: {
                        confirmAction()
                    }) {
                        Text(confirmText)
                            .font(styles.typography.bodyFont)
                            .foregroundColor(isDestructive ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isDestructive ? Color.red : styles.colors.accent)
                            .cornerRadius(styles.layout.radiusM)
                    }
                    
                    // Cancel button
                    Button(action: {
                        cancelAction()
                    }) {
                        Text(cancelText)
                            .font(styles.typography.bodyFont)
                            .foregroundColor(styles.colors.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(styles.colors.secondaryBackground)
                            .cornerRadius(styles.layout.radiusM)
                    }
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(styles.colors.cardBackground)
            .cornerRadius(styles.layout.radiusL)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

