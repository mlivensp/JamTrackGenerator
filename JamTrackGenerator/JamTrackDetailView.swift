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
    @Bindable var definition: Definition
    @State private var viewModel: ViewModel
    @State private var export = false
    
    @Query var keys: [Key]
    @Query var feels: [Feel]
    @Query var instruments: [Instrument]
    @Query var songSections: [SongSection]
    
    init(definition: Definition) {
        self.definition = definition
        self._viewModel = .init(wrappedValue: .init(definition: definition))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            keyFeelTempo
                .fixedSize(horizontal: false, vertical: true)
                .alignmentGuide(.top) { _ in 0 }
                .padding()
//            Text("Number of sections: \(definition.sections.count)")
//            Text("Number of parts: \(definition.parts.count)")
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
    }
    
    private var keyFeelTempo: some View {
        HStack {
            VStack(spacing: 0) {
                
                LabeledContent {
                    Picker("Key", selection: $definition.key) {
                        ForEach(keys) { key in
                            Text(key.name).tag(key)
                        }
                    }
                }
                label: { Text("Key") }
                
                LabeledContent {
                    Picker("Feel", selection: $definition.feel) {
                        ForEach(feels, id: \.self) { feel in
                            Text(feel.name).tag(feel)
                        }
                    }
                }
                label: { Text("Feel") }
                
                LabeledContent {
                    TextField("BPM", value: $definition.bpm, formatter: NumberFormatter())
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
                label: { Text("BPM") }
                
            }
            .background(.yellow)
            .padding()
            
//            VStack(spacing: 0) {
//                Toggle("Include Count In", isOn: $viewModel.definition.includeCountIn)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//            }
//            .background(.green)
//            .padding()
            
        }
        .frame(maxHeight: .infinity, alignment: .top)
        
    }
    
    private var sections: some View {
        VStack(spacing: 0) {
            SwiftUI.Section(header: Text("Song Sections")) {
                HStack {
                    List(selection: $viewModel.selectedSection) {
                        ForEach(definition.sections, id: \.self) { section in
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
                        Picker("", selection: $viewModel.selectedSongSection) {
                            ForEach(songSections) { section in
                                Text(section.name).tag(section)
                            }
                        }
//                        .pickerStyle(InlinePickerStyle())
                        .frame(maxWidth: .infinity)
                        .border(.red)
                        
                        Button("Add Section") {
                            let _ = definition.addSection(songSection: viewModel.selectedSongSection!)
                        }
                    }
                }
            }
            .border(.red)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var parts: some View {
        VStack(spacing: 0) {
            SwiftUI.Section(header: Text("Parts")) {
                HStack {
                    List(selection: $viewModel.selectedPart) {
                        ForEach(definition.parts) { part in
                            NavigationLink {
                                EditPartView(part: Binding(
                                    get: { part },
                                    set: { _ in return }
                                ))
                            }
                            label: {
                                Text(part.instrument.name)
                            }
                        }
                    }
                    
                    VStack {
                        Picker("", selection: $viewModel.selectedMidiInstrument) {
                            ForEach(instruments) { instrument in
                                Text(instrument.name).tag(instrument)
                            }
                        }
//                        .pickerStyle()
                        .frame(maxWidth: .infinity)
                        .border(.red)
                        
                        Button("Add Part") {
                            if let selectedMidiInstrument = viewModel.selectedMidiInstrument {
                                let _ = definition.addPart(instrument: selectedMidiInstrument)
                            }
                        }
                    }
                }
            }
            .border(.red)
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
                        .background(Color.blue)
                        .foregroundColor(.white)
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
        .border(.green)
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
}

//#Preview {
//    JamTrackDetailView()
//}
