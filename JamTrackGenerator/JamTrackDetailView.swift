//
//  JamTrackDetailView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/30/25.
//

import SwiftData
import SwiftUI


// usage:
struct JamTrackDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var jamTrack: JamTrack
    @State private var viewModel: ViewModel
    @State private var export = false
    @State private var midiDocument: MidiDocument?
    @State private var showAlert: Bool = false
    
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
        self._viewModel = .init(wrappedValue: .init(jamTrack: jamTrack))
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
                Button(action: {
//                    do {
                        viewModel.save(modelContext: modelContext)
//                        try modelContext.save()
//                    } catch {
//                        viewModel.errorMessage = "Failed to save: \(error.localizedDescription)"
//                    }
                }) {
                    Label("Save", systemImage: "tray.and.arrow.down")
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel, action: viewModel.reset) {
                    Label("Cancel", systemImage: "xmark.circle")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button(role: .destructive) {
                        //                            confirmDelete()
                        modelContext.delete(jamTrack)
                        do {
                            try modelContext.save()
                        } catch {
                            viewModel.errorMessage = "Failed to delete: \(error.localizedDescription)"
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button(action: {
                        midiDocument = viewModel.createMidiDocument(modelContext: modelContext)
                        export = true
                    }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        } .onAppear {
            viewModel.modelContext = modelContext
        } .fileExporter(
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
    }
    
    private var keyFeelTempo: some View {
#if os(macOS)
        VStack(spacing: 0) {
            HStack {
                LabeledContent {
                    TextField("", text: $viewModel.name)
                }
                label: { Text("Name") }
                
                LabeledContent {
                    Picker("", selection: $viewModel.key) {
                        ForEach(keys) { key in
                            Text(key.noteName).tag(key)
                        }
                    }
                }
                label: { Text("Key") }
            }
            
            HStack {
                LabeledContent {
                    Picker("", selection: $viewModel.feel) {
                        ForEach(feels, id: \.self) { feel in
                            Text(feel.name).tag(feel)
                        }
                    }
                }
                label: { Text("Feel") }
                
                Picker("BPM", selection: $viewModel.bpm) {
                    ForEach(45...180, id: \.self) { value in
                        Text("\(value)").tag(UInt8(value))
                    }
                }
                
                Spacer()
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
#else
        VStack(spacing: 0) {
            LabeledContent {
                TextField("", text: $viewModel.name)
            }
            label: { Text("Name") }
            
            LabeledContent {
                Picker("", selection: $viewModel.key) {
                    ForEach(keys) { key in
                        Text(key.noteName).tag(key)
                    }
                }
            }
            label: { Text("Key") }
            
            LabeledContent {
                Picker("", selection: $viewModel.feel) {
                    ForEach(feels, id: \.self) { feel in
                        Text(feel.name).tag(feel)
                    }
                }
            }
            label: { Text("Feel") }
            
            LabeledContent {
                Picker("BPM", selection: $viewModel.bpm) {
                    ForEach(UInt8(45)...UInt8(180), id: \.self) { value in
                        Text("\(value)").tag(UInt8(value))
                    }
                }
            }
            label: { Text("BPM") }
            
            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        // TODO: this isn't working
        .navigationGuard {
            if viewModel.hasUnsavedChanges {
                showAlert = true
                return false
            }
            return true
        }
        .alert("Discard changes?", isPresented: $showAlert) {
            Button("Discard", role: .destructive) {
                viewModel.reset()
                // Optionally trigger manual pop
            }
            Button("Cancel", role: .cancel) {}
        }
#endif
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func fetchModelContext() -> ModelContext {
        modelContext
    }
    
    //    private func buildMidiDocument() -> MidiDocument? {
    //        return jamTrack.createMidiDocument(modelContext: modelContext)
    //    }
}

//#Preview {
//    JamTrackDetailView()
//}
