//
//  JamTrackDetailView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/30/25.
//

import SwiftUI

struct JamTrackDetailView: View {
    @State private var viewModel: ViewModel = .init()
    @State private var export = false
    
    var body: some View {
        VStack(spacing: 0) {
            keyFeelTempo
                .fixedSize(horizontal: false, vertical: true)
                .alignmentGuide(.top) { _ in 0 }
                .padding()
            ScrollView {
                sections
                parts
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
                    Picker("Key", selection: $viewModel.specification.key) {
                        ForEach(Array(Key.keys.keys), id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                }
                label: { Text("Key") }
                
                LabeledContent {
                    Picker("Feel", selection: $viewModel.specification.feel) {
                        ForEach(Feel.allCases) { feel in
                            Text(feel.description).tag(feel)
                        }
                    }
                }
                label: { Text("Feel") }
                
                LabeledContent {
                    TextField("BPM", value: $viewModel.specification.bpm, formatter: NumberFormatter())
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
                label: { Text("BPM") }
                
            }
            .background(.yellow)
            .padding()
            
            VStack(spacing: 0) {
                Toggle("Include Count In", isOn: $viewModel.specification.includeCountIn)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .background(.green)
            .padding()
            
        }
        .frame(maxHeight: .infinity, alignment: .top)
        
    }
    
    private var sections: some View {
        VStack(spacing: 0) {
            SwiftUI.Section(header: Text("Song Sections")) {
                HStack {
                    List(selection: $viewModel.selectedSection) {
                        ForEach(viewModel.sections) { section in
                            NavigationLink {
                                EditSectionView(section: Binding(
                                    get: { section },
                                    set: { _ in return }
                                ))
                            }
                            label: {
                                Text(section.description)
                            }
                        }
                    }
                    
                    VStack {
                        Picker("", selection: $viewModel.selectedSongSection) {
                            ForEach(SongSection.allCases) { section in
                                Text(section.description).tag(section)
                            }
                        }
                        .pickerStyle(InlinePickerStyle())
                        .frame(maxWidth: .infinity)
                        .border(.red)
                        
                        Button("Add Section") {
                            viewModel.addSection(section: viewModel.selectedSongSection!)
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
                        ForEach(viewModel.parts) { part in
                            NavigationLink {
                                EditPartView(part: Binding(
                                    get: { part },
                                    set: { _ in return }
                                ))
                            }
                            label: {
                                Text(part.description)
                            }
                        }
                    }
                    
                    VStack {
                        Picker("", selection: $viewModel.selectedMidiInstrument) {
                            ForEach(MidiInstrument.allCases) { midiInstrument in
                                Text(midiInstrument.description).tag(midiInstrument)
                            }
                        }
                        .pickerStyle(InlinePickerStyle())
                        .frame(maxWidth: .infinity)
                        .border(.red)
                        
                        Button("Add Part") {
                            viewModel.addPart(part: viewModel.selectedMidiInstrument!)
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
            viewModel.play()
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

#Preview {
    JamTrackDetailView()
}
