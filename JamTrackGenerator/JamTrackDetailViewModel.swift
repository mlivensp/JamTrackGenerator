//
//  JamTrackDetailViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/30/25.
//

import Foundation
import SwiftData

extension JamTrackDetailView {
    @Observable class ViewModel {
        var jamTrack: JamTrack
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

        init(jamTrack: JamTrack) {
            self.jamTrack = jamTrack
            do {
                // TODO: move this closer to where it is needed
                midiPlayer = try MIDIPlayer()
            } catch {
                errorMessage = "Failed to initialize player: \(error.localizedDescription)"
            }
            
            selectedSongSection = jamTrack.sections.first?.songSection
//            specification = JamTrackSpecification()
//            specification.sections.append(Section(section: .chorus))
//            sections = specification.sections
//            selectedSongSection = .intro
//            
//            specification.parts.append(Part(instrument: .drums))
//            specification.parts.append(Part(instrument: .electricBassFinger))
//            parts = specification.parts
        }
//        
//        func addSection(songSection: SongSection) {
//            let order = jamTrack.sections.map { $0.order }.max() ?? 0
//            jamTrack.sections.append(Section(jamTrack: jamTrack, songSection: songSection, order: order + 1))
////            sections = jamTrack.sections
//        }
        
        func deleteSection(section: Section) {
            if let sectionIndex = jamTrack.sections.firstIndex(of: section) {
                jamTrack.sections.remove(at: sectionIndex)
            }
        }
//        
//        func addPart(instrument: Instrument) {
//            let part = Part(jamTrack: self,instrument: instrument)
//            jamTrack.parts.append(part)
//            parts = jamTrack.parts
//        }
        
        func deletePart(part: Part) {
            if let partIndex = jamTrack.parts.firstIndex(of: part) {
                jamTrack.parts.remove(at: partIndex)
            }
        }
        
        func play(modelContext: ModelContext) {
            let data = jamTrack.encodeToMidi(modelContext: modelContext)
            guard let url = saveToDocuments(data: data) else {
                errorMessage = "Failed to save MIDI file"
                return
            }

            print("playing at \(jamTrack.bpm) BPM")
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

//        func buildDocument() -> MidiDocument {
//            var song = Song()
//            song.buildTracks(jamTrack: jamTrack)
//            var document = MidiDocument(song: song, bpm: jamTrack.bpm)
//            document.encodeMidi()
//            return document
//        }

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
