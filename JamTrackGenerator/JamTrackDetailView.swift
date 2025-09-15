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
                    TextField("", text: $jamTrack.name)
                }
                label: { Text("Name") }

                LabeledContent {
                    Picker("", selection: $jamTrack.key) {
                        ForEach(keys) { key in
                            Text(key.name).tag(key)
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
    
    private var sections: some View {
        VStack(spacing: 0) {
            SwiftUI.Section(header: Text("Song Sections")) {
                HStack {
                    List(selection: $viewModel.selectedSection) {
                        ForEach(jamTrack.sections.sorted(by: { $0.order < $1.order } )) { section in
                            NavigationLink {
                                SectionDetailView(modelContext: modelContext, section: Binding(
                                    get: { section },
                                    set: { _ in return }
                                ))
                            }
                            label: {
                                Text(section.songSection?.name ?? "<< unknown >>")
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
                        ForEach(jamTrack.parts.sorted(by: { $0.instrument?.name ?? "" < $1.instrument?.name ?? "" } )) { part in
                            NavigationLink {
                                PartDetailView(modelContext: modelContext, part: Binding(
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
                        // Picker for InstrumentFamily
                            Picker("Instrument Family", selection: $selectedFamily) {
                                ForEach(instrumentFamilies, id: \.self) { family in
                                    Text(family.name).tag(Optional(family))
                                }
                            }

                            // Picker for Instruments in selected family
                            Picker("Instrument", selection: $selectedInstrument) {
                                ForEach(selectedFamily?.instruments ?? [], id: \.self) { instrument in
                                    Text(instrument.name).tag(Optional(instrument))
                                }
                            }
//                        Spacer()
//                        Picker("", selection: $viewModel.selectedMidiInstrument) {
//                            ForEach(instruments.sorted(by: { $0.name < $1.name } )) { instrument in
//                                Text(instrument.name).tag(instrument)
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
                        
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
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Spacer()
                
                // Play/Pause button
                Button(action: togglePlayback) {
                    Image(systemName: playButtonIcon)
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.primary)
                        .accessibilityLabel(playButtonIcon == "play.fill" ? "Play" : "Pause") // Improves accessibility
                        .clipShape(Circle())
                }
                .buttonStyle(.plain) // Remove default button styling
                .scaleEffect(playIsPressed ? 0.95 : 1.0) // Subtle press animation
                .animation(.easeOut(duration: 0.2), value: playIsPressed) // Smooth animation
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            playIsPressed = true
                        }
                        .onEnded { _ in
                            playIsPressed = false
                        }
                )
                
                // Stop button
                Button(action: { viewModel.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.primary)
                        .accessibilityLabel("Stop") // Improves accessibility
                        .clipShape(Circle())
                }
                .disabled(viewModel.midiPlayer?.playbackState == .stopped)
                .buttonStyle(.plain) // Remove default button styling
                .scaleEffect(playIsPressed ? 0.95 : 1.0) // Subtle press animation
                .animation(.easeOut(duration: 0.2), value: stopIsPressed) // Smooth animation
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            stopIsPressed = true
                        }
                        .onEnded { _ in
                            stopIsPressed = false
                        }
                )

                Spacer(minLength: 0)
                HStack {
                    // Loop toggle
//                    Button(action: { viewModel.midiPlayer?.isLooping.toggle() }) {
//                        Image(systemName: viewModel.midiPlayer?.isLooping ?? false ? "repeat.1" : "repeat")
//                            .font(.title3)
//                            .foregroundColor(viewModel.midiPlayer?.isLooping ?? false ? .blue : .gray)
//                    }
                    Button(action: { viewModel.midiPlayer?.isLooping.toggle() } ) {
                        Image(systemName: viewModel.midiPlayer?.isLooping ?? false ? "repeat.1" : "repeat")
                            .font(.title3)
                            .foregroundStyle(viewModel.midiPlayer?.isLooping ?? false ? Color.accentColor : .primary)
                            .frame(width: 40, height: 40) // Consistent touch area
                            .clipShape(.circle)
//                            .background(.thinMaterial, in: .circle) // Subtle background
                            .padding(8) // Larger touch area
                    }
                    .buttonStyle(.plain) // Remove default button styling
                    .scaleEffect(loopIsPressed ? 0.95 : 1.0) // Scale animation on press
                    .animation(.easeOut(duration: 0.2), value: loopIsPressed) // Smooth animation
                    .accessibilityLabel(viewModel.midiPlayer?.isLooping ?? false ? "Disable Loop" : "Enable Loop") // Dynamic accessibility label
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                loopIsPressed = true
                            }
                            .onEnded { _ in
                                loopIsPressed = false
                            }
                    )                }
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
