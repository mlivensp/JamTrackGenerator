//
//  NoteDescriptor.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/28/25.
//

import Foundation

struct NoteDescriptor: EventDescriptor {
    let note: Note
    let on: UInt32
    let off: UInt32
    let onVelocity: Velocity
    let offVelocity: Velocity
    
    init(note: Note, on: UInt32, off: UInt32, onVelocity: Velocity = 100, offVelocity: Velocity = 64) {
        self.note = note
        self.on = on
        self.off = off
        self.onVelocity = onVelocity
        self.offVelocity = offVelocity
        self.onOffOffset = 0
    }
    
    var onOffOffset: UInt32
    
    var midiValue: UInt8 {
        note.midiValue
    }
}
