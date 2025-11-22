//
//  HarmonicPatternEditViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 11/16/25.
//

import Foundation
import SwiftData

extension HarmonicPatternEditView {
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
        
        var baseOctave: UInt8 {
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        
        var errorMessage: String?
        var didSave: Bool = false
        
        let original: HarmonicPattern
        var modelContext: ModelContext?
        
        var navManager: NavigationStateManager?

        init(harmonicPattern: HarmonicPattern) {
            self.original = harmonicPattern
            self.name = harmonicPattern.name
            self.style = harmonicPattern.style
            self.feel = harmonicPattern.feel
            self.baseOctave = harmonicPattern.baseOctave
        }
        
        var hasUnsavedChanges: Bool {
            return !didSave &&
            (
                name != original.name ||
                style != original.style ||
                feel != original.feel ||
                baseOctave != original.baseOctave
            )
        }
        
        func commit() {
            original.name = name
            original.style = style
            original.feel = feel
            original.baseOctave = baseOctave
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
            let fresh = ViewModel(harmonicPattern: original)
            self.name = fresh.name
            self.style = fresh.style
            self.feel = fresh.feel
            self.baseOctave = fresh.baseOctave
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
