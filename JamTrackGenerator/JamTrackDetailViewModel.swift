//
//  JamTrackDetailViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/30/25.
//

import Foundation

extension JamTrackDetailView {
    @Observable class ViewModel {
        var definition: Definition
        var isPlaying = false
        var isPaused = false
        var export = false
        var errorMessage: String?


        var midiPlayer: MIDIPlayer?

        
//        var sections: [Section] = []
        var selectedSection: Section? = nil
        var selectedSongSection: SongSection? = nil
        
        var parts: [Part] = []
        var selectedPart: Part? = nil
        var selectedMidiInstrument: Instrument? = nil

        init(definition: Definition) {
            self.definition = definition
            do {
                // TODO: move this closer to where it is needed
                midiPlayer = try MIDIPlayer()
            } catch {
                errorMessage = "Failed to initialize player: \(error.localizedDescription)"
            }
            
//            specification = JamTrackSpecification()
//            specification.sections.append(Section(section: .chorus))
//            sections = specification.sections
//            selectedSongSection = .intro
//            
//            specification.parts.append(Part(instrument: .drums))
//            specification.parts.append(Part(instrument: .electricBassFinger))
//            parts = specification.parts
        }
        
        func addSection(songSection: SongSection) {
            let order = definition.sections.map { $0.order }.max() ?? 0
            definition.sections.append(Section(definition: definition, songSection: songSection, order: order + 1))
//            sections = definition.sections
        }
        
        func deleteSection(section: Section) {
            if let sectionIndex = definition.sections.firstIndex(of: section) {
                definition.sections.remove(at: sectionIndex)
            }
        }
        
        func addPart(instrument: Instrument) {
            let part = Part(instrument: instrument)
            definition.parts.append(part)
            parts = definition.parts
        }
        
        func deletePart(part: Part) {
            if let partIndex = definition.parts.firstIndex(of: part) {
                definition.parts.remove(at: partIndex)
            }
        }
        
        func play() {
            let data = definition.encodeToMidi()
            guard let url = saveToDocuments(data: data) else {
                errorMessage = "Failed to save MIDI file"
                return
            }

            do {
                if isPaused {
                    midiPlayer?.resumeMIDIFile()
                    
                } else {
                    try midiPlayer?.playMIDIFile(from: url)
                }
                
                isPlaying = true
                isPaused = false
            } catch {
                errorMessage = "Playback failed: \(error.localizedDescription)"
            }
        }

        func pause() {
            midiPlayer?.pauseMIDIFile()
            isPaused = true
        }

        func stop() {
            midiPlayer?.stopMIDIFile()
            isPlaying = false
            isPaused = false
        }

        func buildDocument() -> MidiDocument {
            var song = Song()
            song.buildTracks(definition: definition)
            var document = MidiDocument(definition: definition, song: song)
            document.encodeMidi()
            return document
        }

        private func saveToDocuments(data: Data) -> URL? {
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            let midiURL = documentsURL.appendingPathComponent("test.midi")
            do {
                try data.write(to: midiURL)
                return midiURL
            } catch {
                print("Failed to write MIDI file: \(error)")
                return nil
            }
        }
    }
}
