//
//  DrumEvent.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/28/25.
//

import Foundation

struct DrumEvent {
    let part: DrumPart
    let command: UInt8
    let onPulse: UInt16
    let velocity: Velocity
}
