//
//  MidiHandler.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 10/8/25.
//

import Foundation
import SwiftData

@Observable class MidiHandler {
    let url: URL
    var midiPlayer: MIDIPlayer
    var isPlaying = false
    var isPaused = false

    init(url: URL) throws {
        self.url = url
        midiPlayer = try MIDIPlayer()
        midiPlayer.onPlaybackEnded = {
            self.isPlaying = false
            self.isPaused = false
        }
    }
    
    func play() throws {
        if isPaused {
            midiPlayer.resumeMIDIFile()
            
        } else {
            try midiPlayer.playMIDIFile(from: url)
        }
        
        isPlaying = true
        isPaused = false
    }
    
    func togglePlayback() throws {
        switch midiPlayer.playbackState {
        case .stopped, .paused:
            try play()
        case .playing:
            pause()
        }
    }

    func pause() {
        midiPlayer.pauseMIDIFile()
        isPaused = true
    }

    func stop() {
        midiPlayer.stopMIDIFile()
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
