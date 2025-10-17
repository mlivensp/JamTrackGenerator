//
//  JamTracksViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/13/25.
//

import Foundation
import SwiftData

extension JamTracksView {
    @Observable class ViewModel {
        var midiHandler: MidiHandler?
        init() {}
        
//        func togglePlayJamTrack(jamTrack: JamTrack, modelContext: ModelContext) throws {
//            if midiHandler == nil {
//                midiHandler = try MidiHandler(jamTrack: jamTrack, modelContext: modelContext)
//            }
//
//            try midiHandler?.togglePlayback()
//        }
        
        func addJamTrack(modelContext: ModelContext) -> JamTrack {
            let newJamTrack = JamTrack.newJamTrack(modelContext: modelContext)
            modelContext.insert(newJamTrack)
            do {
                try modelContext.save()
            } catch {
                fatalError("died trying to fetch")
            }
            
//            jamTracks = fetchJamTracks()
            return newJamTrack
        }
    }
}
