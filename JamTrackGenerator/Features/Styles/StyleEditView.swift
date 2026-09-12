import SwiftUI
import SwiftData

struct StyleEditView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var navManager: NavigationStateManager
    
    @Binding var navPath: NavigationPath
    @State private var viewModel: ViewModel
    
    @Binding var style: Style
    
    init(style: Binding<Style>, navPath: Binding<NavigationPath>) {
        self._style = style
        self._navPath = navPath
        self.viewModel = .init(style: style.wrappedValue)
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
        }
        .navigationTitle(viewModel.name.isEmpty ? "New Style" : viewModel.name)
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
        .onChange(of: style) {
            // If the bound model instance changed underneath us, reset draft and clear dirty
            viewModel = .init(style: style)
            viewModel.navManager = self.navManager
            navManager.isDirty = false
        }
        .onDisappear {
            // Ensure global dirty state is cleared when editor is removed
            navManager.isDirty = false
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Style.self, configurations: config)
    
    let style = Style(name: "Preview Style")
    container.mainContext.insert(style)
    
    return StyleEditView(style: .constant(style), navPath: .constant(NavigationPath()))
        .modelContainer(container)
        .environmentObject(NavigationStateManager())
}
