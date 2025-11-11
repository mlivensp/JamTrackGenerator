import SwiftUI
import SwiftData

struct FeelEditView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var navManager: NavigationStateManager
    
    @Binding var navPath: NavigationPath
    @State private var viewModel: ViewModel
    
    @Binding var feel: Feel
    
    init(feel: Binding<Feel>, navPath: Binding<NavigationPath>) {
        self._feel = feel
        self._navPath = navPath
        self.viewModel = .init(feel: feel.wrappedValue)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Feel Info")) {
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
        }
        .navigationTitle(viewModel.name.isEmpty ? "New Feel" : viewModel.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
        .onAppear {
            viewModel.modelContext = self.modelContext
            viewModel.navManager = self.navManager
        }
#if os(iOS)
        .navigationBarBackButtonHidden(true)
#endif
        .toolbar {
            // Check if we are likely in a NavigationStack (i.e., not a wide master-detail layout).
            // `horizontalSizeClass == .compact` is generally true on iPhone and half-screen iPads,
            // which usually means we are pushed in a stack and need a back button.
            if horizontalSizeClass == .compact {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        navManager.requestNavigation {
                            navPath.removeLast() // Go back
                        }
                    } label: {
                        // Use a system icon that looks like the native back button
                        Image(systemName: "chevron.backward")
                            .accessibilityLabel("Back")
                    }
                }
            }
            
            ToolbarItemGroup {
                Button("Revert") {
                    viewModel.reset()
                }
                .disabled(!viewModel.hasUnsavedChanges)
                
                Button("Save") {
                    viewModel.save(modelContext: self.modelContext)
                }
                .disabled(!viewModel.hasUnsavedChanges)
            }
        }
        .onChange(of: feel) {
            // If the bound model instance changed underneath us, reset draft and clear dirty
            viewModel = .init(feel: feel)
            viewModel.navManager = self.navManager
            navManager.isDirty = false
        }
        .onDisappear {
            // Ensure global dirty state is cleared when editor is removed
            navManager.isDirty = false
        }
    }
}

//#Preview {
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: Feel.self, configurations: config)
//    
//    let feel = Feel(name: "Preview Feel")
//    container.mainContext.insert(feel)
//    
//    return FeelEditView(style: .constant(feel), navPath: .constant(NavigationPath()))
//        .modelContainer(container)
//        .environmentObject(NavigationStateManager())
//}
