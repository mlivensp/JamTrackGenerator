//
//  PlaybackControlsViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 10/8/25.
//

import Foundation
import SwiftData

extension PlaybackControlsView {
    @Observable class ViewModel {
        let jamTrack: JamTrack
        let modelContext: ModelContext
        var midiHandler: MidiHandler?
        
        init(jamTrack: JamTrack, modelContext: ModelContext) {
            self.jamTrack = jamTrack
            self.modelContext = modelContext
            midiHandler = nil
        }
        
        func togglePlayback() throws {
            if midiHandler == nil {
                midiHandler = try MidiHandler(jamTrack: jamTrack, modelContext: modelContext)
            }
            
            try midiHandler?.togglePlayback()
        }
        
        var isPlaying: Bool {
            midiHandler?.isPlaying ?? false
        }
        
        func stop() {
            midiHandler?.stop()
            midiHandler = nil
        }
        
        var isStopped: Bool {
            midiHandler == nil
        }
        
        func toggleLooping() {
            // TODO: handle looping
        }
        
        var isLooping: Bool {
            // TODO: handle looping
            false
        }
    }
}
