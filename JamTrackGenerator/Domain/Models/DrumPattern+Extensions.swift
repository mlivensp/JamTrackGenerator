//
//  DrumPattern+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/13/25.
//

import Foundation
import SwiftData

extension DrumPattern: Identifiable { }

extension DrumPattern {
    var sortedNotes: [DrumNoteInPattern] {
        drumNotesInPattern.sorted(by: { $0.timestampOn < $1.timestampOn })
    }
    
    static func newDrumPattern(modelContext: ModelContext) -> DrumPattern {
        let drumPattern = DrumPattern(name: "New Drum Pattern")
        
        let styleFetchDescriptor = FetchDescriptor<Style>(predicate: #Predicate { style in
            style.name == "12 Bar Blues"
        })
        let feelFetchDescriptor = FetchDescriptor<Feel>(predicate: #Predicate { feel in
            feel.name == "Shuffle"
        })
        
        do {
            drumPattern.style = try modelContext.fetch(styleFetchDescriptor).first
            drumPattern.feel = try modelContext.fetch(feelFetchDescriptor).first
        } catch {
            fatalError("Fatal error fetching DrumPattern defaults: \(error.localizedDescription)")
        }
        
        return drumPattern
    }
}
