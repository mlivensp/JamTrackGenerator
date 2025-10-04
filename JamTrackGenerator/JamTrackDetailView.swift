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
    @State private var playIsPressed = false
    @State private var stopIsPressed = false
    @State private var loopIsPressed = false

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

            JamTrackMatrixView(jamTrack: jamTrack)
            
            PlaybackControlsView(viewModel: viewModel)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    midiDocument = buildMidiDocument()
                    export = true
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
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
    }
    
    private var keyFeelTempo: some View {
        HStack {
            VStack(spacing: 0) {
                LabeledContent {
                    TextField("", text: $jamTrack.name)
                }
                label: { Text("Name") }

                LabeledContent {
                    Picker("", selection: $jamTrack.key) {
                        ForEach(keys) { key in
                            Text(key.noteName).tag(key)
                        }
                    }
                }
                label: { Text("Key") }
                
                LabeledContent {
                    Picker("", selection: $jamTrack.feel) {
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
                    TextField("", value: $jamTrack.bpm, formatter: formatter)
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
    
    private func buildMidiDocument() -> MidiDocument? {
        return jamTrack.createMidiDocument(modelContext: modelContext)
    }
}

//#Preview {
//    JamTrackDetailView()
//}
