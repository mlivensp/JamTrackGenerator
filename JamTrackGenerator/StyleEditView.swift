import SwiftUI
import SwiftData

struct StyleEditView: View {
    @Environment(\.modelContext) var modelContext
    @Binding var navPath: NavigationPath
    @State private var viewModel: ViewModel
    @State private var showingDiscardAlert = false // New state for the alert
    
    init(style: Style, navPath: Binding<NavigationPath>) {
        self._viewModel = .init(wrappedValue: .init(style: style))
        self._navPath = navPath
    }
    
    var body: some View {
        Form {
            Section(header: Text("Style Info")) {
                TextField("Name", text: $viewModel.name)
            }
            
            Section(header: Text("Drum Patterns")) {
                if viewModel.drumPatterns.isEmpty {
                    Text("No drum patterns")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.drumPatterns) { pattern in
                        Text(pattern.name)
                    }
                }
            }
            
            Section(header: Text("Harmonic Patterns")) {
                if viewModel.harmonicPatterns.isEmpty {
                    Text("No harmonic patterns")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.harmonicPatterns) { pattern in
                        Text(pattern.name)
                    }
                }
            }
            
            Section(header: Text("JamTrack Definitions")) {
                if viewModel.jamTracks.isEmpty {
                    Text("No jam tracks")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.jamTracks) { track in
                        Text(track.name)
                    }
                }
            }
            
            //            Section {
            //                Button(role: .destructive) {
            //                    showAlert = true
            //                } label: {
            //                    Label("Delete Style", systemImage: "trash")
            //                }
            //            }
        }
        .navigationTitle(viewModel.name.isEmpty ? "New Style" : viewModel.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        // 1. **Crucial:** Hide the native back button
//        .navigationBarBackButtonHidden(true)
#if os(iOS)
.navigationBarBackButtonHidden(UIDevice.current.userInterfaceIdiom == .phone)
#endif
        // 2. Disable the interactive dismissal (swipe gesture) if there are unsaved changes
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
        
        // 3. Override the back button with custom logic
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    // Custom logic for the back action
                    if viewModel.hasUnsavedChanges {
                        showingDiscardAlert = true // Show prompt if unsaved changes exist
                    } else {
                        navPath.removeLast() // Go back immediately
                    }
                } label: {
                    // Use a system icon that looks like the native back button
                    Image(systemName: "chevron.backward")
                        .accessibilityLabel("Back")
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.save(modelContext: modelContext)
                    navPath.removeLast() // Go back after saving
                }
                .disabled(!viewModel.hasUnsavedChanges)
            }
        }
        
        // 4. Alert to prompt the user to discard changes
        .alert("Discard changes?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                // Discard changes (by not saving them) and navigate back
                navPath.removeLast()
            }
            Button("Cancel", role: .cancel) {} // Stay on the view
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        //         .toolbar {
        //             ToolbarItem(placement: .navigationBarLeading) {
        //                 Button("Back") {
        //                     if viewModel.hasUnsavedChanges {
        //                         showAlert = true
        //                     } else {
        //                         navPath.removeLast()
        //                     }
        //                 }
        //             }
        //         }
        //         .alert("Discard changes?", isPresented: $showAlert) {
        //             Button("Discard", role: .destructive) {
        //                 viewModel.reset()
        //                 navPath.removeLast()
        //             }
        //             Button("Cancel", role: .cancel) {}
        //         }
    }
}

#Preview {
    @Previewable @State var navPath: NavigationPath = NavigationPath()
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: JamTrack.self, configurations: config)
    
    let style = Style(name: "Test Style")
    
    StyleEditView(style: style, navPath: $navPath)
        .modelContainer(container)
}
