import Foundation
import SwiftUI
import Combine // Import Combine for observing AppStorage changes

// Basic Subscription Manager (Stub Implementation)
// In a real app, this would interact with StoreKit and persist state securely.
@MainActor // Ensure published property updates happen on the main thread
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // Use a private key for AppStorage
    private let subscriptionKey = "isUserSubscribed_NoteToSelf_v2" // Use a distinct key

    // Private @AppStorage variable to handle persistence
    @AppStorage(wrappedValue: false, "isUserSubscribed_NoteToSelf_v2") private var _persistedIsUserSubscribed: Bool

    // Public @Published variable for SwiftUI views to observe
    @Published var isUserSubscribed: Bool = false

    private var cancellable: AnyCancellable?

    private init() {
        // Initialize the @Published var with the current persisted value
        self.isUserSubscribed = _persistedIsUserSubscribed
        print("SubscriptionManager initialized. Persisted state: \(_persistedIsUserSubscribed). Published state: \(isUserSubscribed)")

        // Observe changes to the @AppStorage variable
        // We need to observe the projected value ($) of the AppStorage property wrapper
        // Note: Direct observation of @AppStorage within ObservableObject can be tricky.
        // A common pattern is to use UserDefaults directly or a publisher if available.
        // Let's try observing the UserDefaults key directly for robustness.
        cancellable = UserDefaults.standard.publisher(for: \.isUserSubscribed_NoteToSelf_v2) // Requires defining the key path extension below
            .sink { [weak self] newValue in
                guard let self = self else { return }
                // Ensure the @Published var reflects the persisted value
                if self.isUserSubscribed != newValue {
                    print("Detected change in persisted subscription status: \(newValue)")
                    self.isUserSubscribed = newValue
                }
            }
    }

    // --- Stub Functions ---
    // Replace these with actual StoreKit logic in production

    func subscribeMonthly() {
        print("Attempting to subscribe (stub)...")
        updateSubscriptionStatus(to: true)
        print("Subscription successful (stub). User is now Pro.") // Updated text
    }

    func restorePurchase() {
        print("Attempting to restore purchases (stub)...")
        updateSubscriptionStatus(to: true) // Assume success for stub
        print("Purchases restored (stub). User is now Pro.") // Updated text
    }

    // --- Debug Function ---
    func unsubscribeDebug() {
        #if DEBUG
        print("Debug: Unsubscribing user...")
        updateSubscriptionStatus(to: false)
        print("User unsubscribed (debug).")
        #else
        print("Warning: Unsubscribe debug function called in release build. No action taken.")
        #endif
    }

    // --- Helper to update state and persist ---
    private func updateSubscriptionStatus(to subscribed: Bool) {
        // Update the AppStorage value, which will trigger the publisher
        _persistedIsUserSubscribed = subscribed
        // The sink observer should automatically update the @Published var 'isUserSubscribed'
        print("Subscription status updated in AppStorage to: \(subscribed)")
        // Manually update if sink doesn't fire immediately (though it should)
        if isUserSubscribed != subscribed {
             isUserSubscribed = subscribed
        }
    }
}

// Extension to make the UserDefaults key observable via KeyPath
// Place this outside the SubscriptionManager class, but in the same file or a shared location.
extension UserDefaults {
    @objc dynamic var isUserSubscribed_NoteToSelf_v2: Bool {
        return bool(forKey: "isUserSubscribed_NoteToSelf_v2")
    }
}