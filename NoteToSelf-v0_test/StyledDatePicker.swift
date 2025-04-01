import SwiftUI

/// A reusable DatePicker styled to match the Settings reminder time picker.
/// Displays the selected date/time using the user's system format, with accent color and a chevron.
/// Tapping the view presents the appropriate DatePicker style in a sheet.
struct StyledDatePicker: View {
    @Binding var selection: Date
    var displayedComponents: DatePickerComponents = .date // Default to date only

    @State private var showPickerSheet: Bool = false
    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    var body: some View {
        Button {
            showPickerSheet = true
        } label: {
            // The visible part of the component
            HStack(spacing: 4) {
                Text(formattedDate)
                    .font(styles.typography.bodyFont)
                    .foregroundColor(styles.colors.accent)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(styles.colors.textSecondary)

                Spacer() // Push content to the left
            }
            .padding(.horizontal, 8) // Add padding to mimic default picker padding
            .frame(height: 30) // Maintain a consistent height
            .contentShape(Rectangle()) // Define the tappable area
        }
        .buttonStyle(.plain) // Use plain button style to avoid default button appearance
        .sheet(isPresented: $showPickerSheet) {
            DatePickerSheetView(
                selection: $selection,
                displayedComponents: displayedComponents,
                showPickerSheet: $showPickerSheet
            )
            // Sensible detents based on content
            .presentationDetents(displayedComponents == .hourAndMinute ? [.height(250)] : [.medium, .large])
            .presentationDragIndicator(.visible) // Show drag indicator
        }
    }

    // Computed property to format the date based on displayedComponents
    private var formattedDate: String {
        let showsDate = displayedComponents._contains(.date)
        let showsTime = displayedComponents._contains(.hourAndMinute)

        if showsDate && showsTime {
            return selection.formatted(date: .abbreviated, time: .shortened)
        } else if showsDate {
            return selection.formatted(date: .abbreviated, time: .omitted)
        } else if showsTime {
            return selection.formatted(date: .omitted, time: .shortened)
        } else {
            return selection.formatted()
        }
    }
}

// Separate view for the sheet content
private struct DatePickerSheetView: View {
    @Binding var selection: Date
    let displayedComponents: DatePickerComponents
    @Binding var showPickerSheet: Bool // To dismiss the sheet

    @ObservedObject private var styles = UIStyles.shared // Use @ObservedObject

    var body: some View {
        NavigationView { // Embed in NavigationView for title and Done button
            VStack {
                // Use GraphicalDatePickerStyle for dates, WheelDatePickerStyle for time
                if displayedComponents == .hourAndMinute {
                    DatePicker("", selection: $selection, displayedComponents: displayedComponents)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                } else {
                     DatePicker("", selection: $selection, displayedComponents: displayedComponents)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding()
                }

                Spacer() // Push picker to top
            }
            .background(styles.colors.menuBackground.ignoresSafeArea()) // Consistent background
            .navigationTitle(displayedComponents == .hourAndMinute ? "Select Time" : "Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showPickerSheet = false
                    }
                    .foregroundColor(styles.colors.accent)
                }
             }
         }
         // .preferredColorScheme(.dark) // REMOVED
     }
 }


// Corrected Extension to check DatePickerComponents easily
extension DatePickerComponents {
    func _contains(_ component: DatePickerComponents) -> Bool {
        // DatePickerComponents conforms to OptionSet, which has a 'contains' method.
        return self.contains(component)
    }
}


#Preview {
    VStack(alignment: .leading, spacing: 20) {
        Text("Date Only:")
        StyledDatePicker(selection: .constant(Date()), displayedComponents: .date)
            .background(Color.gray.opacity(0.2)) // Add background for preview clarity

        Text("Time Only:")
        StyledDatePicker(selection: .constant(Date()), displayedComponents: .hourAndMinute)
            .background(Color.gray.opacity(0.2))

        Text("Date and Time:")
        StyledDatePicker(selection: .constant(Date()), displayedComponents: [.date, .hourAndMinute])
            .background(Color.gray.opacity(0.2))

        Spacer()
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
    .foregroundColor(.white)
}