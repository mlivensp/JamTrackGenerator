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
//        var export = false
        var errorMessage: String?


        
//        var sections: [Section] = []
        var selectedSection: JamTrackSection? = nil
        var selectedSongSection: SongSection? = nil
        
//        var parts: [Part] = []
        var selectedPart: Part? = nil
        var selectedMidiInstrument: Instrument? = nil

        init(jamTrack: JamTrack) {
            self.jamTrack = jamTrack            
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
    }
}
