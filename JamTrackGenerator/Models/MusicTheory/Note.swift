//
//  Note.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/23/25.
//

import Foundation

struct Note: Equatable {
    let degree: String
    let octave: Octave
    
    var midiValue: UInt8 {
        (octave + 1) * 12 + (Note.noteValue[degree] ?? 0)
    }
    
    static let noteValue: [String: UInt8] = [
        "C": 0,
        "C♯": 1,
        "D♭": 1,
        "D": 2,
        "D♯": 3,
        "E♭": 3,
        "E": 4,
        "F": 5,
        "F♯": 6,
        "G♭": 6,
        "G": 7,
        "G♯": 8,
        "A♭": 8,
        "A": 9,
        "A♯": 10,
        "B♭": 10,
        "B": 11,
        "C♭": 11
    ]
}
