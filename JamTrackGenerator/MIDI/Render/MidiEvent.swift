//
//  MidiEvent.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/28/25.
//

import Foundation

struct MidiEvent {
    let value: UInt8
    let command: UInt8
    let pulse: UInt
    let velocity: UInt8
}
