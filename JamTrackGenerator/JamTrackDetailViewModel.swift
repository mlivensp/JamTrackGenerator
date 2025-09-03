//
//  JamTrackDetailViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/30/25.
//

import Foundation

extension JamTrackDetailView {
    @Observable class ViewModel {
        var specification: JamTrackSpecification
        var isPlaying = false
        var isPaused = false
        var export = false
        var errorMessage: String?


        var midiPlayer: MIDIPlayer?

        
        var sections: [Section] = []
        var selectedSection: Section? = nil
        var selectedSongSection: SongSection? = nil
        
        var parts: [Part] = []
        var selectedPart: Part? = nil
        var selectedMidiInstrument: MidiInstrument? = nil

        init() {
            do {
                // TODO: move this closer to where it is needed
                midiPlayer = try MIDIPlayer()
            } catch {
                errorMessage = "Failed to initialize player: \(error.localizedDescription)"
            }
            
            specification = JamTrackSpecification()
            specification.sections.append(Section(section: .chorus))
            sections = specification.sections
            selectedSongSection = .intro
            
            parts.append(Part(instrument: .electricBassFinger))
        }
        
        func addSection(section: SongSection) {
            specification.sections.append(Section(section: section))
            sections = specification.sections
        }
        
        func deleteSection(section: Section) {
            if let sectionIndex = specification.sections.firstIndex(of: section) {
                specification.sections.remove(at: sectionIndex)
            }
        }
        
        func addPart(part: MidiInstrument) {
            
        }
        
        func deletePart(part: Part) {
            
        }
        
        func play() {
            let data = specification.encodeToMidi()
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
            song.buildTracks(specification: specification)
            var document = MidiDocument(specification: specification, song: song)
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
