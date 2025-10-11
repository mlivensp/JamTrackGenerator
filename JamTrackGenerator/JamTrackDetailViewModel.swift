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
        var errorMessage: String?

        init(jamTrack: JamTrack) {
            self.jamTrack = jamTrack            
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
