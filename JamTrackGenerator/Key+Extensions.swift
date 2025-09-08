//
//  Key+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/6/25.
//

import Foundation

extension Key {
    func noteOfDegree(scaleDegree: ScaleDegree) -> Note {
        let sortedNotes = notes.sorted { $0.sortOrder < $1.sortOrder }
        return sortedNotes[scaleDegree.ordinal].note ?? Note(name: "Unknown", valueForMidiCalculation: 0)
    }
    
    var root: Note {
        let sortedNotes = notes.sorted { $0.sortOrder < $1.sortOrder }
        return sortedNotes[0].note ?? Note(name: "Unknown", valueForMidiCalculation: 0)
    }
    
    var fourth: Note {
        let sortedNotes = notes.sorted { $0.sortOrder < $1.sortOrder }
        return sortedNotes[3].note ?? Note(name: "Unknown", valueForMidiCalculation: 0)
    }
    
    var fifth: Note {
        let sortedNotes = notes.sorted { $0.sortOrder < $1.sortOrder }
        return sortedNotes[4].note ?? Note(name: "Unknown", valueForMidiCalculation: 0)
    }
}
