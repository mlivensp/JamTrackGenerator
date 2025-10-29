import SwiftUI

// MARK: - Navigation State Manager

class NavigationStateManager: ObservableObject {
    /// True if any detail view has unsaved changes
    @Published var isDirty: Bool = false
    
    /// The alert toggle
    @Published var showingUnsavedAlert: Bool = false
    
    /// A closure holding the navigation action (e.g., changing selection)
    /// that was interrupted by the alert.
    private var pendingNavigation: (() -> Void)? = nil
    
    /// Call this to request a navigation change.
    /// It will either run the action immediately or show an alert.
    func requestNavigation(action: @escaping () -> Void) {
        if isDirty {
            // We have unsaved changes. Store the action and show the alert.
            self.pendingNavigation = action
            self.showingUnsavedAlert = true
        } else {
            // No unsaved changes, proceed immediately.
            action()
        }
    }
    
    /// Call this if the user clicks "Discard" in the alert.
    func discardChangesAndNavigate() {
        isDirty = false // Reset the flag
        pendingNavigation?() // Run the stored action
        pendingNavigation = nil // Clear the action
    }
    
    /// Call this if the user clicks "Cancel".
    func cancelNavigation() {
        pendingNavigation = nil // Clear the action
    }
}
