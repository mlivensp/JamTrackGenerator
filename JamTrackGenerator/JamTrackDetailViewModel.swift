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
//        var export = false
        var errorMessage: String?

        var midiPlayer: MIDIPlayer?

        
//        var sections: [Section] = []
        var selectedSection: JamTrackSection? = nil
        var selectedSongSection: SongSection? = nil
        
//        var parts: [Part] = []
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
            
            selectedSongSection = jamTrack.jamTrackSections.first?.songSection
        }
        
        func deleteSection(section: JamTrackSection) {
            if let sectionIndex = jamTrack.jamTrackSections.firstIndex(of: section) {
                jamTrack.jamTrackSections.remove(at: sectionIndex)
            }
        }
        
        func deletePart(part: Part) {
            jamTrack.deletePart(part: part)
        }
        
        func play(modelContext: ModelContext) {
            let data = jamTrack.encodeToMidi(modelContext: modelContext)
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
