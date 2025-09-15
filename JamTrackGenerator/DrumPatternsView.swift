//
//  DrumPatternsView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/13/25.
//

import SwiftData
import SwiftUI

struct DrumPatternsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DrumPattern.name) var drumPatterns: [DrumPattern]
    @Binding var selectedDrumPattern: DrumPattern?
    @State private var importMidi = false

    var body: some View {
        List {
            ForEach(drumPatterns) { drumPattern in
                NavigationLink(value: drumPattern) {
                    Text(drumPattern.name)
                        .border(.blue, width: 1)
                }
                .onTapGesture { selectedDrumPattern = drumPattern }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(drumPatterns[index])
                }
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to delete DrumPattern: \(error)")
                }
            }
        }
        .navigationTitle("Drum Patterns")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addDrumPattern) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .fileImporter(isPresented: $importMidi, allowedContentTypes: [.midi]) { result in
            switch result {
                case .success(let url):
                print("Imported MIDI files: \(url)")
            case .failure(let error):
                print("Failed to import MIDI file: \(error)")
            }
            // parse midi file
            // find the drum track if any
            // get the events and add them to the pattern
        }
                      //, onCompletion: importMidiFile)
    }
    
    private func addDrumPattern() {
        withAnimation {
            let newDrumPattern = DrumPattern.newDrumPattern(modelContext: modelContext)
            modelContext.insert(newDrumPattern)
            selectedDrumPattern = newDrumPattern
            do {
                try modelContext.save()
            } catch {
                print("Failed to save DrumPattern: \(error)")
            }
            
            importMidi = true
        }
    }
}

//#Preview {
//    DrumPatternsView()
//}
