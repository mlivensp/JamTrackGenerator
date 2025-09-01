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
        VStack {
            Group {
                Form {
                    Picker("Key", selection: $viewModel.specification.key) {
                        ForEach(Array(Key.keys.keys), id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                    Picker("Feel", selection: $viewModel.specification.feel) {
                        ForEach(Feel.allCases) { feel in
                            Text(feel.description).tag(feel)
                        }
                    }
                    
                    HStack {
                        Text("BPM")
                        Spacer()
                        TextField("BPM", value: $viewModel.specification.bpm, formatter: NumberFormatter())
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    Toggle("Include Count In", isOn: $viewModel.specification.includeCountIn)

                    Toggle("Include Drum Track", isOn: $viewModel.specification.includeDrumTrack)
                    Toggle("Include Bass Track", isOn: $viewModel.specification.includeBassTrack)
                    HStack {
                        Text("Number Of Choruses")
                        Spacer()
                        TextField("Number of Choruses", value: $viewModel.specification.numberOfChoruses, formatter: NumberFormatter())
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        export = true
                    } label: {
                        Label("Export MIDI", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .fileExporter(
                isPresented: $export,
                document: viewModel.buildDocument(),
                contentType: .midi,
                defaultFilename: "test") { result in
                    switch result {
                    case .success(let url):
                        print("File saved to \(url)")
                    case .failure(let error):
                        print("Failed to save file: \(error.localizedDescription)")
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

    private var playbackControls: some View {
        HStack(spacing: 20) {
            Button {
                viewModel.play()
            } label: {
                Label("Play", systemImage: "play.fill")
            }
            .disabled(viewModel.isPlaying && !viewModel.isPaused)

            Button {
                viewModel.pause()
            } label: {
                Label("Pause", systemImage: "pause.fill")
            }
            .disabled(!viewModel.isPlaying || viewModel.isPaused)

            Button {
                viewModel.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .disabled(!viewModel.isPlaying)
        }
        .padding()
    }
}

#Preview {
    JamTrackDetailView()
}
