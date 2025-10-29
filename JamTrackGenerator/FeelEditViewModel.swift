//
//  FeelEditViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 10/25/25.
//

import Foundation

extension FeelEditView {
    @Observable class ViewModel {
        var feel: Feel
        
        init(feel: Feel) {
            self.feel = feel
        }
        
        var hasUnsavedChanges: Bool {
            true
        }
        
        func reset() {
//            let fresh = ViewModel(jamTrack: original)
//            self.name = fresh.name
//            self.key = fresh.key
//            self.style = fresh.style
//            self.feel = fresh.feel
//            self.bpm = fresh.bpm
//            self.includeCountIn = fresh.includeCountIn
//            self.parts = fresh.parts
//            self.jamTrackSections = fresh.jamTrackSections
//            self.didSave = false
//            self.errorMessage = nil
        }
    }
}
