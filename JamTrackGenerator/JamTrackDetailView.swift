//
//  JamTrackDetailView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/30/25.
//

import SwiftData
import SwiftUI

struct JamTrackDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var jamTrack: JamTrack
    @State private var viewModel: ViewModel
    @State private var export = false
    @State private var midiDocument: MidiDocument?

    @Query var keys: [Key]
    @Query var feels: [Feel]
    @Query private var instrumentFamilies: [InstrumentFamily]
    @Query var instruments: [Instrument]
    @Query var songSections: [SongSection]

    @State private var selectedFamily: InstrumentFamily?
    @State private var selectedInstrument: Instrument?

    
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
            
            PlaybackControlsView(size: .large, createURL: viewModel.createURL)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    do {
                        try modelContext.save()
                    } catch {
                        viewModel.errorMessage = "Failed to save: \(error.localizedDescription)"
                    }
                }) {
                    Label("Save", systemImage: "tray.and.arrow.down")
                }

                Button(role: .destructive, action: {
                    modelContext.delete(jamTrack)
                    do {
                        try modelContext.save()
                    } catch {
                        viewModel.errorMessage = "Failed to delete: \(error.localizedDescription)"
                    }
                }) {
                    Label("Delete", systemImage: "trash")
                }

                Button(action: {
                    midiDocument = viewModel.createMidiDocument(modelContext: modelContext)
                    export = true
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                
                Button(action: viewModel.dumpSectionParts) {
                    Label("Dump", systemImage: "arrow.2.circlepath.circle")
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
        HStack {
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
                    let formatter: NumberFormatter = {
                        let f = NumberFormatter()
                        f.numberStyle = .none
                        f.minimum = 0
                        f.maximum = 255
                        f.allowsFloats = false
                        return f
                    }()
                    
                    TextField("", value: $viewModel.bpm, formatter: formatter)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
                label: { Text("BPM") }
                
            }
            .padding()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        
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
