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
//        var jamTracks: [JamTrack] = []
        
        init() {
        }
        
//        fileprivate func fetchJamTracks(modelContext: ModelContext) -> [JamTrack] {
//            let fetchDescriptor = FetchDescriptor<JamTrack>(sortBy: [SortDescriptor(\JamTrack.name)])
//            
//            do {
//                return try modelContext.fetch(fetchDescriptor)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
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
