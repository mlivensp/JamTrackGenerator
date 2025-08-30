//
//  Track.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/28/25.
//

import Foundation

struct Track {
    let channel: UInt8
    let program: MidiInstrument?
    let events: [EventDescriptor]
    
    init(channel: UInt8, program: MidiInstrument? = nil, events: [EventDescriptor]) {
        self.channel = channel
        self.program = program
        self.events = events
    }
}
