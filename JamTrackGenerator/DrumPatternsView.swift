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
    @Binding var selectedDrumPatternNavigation: DrumPatternNavigation?
    @State private var selectImportFile = false
    
    var body: some View {
        List {
            ForEach(drumPatterns) { drumPattern in
                NavigationLink(value: DrumPatternNavigation.existing(drumPattern)) {
                    Text(drumPattern.name)
                        .border(.blue, width: 1)
                }
                .onTapGesture { selectedDrumPatternNavigation = .existing(drumPattern) }
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
                Button(action: { selectImportFile = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .fileImporter(isPresented: $selectImportFile, allowedContentTypes: [.midi]) { result in
            switch result {
            case .success(let url):
                let trackNotes = importMidi(from: url)
                selectedDrumPatternNavigation = .importOptions(trackNotes)
            case .failure(let error):
                print("Failed to import MIDI file: \(error)")
            }
        }
    }
    
    private func importMidi(from url: URL) -> [MidiTrackData] {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource")
            return []
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        let processor = MidiProcessor()
//        processor.dumpMIDIEvents(from: url)
        do {
            let trackNotes = try processor.process(url: url, filter: .all)
            return trackNotes
//            for (_, trackInfo) in trackNotes.enumerated() {
//                for note in trackInfo.notes {
//                    print("  Note: \(note.note), On: \(note.tickOn), Off: \(note.tickOff), On Velocity: \(note.velocityOn), Off Velocity: \(note.velocityOff)")
//                }
//            }
        } catch {
            fatalError("midi processing failed: \(error)")
        }
    }
//    
//    private func addDrumPattern() {
//        withAnimation {
//            let newDrumPattern = DrumPattern.newDrumPattern(modelContext: modelContext)
//            modelContext.insert(newDrumPattern)
//            selectedDrumPattern = newDrumPattern
//            do {
//                try modelContext.save()
//            } catch {
//                print("Failed to save DrumPattern: \(error)")
//            }
//            
//            importMidi = true
//        }
//    }
}

//#Preview {
//    DrumPatternsView()
//}
