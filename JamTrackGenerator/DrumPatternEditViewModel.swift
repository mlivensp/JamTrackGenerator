//
//  DrumPatternEditViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 11/13/25.
//

import Foundation
import SwiftData

extension DrumPatternEditView {
    @Observable class ViewModel {
        var name: String {
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        
        var style: Style? {
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        
        var feel: Feel? {
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        
        var errorMessage: String?
        var didSave: Bool = false
        
        let original: DrumPattern
        var modelContext: ModelContext?
        
        var navManager: NavigationStateManager?

        init(drumPattern: DrumPattern) {
            self.original = drumPattern
            self.name = drumPattern.name
            self.style = drumPattern.style
            self.feel = drumPattern.feel
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
            let fresh = ViewModel(drumPattern: original)
            self.name = fresh.name
            self.style = fresh.style
            self.feel = fresh.feel
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
