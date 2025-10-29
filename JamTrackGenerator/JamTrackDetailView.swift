import SwiftUI
import SwiftData

struct JamTrackDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var navManager: NavigationStateManager
    
    @Query var keys: [Key]
    @Query var styles: [Style]
    @Query var feels: [Feel]
    
    /// Source-of-truth binding to the live model instance (provided by ContentView)
    @Binding var jamTrack: JamTrack
    
    /// Local editable draft
    @State private var viewModel: ViewModel
    
#if canImport(UIKit)
    let systemSeparator = Color(UIColor.separator)
#else
    let systemSeparator = Color(NSColor.separatorColor)
#endif
    
    init(jamTrack: Binding<JamTrack>) {
        self._jamTrack = jamTrack
        self.viewModel = .init(jamTrack: jamTrack.wrappedValue)
    }
    
    var body: some View {
        Section("Track Info") {
            keyFeelTempo
        }
        
        JamTrackMatrixView(viewModel: viewModel)
            .border(systemSeparator, width: 1)
        PlaybackControlsView(size: .large, createURL: viewModel.createURL)
        
            .navigationTitle(viewModel.name.isEmpty ? "Untitled Jam Track" : viewModel.name)
            .onAppear {
                viewModel.modelContext = self.modelContext
                viewModel.navManager = self.navManager
            }
            .toolbar {
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
            .onChange(of: jamTrack) {
                // If the bound model instance changed underneath us, reset draft and clear dirty
                viewModel = .init(jamTrack: jamTrack)
                viewModel.navManager = self.navManager
                navManager.isDirty = false
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
                Picker("", selection: $viewModel.key) {
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
                Picker("", selection: $viewModel.style) {
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
                Picker("", selection: $viewModel.feel) {
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
    
    // MARK: - Helpers
}
