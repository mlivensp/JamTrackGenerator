//
//  HarmonicEventBuilder.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/9/25.
//

import Foundation
import SwiftData

struct HarmonicEventBuilder: EventBuilder {
    let pattern: HarmonicPattern
    let key: Key
    
    init(pattern: HarmonicPattern, key: Key) {
        self.pattern = pattern
        self.key = key
    }
    
    func buildEvents(startingPulse: UInt) -> [EventDescriptor] {
        var events: [EventDescriptor] = []

        for harmonicNoteInPattern in pattern.harmonicNotesInPattern.sorted(by: { $0.timestampOn < $1.timestampOn } ) {
            let pitechedNote = key.pitchedNote(distanceFromRoot: harmonicNoteInPattern.halfSteps, octave: pattern.baseOctave)
            let midiValue = pitechedNote.midiValue
            let onPulse = harmonicNoteInPattern.timestampOn + startingPulse
            let offPulse = harmonicNoteInPattern.timestampOff + startingPulse
            let onVelocity: UInt8 = 100
            let offVelocity: UInt8 = 64
            let event = EventDescriptor( midiValue: midiValue, on: onPulse, off: offPulse, onVelocity: onVelocity, offVelocity: offVelocity)
            events.append(event)
        }
        
        return events
    }
}
