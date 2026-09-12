//
//  NavigationGuard.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 10/19/25.
//

import SwiftUI

#if !os(macOS)
struct NavigationGuard: UIViewControllerRepresentable {
    var canNavigateBack: () -> Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = GuardingController()
        controller.canNavigateBack = canNavigateBack
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class GuardingController: UIViewController, UINavigationControllerDelegate {
    var canNavigateBack: () -> Bool = { true }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.delegate = self
    }

    func navigationController(_ navigationController: UINavigationController,
                              shouldPop viewController: UIViewController) -> Bool {
        return canNavigateBack()
    }
}

extension View {
    func navigationGuard(_ canNavigateBack: @escaping () -> Bool) -> some View {
        self.background(NavigationGuard(canNavigateBack: canNavigateBack))
    }

    @ViewBuilder func navigationGuardIfPhone(_ canNavigateBack: @escaping () -> Bool) -> some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.navigationGuard(canNavigateBack)
        } else {
            self
        }
#else
        self
#endif
    }
}#endif
// Usage Example

//struct DetailView: View {
//    @State private var hasUnsavedChanges = true
//    @State private var showAlert = false
//
//    var body: some View {
//        VStack {
//            Text("Editing something important...")
//        }
//        .navigationGuard {
//            if hasUnsavedChanges {
//                showAlert = true
//                return false
//            }
//            return true
//        }
//        .alert("Discard changes?", isPresented: $showAlert) {
//            Button("Discard", role: .destructive) {
//                hasUnsavedChanges = false
//                // Optionally trigger manual pop
//            }
//            Button("Cancel", role: .cancel) {}
//        }
//    }
//}
