//
//  HarmonicEvent.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/19/25.
//

import Foundation

struct HarmonicEvent: Equatable {
    static func == (lhs: HarmonicEvent, rhs: HarmonicEvent) -> Bool {
        guard lhs.notes.count == rhs.notes.count else {
            return false
        }
        
        for (i, note) in lhs.notes.enumerated() {
            if note != rhs.notes[i] {
                return false
            }
        }
        
        return true
    }
    
    let notes: [(Note, Velocity)]
    let duration: UInt16
}
