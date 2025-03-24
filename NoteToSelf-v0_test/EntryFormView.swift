import SwiftUI

// Shared component for both new entries and editing existing entries
struct EntryFormView<Content: View>: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let onSave: () -> Void
    let saveButtonEnabled: Bool
    let content: () -> Content
    
    // Access shared styles
    private let styles = UIStyles.shared
    
    init(title: String, onSave: @escaping () -> Void, saveButtonEnabled: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.onSave = onSave
        self.saveButtonEnabled = saveButtonEnabled
        self.content = content
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                styles.colors.appBackground
                    .ignoresSafeArea()
                
                // Content area
                VStack(spacing: styles.layout.spacingM) {
                    content()
                    Spacer()
                }
                .padding(styles.layout.paddingXL)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            // Custom navigation bar with optimized top spacing
            .safeAreaInset(edge: .top) {
                VStack(spacing: 0) {
                    // Set spacing to a value between original and doubled (36 points)
                    Spacer().frame(height: 36)
                    
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(styles.colors.accent)
                        
                        Spacer()
                        
                        Text(title)
                            .font(styles.typography.title3)
                            .foregroundColor(styles.colors.text)
                        
                        Spacer()
                        
                        Button("Save") {
                            onSave()
                        }
                        .foregroundColor(styles.colors.accent)
                        .disabled(!saveButtonEnabled)
                        .opacity(saveButtonEnabled ? 1.0 : 0.5)
                    }
                    .padding(.horizontal, styles.layout.paddingL)
                    .padding(.bottom, 12)
                }
                .background(styles.colors.appBackground)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .preferredColorScheme(.dark)
        // Apply consistent presentation detents to make it universal
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
    }
}