import SwiftUI
import SwiftData

struct JamTrackDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var navManager: NavigationStateManager
    
    @Query var keys: [Key]
    @Query var styles: [Style]
    @Query var feels: [Feel]
    
    @Binding var navPath: NavigationPath
    let jamTrack: JamTrack
    
    /// Local editable draft
    @State private var viewModel: ViewModel
    @State private var isShowingError = false
    
#if canImport(UIKit)
    let systemSeparator = Color(UIColor.separator)
#else
    let systemSeparator = Color(NSColor.separatorColor)
#endif
    
    init(jamTrack: JamTrack, navPath: Binding<NavigationPath>) {
        self.jamTrack = jamTrack
        self._navPath = navPath
        self.viewModel = .init(jamTrack: jamTrack)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            keyFeelTempo
            
            JamTrackMatrixView(viewModel: viewModel)
                .frame(maxHeight: .infinity)
                .layoutPriority(1)
                .border(systemSeparator, width: 1)
            PlaybackControlsView(
                size: .large,
                isPlayDisabled: viewModel.isSavingAndCreatingExportURL
            ) {
                viewModel.saveAndCreateExportURL(modelContext: modelContext)
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
        .onAppear {
            navManager.isDirty = viewModel.hasUnsavedChanges
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
                .disabled(!viewModel.hasUnsavedChanges || viewModel.isSavingAndCreatingExportURL)
                
                Button("Save") {
                    viewModel.save(modelContext: self.modelContext)
                }
                .disabled(!viewModel.hasUnsavedChanges || viewModel.isSavingAndCreatingExportURL)
            }
        }
        .alert("Save or Export Failed", isPresented: $isShowingError) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: jamTrack.id) {
            // If the persistent model instance changed underneath us, reset draft and clear dirty
            viewModel = .init(jamTrack: jamTrack)
            navManager.isDirty = false
        }
        .onChange(of: viewModel.hasUnsavedChanges) { _, hasUnsavedChanges in
            navManager.isDirty = hasUnsavedChanges
        }
        .onChange(of: viewModel.errorMessage) { _, errorMessage in
            isShowingError = errorMessage != nil
        }
        .onDisappear {
            // Ensure global dirty state is cleared when editor is removed
            navManager.isDirty = false
        }
    }
    
    private var keyFeelTempo: some View {
        VStack(spacing: 0) {
            LabeledContent("Name") {
                TextField("Jam Track Name", text: $viewModel.name)
            }
            
            LabeledContent("Key") {
                Picker("", selection: keyBinding) {
                    Text("Select Key").tag(nil as Key?)
                    ForEach(keys) { key in
                        Text(key.noteName).tag(key as Key?)
                    }
                }
                .pickerStyle(.menu)               // works everywhere
#if os(iOS)
                .pickerStyle(.wheel)              // iOS-only wheel
#endif
            }
            
            LabeledContent("Style") {
                Picker("", selection: styleBinding) {
                    Text("Select Style").tag(nil as Style?)
                    ForEach(styles, id: \.self) { style in
                        Text(style.name).tag(style as Style?)
                    }
                }
                .pickerStyle(.menu)
#if os(iOS)
                .pickerStyle(.wheel)
#endif
            }
            
            LabeledContent("Feel") {
                Picker("", selection: feelBinding) {
                    Text("Select Feel").tag(nil as Feel?)
                    ForEach(feels, id: \.self) { feel in
                        Text(feel.name).tag(feel as Feel?)
                    }
                }
                .pickerStyle(.menu)
#if os(iOS)
                .pickerStyle(.wheel)
#endif
            }
            
            LabeledContent("BPM") {
                Picker("BPM", selection: $viewModel.bpm) {
                    ForEach(UInt8(45)...UInt8(180), id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.menu)
#if os(iOS)
                .pickerStyle(.wheel)
#endif
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }

    private var keyBinding: Binding<Key?> {
        Binding(
            get: { keys.first { $0.persistentModelID == viewModel.draft.keyID } },
            set: { viewModel.setKey($0?.persistentModelID) }
        )
    }

    private var styleBinding: Binding<Style?> {
        Binding(
            get: { styles.first { $0.persistentModelID == viewModel.draft.styleID } },
            set: { viewModel.setStyle($0?.persistentModelID) }
        )
    }

    private var feelBinding: Binding<Feel?> {
        Binding(
            get: { feels.first { $0.persistentModelID == viewModel.draft.feelID } },
            set: { viewModel.setFeel($0?.persistentModelID) }
        )
    }
}
