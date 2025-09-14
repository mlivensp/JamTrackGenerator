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
    @Query var instruments: [Instrument]
    @Query var songSections: [SongSection]
    
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
            GeometryReader { geo in
                ScrollView {
                    sections
                        .frame(height: geo.size.height / 2)
                    parts
                        .frame(height: geo.size.height / 2)
                }
            }
            
            playbackControls
            
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
                    Picker("Key", selection: $jamTrack.key) {
                        ForEach(keys) { key in
                            Text(key.name).tag(key)
                        }
                    }
                }
                label: { Text("Key") }
                
                LabeledContent {
                    Picker("Feel", selection: $jamTrack.feel) {
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
                    TextField("BPM", value: $jamTrack.bpm, formatter: formatter)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
                label: { Text("BPM") }
                
            }
            .padding()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        
    }
    
    private var sections: some View {
        VStack(spacing: 0) {
            SwiftUI.Section(header: Text("Song Sections")) {
                HStack {
                    List(selection: $viewModel.selectedSection) {
                        ForEach(jamTrack.sections) { section in
                            NavigationLink {
                                EditSectionView(section: Binding(
                                    get: { section },
                                    set: { _ in return }
                                ))
                            }
                            label: {
                                Text(section.songSection?.name ?? "Unknown")
                            }
                        }
                    }
                    
                    VStack {
                        Spacer()
                        Picker("", selection: $viewModel.selectedSongSection) {
                            ForEach(songSections) { section in
                                Text(section.name).tag(section)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Spacer()
                        Button("Add Section") {
                            let _ = jamTrack.addSection(songSection: viewModel.selectedSongSection!)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var parts: some View {
        VStack(spacing: 0) {
            SwiftUI.Section(header: Text("Parts")) {
                HStack {
                    List(selection: $viewModel.selectedPart) {
                        ForEach(jamTrack.parts) { part in
                            NavigationLink {
                                EditPartView(part: Binding(
                                    get: { part },
                                    set: { _ in return }
                                ))
                            }
                            label: {
                                Text(part.instrument?.name ?? "<< unknown >>")
                            }
                        }
                    }
                    
                    VStack {
                        Spacer()
                        Picker("", selection: $viewModel.selectedMidiInstrument) {
                            ForEach(instruments) { instrument in
                                Text(instrument.name).tag(instrument)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Spacer()
                        Button("Add Part") {
                            if let selectedMidiInstrument = viewModel.selectedMidiInstrument {
                                let _ = jamTrack.addPart(instrument: selectedMidiInstrument)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var playbackControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                Spacer()
                
                // Play/Pause button
                Button(action: togglePlayback) {
                    Image(systemName: playButtonIcon)
                        .font(.title)
                        .frame(width: 50, height: 50)
//                        .background(Color.blue)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                }
                
                // Stop button
                Button(action: { viewModel.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
                .disabled(viewModel.midiPlayer?.playbackState == .stopped)
                
                Spacer(minLength: 0)
                HStack {
                    // Loop toggle
                    Button(action: { viewModel.midiPlayer?.isLooping.toggle() }) {
                        Image(systemName: viewModel.midiPlayer?.isLooping ?? false ? "repeat.1" : "repeat")
                            .font(.title3)
                            .foregroundColor(viewModel.midiPlayer?.isLooping ?? false ? .blue : .gray)
                    }
                }
                .padding()
            }
            
            // Progress bar
            //            VStack(spacing: 8) {
            //                if let midiPlayer = viewModel.midiPlayer {
            //                    ProgressView(value: midiPlayer.currentPosition,
            //                                 total: midiPlayer.totalDuration)
            //                    .progressViewStyle(LinearProgressViewStyle())
            //
            //                    HStack {
            //                        Text(formatTime(midiPlayer.currentPosition))
            //                            .font(.caption)
            //                            .foregroundColor(.secondary)
            //
            //                        Spacer()
            //
            //                        Text(formatTime(midiPlayer.totalDuration))
            //                            .font(.caption)
            //                            .foregroundColor(.secondary)
            //                    }
            //                }
            //            }
            
        }
        .border(.primary, width: 1)
        .padding()
    }
    
    private var playButtonIcon: String {
        switch viewModel.midiPlayer?.playbackState {
        case .playing:
            return "pause.fill"
        case .paused, .stopped, .none:
            return "play.fill"
        }
    }
    
    private func togglePlayback() {
        switch viewModel.midiPlayer?.playbackState {
        case .stopped, .paused, .none:
            viewModel.play(modelContext: modelContext)
        case .playing:
            viewModel.pause()
        }
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
