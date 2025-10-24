//
//  StyleEditViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 10/21/25.
//

import Foundation
import SwiftData

extension StyleEditView {
    @Observable class ViewModel {
        var name: String
        
        var errorMessage: String?
        var didSave: Bool = false
        
        let original: Style
        var modelContext: ModelContext?
        
        init(style: Style) {
            self.original = style
            self.name = style.name
        }
        
        // TODO: switch to a local copy of the related entity arrays??
        var drumPatterns: [DrumPattern] {
            original.drumPatterns
        }
        
        var harmonicPatterns: [HarmonicPattern] {
            original.harmonicPatterns
        }
        
        var jamTracks: [JamTrack] {
            original.jamTracks
        }
        
        var hasUnsavedChanges: Bool {
            return !didSave &&
                (name != original.name)
        }
        
        func commit() {
            original.name = name
        }
        
        func prepareForSave(modelContext: ModelContext) {
            commit()
        }

        func save(modelContext: ModelContext) {
            prepareForSave(modelContext: modelContext)
            
            do {
                try modelContext.save()
                didSave = true
            } catch {
                errorMessage = "Save failed: \(error.localizedDescription)"
                didSave = false
            }
        }
        
        // TODO: add a button to invoke this
        func reset() {
            let fresh = ViewModel(style: original)
            self.name = fresh.name
            self.didSave = false
            self.errorMessage = nil
        }
        
        func discardChanges() {
            didSave = false
            errorMessage = nil
        }
    }
}
