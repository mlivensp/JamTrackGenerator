//
//  BackInterceptionView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 10/22/25.
//

import SwiftUI

import SwiftUI

/// A wrapper that intercepts back navigation in a NavigationStack and optionally cancels it.
struct BackInterceptionView<Content: View, Value: Hashable>: View {
    @Binding var path: NavigationPath
    let value: Value
    let hasUnsavedChanges: () -> Bool
    let onDiscardConfirmed: () -> Void
    let content: () -> Content

    @State private var showAlert = false
    @State private var isPopping = false

    var body: some View {
        content()
            .onDisappear {
                // Only intercept if user is navigating back (not programmatically popping)
                if !isPopping && hasUnsavedChanges() {
                    showAlert = true
                    DispatchQueue.main.async {
                        path.append(value) // Re-push to cancel the pop
                    }
                }
            }
            .alert("Discard changes?", isPresented: $showAlert) {
                Button("Discard", role: .destructive) {
                    onDiscardConfirmed()
                    isPopping = true
                    path.removeLast()
                }
                Button("Cancel", role: .cancel) {}
            }
    }
}

//#Preview {
//    BackInterceptionView()
//}
