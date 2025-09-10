//
//  DrumEventBuilder.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/9/25.
//

import Foundation
import SwiftData

struct DrumEventBuilder: EventBuilder {
    var pattern: DrumPattern
    
    init(modelContext: ModelContext, patternName: String) throws {
        let fetchDescriptor = FetchDescriptor<DrumPattern>(predicate: #Predicate { pattern in
            pattern.name == patternName
        })
        
        if let pattern = try modelContext.fetch(fetchDescriptor).first {
            self.pattern = pattern
        } else {
            // TODO: get a better error
            throw NSError(domain: "JamTrackGenerator", code: 1, userInfo: nil)
        }
    }
    
    func buildEvents(startingPulse: UInt) -> [EventDescriptor] {
        var events: [EventDescriptor] = []

        for drumNoteInPattern in pattern.drumNotesInPattern {
            guard let drumNote = drumNoteInPattern.drumNote else {
                fatalError((#file as NSString).lastPathComponent + ": " + #function + ": " + "Could not find drum note for \(drumNoteInPattern)")
            }
            
            let midiValue = drumNote.midiValue
            let onPulse = drumNoteInPattern.timestampOn + startingPulse
            let offPulse = drumNoteInPattern.timestampOff + startingPulse
            let onVelocity: UInt8 = 100
            let offVelocity: UInt8 = 64
            let event = EventDescriptor( midiValue: midiValue, on: onPulse, off: offPulse, onVelocity: onVelocity, offVelocity: offVelocity)
            events.append(event)
        }
        
        return events
    }
}
