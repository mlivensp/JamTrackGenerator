//
//  StyleEditViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 10/21/25.
//

import Foundation
import SwiftData

extension FeelEditView {
    @Observable class ViewModel {
        var name: String {
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        
        var errorMessage: String?
        var didSave: Bool = false
        
        let original: Feel
        var modelContext: ModelContext?
        
        var navManager: NavigationStateManager?

        init(feel: Feel) {
            self.original = feel
            self.name = feel.name
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
                navManager?.isDirty = false
            } catch {
                errorMessage = "Save failed: \(error.localizedDescription)"
                didSave = false
            }
        }
        
        func reset() {
            let fresh = ViewModel(feel: original)
            self.name = fresh.name
            self.didSave = false
            self.errorMessage = nil
            navManager?.isDirty = false
        }
        
        func discardChanges() {
            didSave = false
            errorMessage = nil
        }
    }
}
