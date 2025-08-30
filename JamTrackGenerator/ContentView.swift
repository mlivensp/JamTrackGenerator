//
//  ContentView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/18/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var specification = JamTrackSpecification()
    @State private var export = false
    @State private var player: MIDIPlayer?
    @State private var errorMessage: String?

    var body: some View {
        NavigationSplitView {
            Text("Jam Tracks")
        }
        detail: {
            VStack {
                Form {
                    // TODO: need to specify
                    // song structure: intro, chorus, etc
                    // for each song part, for each instrument, which pattern to use
                    Picker("Key", selection: $specification.key) {
                        ForEach(Array(Key.keys.keys), id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                    Picker("Feel", selection: $specification.feel) {
                        ForEach(Feel.allCases) { feel in
                            Text(feel.description).tag(feel)
                        }
                    }
                    TextField("BPM", value: $specification.bpm, formatter: NumberFormatter())
                        .padding()
                    Toggle("Include Drum Track", isOn: $specification.includeDrumTrack)
                    Toggle("Include Bass Track", isOn: $specification.includeBassTrack)
                    TextField("Number of Choruses", value: $specification.numberOfChoruses, formatter: NumberFormatter())
                    HStack {
                        HStack {
                            Button("Play") {
                                playMidi()
                            }
                        }
                        Spacer()
                        HStack {
                            Button("Export Midi") {
                                export = true
                            }
                        }
                    }
                    .padding()
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
//        }
//        NavigationSplitView {
//            Button("Do It") {
//                export = true
//            }
//        }.navigationTitle(Text("Jam Track Generator"))
//            }
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
//                    } label: {
//                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                do {
                    player = try MIDIPlayer()
                } catch {
                    errorMessage = "Failed to initialize player: \(error.localizedDescription)"
                }
            }
            .fileExporter(
                isPresented: $export,
                document: buildDocument(specification: specification),
                contentType: .midi,
                defaultFilename: "test") { result in
                    switch result {
                    case .success(let url):
                        print("File saved to \(url)")
                    case .failure(let error):
                        print("Failed to save file: \(error.localizedDescription)")
                    }
            }
    }
    
    private func playMidi() {
        var song = Song()
        song.buildTracks(specification: specification)
        var document = MidiDocument(specification: specification, song: song)
        document.encodeMidi()
        let data = document.encodeMidiToData()
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let midiURL = documentsURL.appendingPathComponent("test.midi")
        do {
            try data.write(to: midiURL)
        } catch {
            print("Failed to write data to \(midiURL): \(error)")
        }

        do {
//                    let midiURL = URL(string: "https://petersmidi.com/Am_I_Blue_AB.mid")! // Replace with a valid MIDI URL
            try player?.playMIDIFile(from: midiURL)
        } catch {
            errorMessage = "Failed to play MIDI file: \(error.localizedDescription)"
        }
    }
    
    private func buildDocument(specification: JamTrackSpecification) -> MidiDocument {
        var song = Song()
        song.buildTracks(specification: specification)
        var document = MidiDocument(specification: specification, song: song)
        document.encodeMidi()
        return document
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
    
    private func writeFile() {
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsURL.appendingPathComponent("test.mid")
//        let fileManager = FileManager.default
//        let homeURL = fileManager.homeDirectoryForCurrentUser
////        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let fileURL = homeURL.appendingPathComponent("test.mid")
//        
                guard let headerData = "MThd".data(using: .utf8) else {
                    fatalError(#function + ": Failed to convert string to data")
                }
                let lengthData: Data = Data([0x00, 0x00, 0x00, 0x06])
                let formatData: Data = Data([0x00, 0x01])
                let trackCountData: Data = Data([0x00, 0x01])
                let timeDivisionData: Data = Data([0x00, 0xFF, 0xFF, 0x03])
                var combinedData = Data()
                combinedData.append(contentsOf: headerData)
                combinedData.append(contentsOf: lengthData)
                combinedData.append(contentsOf: formatData)
                combinedData.append(contentsOf: trackCountData)
                combinedData.append(contentsOf: timeDivisionData)
                do {
                    try combinedData.write(to: fileURL)
                } catch {
                    fatalError(#function + ": \(error)")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
