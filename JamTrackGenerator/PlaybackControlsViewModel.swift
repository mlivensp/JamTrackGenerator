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
//        let jamTrack: JamTrack
//        let modelContext: ModelContext
        let createURL: () -> URL?
        var midiHandler: MidiHandler?
        
        init(createURL: @escaping () -> URL?) {
//            self.jamTrack = jamTrack
//            self.modelContext = modelContext
            self.createURL = createURL
            midiHandler = nil
        }
        
        func togglePlayback() throws {
            if midiHandler == nil {
                if let url = createURL() {
                    midiHandler = try MidiHandler(url: url)
                }
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
