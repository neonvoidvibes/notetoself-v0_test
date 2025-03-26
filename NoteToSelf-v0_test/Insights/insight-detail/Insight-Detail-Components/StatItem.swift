import SwiftUI

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    var color: Color? = nil
    private let styles = UIStyles.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color ?? styles.colors.accent)
                .font(.system(size: 24))
            
            Text(value)
                .font(styles.typography.bodyLarge)
                .foregroundColor(styles.colors.text)
            
            Text(label)
                .font(styles.typography.caption)
                .foregroundColor(styles.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

