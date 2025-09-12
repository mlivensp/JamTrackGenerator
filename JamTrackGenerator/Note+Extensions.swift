//
//  Note+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/10/25.
//

import Foundation

extension Note {
    func midiValue(octave: UInt8) -> UInt8 {
        return (octave + 1) * 12 + valueForMidiCalculation
    }
}
