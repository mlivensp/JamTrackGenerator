//
//  Song.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/28/25.
//

import Foundation
import SwiftData

struct Song {
    var tracks: [Track] = []
    var channel: UInt8 = 0
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    mutating func buildTracks(jamTrack: JamTrack) {
        var currentPulse: UInt = 0
        var drumPartId: PersistentIdentifier? = nil
        var partMap: [PersistentIdentifier: [EventDescriptor]] = [:]
        var programMap: [PersistentIdentifier: (program: UInt8, name: String)] = [:]
        
        dumpSectionParts(jamTrack.jamTrackSections)
        for section in jamTrack.jamTrackSections.sorted(by: { $0.order < $1.order } ) {
            for sectionPart in section.sectionParts.filter( { $0.patternName != "" } ) {
                guard let part = sectionPart.part else {
                    fatalError("missing part in setionPart")
                }
                
                guard let instrument = part.instrument else {
                    fatalError((#file as NSString).lastPathComponent + "#" + #function + ": no instrument for part")
                }
                
                let eventBuilder: EventBuilder
                do {
                    if instrument.name == "Drums" {
                        drumPartId = part.id
                        eventBuilder = try DrumEventBuilder(modelContext: modelContext, styleName: jamTrack.style?.name ?? "", feelName: jamTrack.feel?.name ?? "", patternName: sectionPart.patternName)
                    }
                    else {
                        guard let key = jamTrack.key else {
                            fatalError("no key defined for song")
                        }
                        
                        programMap[part.id] = (instrument.programNumber, instrument.name)
                        eventBuilder = try HarmonicEventBuilder(modelContext: modelContext, key: key, patternName: sectionPart.patternName)
                    }
                } catch {
                    fatalError(error.localizedDescription)
                }
                
                let events = eventBuilder.buildEvents(startingPulse: currentPulse)
                
                partMap[part.id, default: []].append(contentsOf: events)
            }
            let maxOff = partMap.values.flatMap { $0.map(\.offsetOff) }.max() ?? 0
            currentPulse = maxOff
            print("End of section maxOff: \(maxOff)")
        }
        
        for (partId, events) in partMap {
            let channel: UInt8
            let program: UInt8?
            let name: String
            
            if let drumPartId {
                if partId == drumPartId {
                    channel = UInt8(9)
                    program = nil
                    name = "Drum Track"
                } else {
                    channel = nextChannel()
                    (program, name) = programMap[partId] ?? (nil, "unknown")
                }
            } else {
                channel = nextChannel()
                (program, name) = programMap[partId] ?? (nil, "unknown")
            }
            
            tracks.append(Track(channel: channel, program: program, name: name, events: events))
        }
    }
    
    mutating private func nextChannel() -> UInt8 {
        defer {
            channel += 1
            
            if channel == 9 {
                channel += 1
            }
        }
        
        return channel
    }
    
    private func dumpSectionParts(_ sections: [JamTrackSection]) {
        for section in sections {
            for sectionPart in section.sectionParts {
                print("section: \(String(describing: section.songSection?.name)), part: \(String(describing: sectionPart.part?.instrument?.name ?? "unknown"))")
            }
        }
    }
}

