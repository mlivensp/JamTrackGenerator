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
    
    init(modelContext: ModelContext, songKey: Key, patternName: String) throws {
        let fetchDescriptor = FetchDescriptor<HarmonicPattern>(predicate: #Predicate { pattern in
            pattern.name == patternName
        })
        
        if let pattern = try modelContext.fetch(fetchDescriptor).first {
            self.pattern = pattern
        } else {
            // TODO: get a better error
            throw NSError(domain: "JamTrackGenerator", code: 1, userInfo: nil)
        }
        
        let songKeyName = songKey.name
        let keyFetchDescriptor = FetchDescriptor<Key>(predicate: #Predicate { key in
            key.name == songKeyName
        })

        if let key = try modelContext.fetch(keyFetchDescriptor).first {
            self.key = key
        } else {
            // TODO: get a better error
            throw NSError(domain: "JamTrackGenerator", code: 1, userInfo: nil)
        }
    }
    
    func buildEvents(startingPulse: UInt) -> [EventDescriptor] {
        var events: [EventDescriptor] = []

        for harmonicNoteInPattern in pattern.harmonicNotesInPattern.sorted(by: { $0.timestampOn < $1.timestampOn } ) {
            guard let noteInKey: NoteInKey = key.notes.first(where: {
                $0.scaleDegree == harmonicNoteInPattern.scaleDegree
            }) else {
                fatalError((#file as NSString).lastPathComponent + ": " + #function + ": " + "Could not find note for \(harmonicNoteInPattern)")
            }
            
            guard let note = noteInKey.note else {
                fatalError((#file as NSString).lastPathComponent + ": " + #function + ": " + "Could not find note for \(noteInKey)")
            }
            
            let midiValue = note.midiValue(octave: harmonicNoteInPattern.octave)
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
