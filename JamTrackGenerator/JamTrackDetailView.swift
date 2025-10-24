import SwiftData
import SwiftUI

struct JamTrackDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var jamTrack: JamTrack
    
    // Use @State (not @StateObject) because ViewModel uses @Observable
    @State private var viewModel: ViewModel
    
    @State private var export = false
    @State private var midiDocument: MidiDocument?
    @State private var showUnsavedChangesAlert = false
    @State private var pendingNavigation: (() -> Void)?
    
    @Query var keys: [Key]
    @Query var feels: [Feel]
    @Query private var instrumentFamilies: [InstrumentFamily]
    @Query var instruments: [Instrument]
    @Query var songSections: [SongSection]
    
    @State private var selectedFamily: InstrumentFamily?
    @State private var selectedInstrument: Instrument?
    
#if canImport(UIKit)
    let systemSeparator = Color(UIColor.separator)
#else
    let systemSeparator = Color(NSColor.separatorColor)
#endif
    
    init(jamTrack: JamTrack) {
        self.jamTrack = jamTrack
        self._viewModel = State(wrappedValue: ViewModel(jamTrack: jamTrack))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            keyFeelTempo
                .fixedSize(horizontal: false, vertical: true)
                .alignmentGuide(.top) { _ in 0 }
                .padding()
            
            JamTrackMatrixView(viewModel: viewModel)
                .border(systemSeparator, width: 1)
            
            PlaybackControlsView(size: .large, createURL: viewModel.createURL)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.save(modelContext: modelContext)
                }
                .keyboardShortcut(.defaultAction)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    attemptNavigation { dismiss() }
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button("Delete", role: .destructive) {
                        attemptNavigation {
                            modelContext.delete(jamTrack)
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                    
                    Button("Export") {
                        midiDocument = viewModel.createMidiDocument(modelContext: modelContext)
                        export = true
                    }
                    
                    Button("Reset Changes") {
                        attemptNavigation {
                            viewModel.reset()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
        }
        .fileExporter(
            isPresented: $export,
            document: midiDocument,
            contentType: .midi
        ) { result in
            switch result {
            case .success(let url):
                print("Exported to \(url)")
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
            Button("Discard", role: .destructive) {
                viewModel.reset()
                pendingNavigation?()
                pendingNavigation = nil
            }
            Button("Keep Editing", role: .cancel) {
                pendingNavigation = nil
            }
        } message: {
            Text("You have unsaved changes. Do you want to discard them or keep editing?")
        }
        // Handle split view selection change (macOS/iPad)
        .onChange(of: jamTrack) { oldJamTrack, newJamTrack in
            guard oldJamTrack !== newJamTrack else { return }
            
            if viewModel.hasUnsavedChanges {
                showUnsavedChangesAlert = true
                pendingNavigation = {
                    // Recreate ViewModel with the *new* JamTrack
                    viewModel = ViewModel(jamTrack: newJamTrack)
                    viewModel.modelContext = modelContext
                }
            } else {
                // No unsaved changes → switch immediately
                viewModel = ViewModel(jamTrack: newJamTrack)
                viewModel.modelContext = modelContext
            }
        }
    }
    
    // Helper: Centralize navigation attempts
    private func attemptNavigation(_ action: @escaping () -> Void) {
        if viewModel.hasUnsavedChanges {
            pendingNavigation = action
            showUnsavedChangesAlert = true
        } else {
            action()
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
}
