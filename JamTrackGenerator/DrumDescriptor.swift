//
//  DrumEvent.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/23/25.
//

import Foundation

struct DrumDescriptor: EventDescriptor {
    let part: DrumPart
    let on: UInt32
    let off: UInt32
    let onVelocity: Velocity
    let offVelocity: Velocity
    
    init(part: DrumPart, on: UInt32, off: UInt32, onVelocity: Velocity = 100, offVelocity: Velocity = 64) {
        self.part = part
        self.on = on
        self.off = off
        self.onVelocity = onVelocity
        self.offVelocity = offVelocity
        onOffOffset = 0
    }
    
    var onOffOffset: UInt32

    var midiValue: UInt8 {
        part.rawValue
    }
    
}
