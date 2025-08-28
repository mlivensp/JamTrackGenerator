//
//  DrumEvent.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/23/25.
//

import Foundation

struct DrumDescriptor {
    let part: DrumPart
    let on: UInt16
    let off: UInt16
    let onVelocity: Velocity
    let offVelocity: Velocity
    
    init(part: DrumPart, on: UInt16, off: UInt16, onVelocity: Velocity = 100, offVelocity: Velocity = 64) {
        self.part = part
        self.on = on
        self.off = off
        self.onVelocity = onVelocity
        self.offVelocity = offVelocity
    }
}
