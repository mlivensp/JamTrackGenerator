//
//  PitchedNote.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/12/25.
//

import Foundation

struct PitchedNote: CustomStringConvertible {
    let rawNote: RawNote
    let octave: UInt8
    
    init(rawNote: RawNote, octave: UInt8) {
        self.rawNote = rawNote
        self.octave = octave
    }
    
    var description: String {
        return "\(rawNote.name)\(octave)"
    }
    
    var midiValue: UInt8 {
        (octave + 1) * 12 + rawNote.distanceFromC
    }
//    
//    func midiValue(octave: UInt8) -> UInt8 {
//        return (octave + 1) * 12 + valueForMidiCalculation
//    }
}
