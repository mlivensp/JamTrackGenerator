//
//  NoteDescriptor.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/28/25.
//

import Foundation

struct NoteDescriptor {
    let note: Note
    let on: UInt16
    let off: UInt16
    let onVelocity: Velocity
    let offVelocity: Velocity
    
    init(note: Note, on: UInt16, off: UInt16, onVelocity: Velocity = 100, offVelocity: Velocity = 64) {
        self.note = note
        self.on = on
        self.off = off
        self.onVelocity = onVelocity
        self.offVelocity = offVelocity
    }
}
