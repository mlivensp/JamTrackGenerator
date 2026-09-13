//
//  Song.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/28/25.
//

import Foundation
import SwiftData
import OSLog

struct Song {
    var tracks: [Track] = []
    var channel: UInt8 = 0
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
//    mutating func buildTracks(jamTrack: JamTrack) {
    mutating func buildTracks(style: Style, feel: Feel, key: Key, jamTrackSections: [JamTrackSection]) {
        var currentPulse: UInt = 0
        var drumPartId: PersistentIdentifier? = nil
        var partMap: [PersistentIdentifier: [EventDescriptor]] = [:]
        var programMap: [PersistentIdentifier: (program: UInt8, name: String)] = [:]
        
        Logger.midi.info("building tracks for style \(style.name), feel \(feel.name), key \(key.noteName)")
        for section in jamTrackSections.sorted(by: { $0.order < $1.order } ) {
            Logger.midi.info("building tracks for section \(section.songSection?.name ?? "<no section>")")
            for sectionPart in section.sectionParts.filter( { $0.patternName != "" } ) {
                Logger.midi.info("building track for part \(sectionPart.part?.instrument?.name ?? "<no instrument>")")
                guard let part = sectionPart.part else {
                    fatalError("missing part in setionPart")
                }
                
                guard let instrument = part.instrument else {
                    fatalError((#file as NSString).lastPathComponent + "#" + #function + ": no instrument for part")
                }
                
                let styleName = style.name
                let feelName = feel.name
                
                let eventBuilder: EventBuilder
                do {
                    if instrument.name == "Drums" {
                        drumPartId = part.id
                        let pattern = try fetchDrumPattern(patternName: sectionPart.patternName, styleName: styleName, feelName: feelName)
                        eventBuilder = DrumEventBuilder(pattern: pattern)
                    }
                    else {
                        programMap[part.id] = (instrument.programNumber, instrument.name)
                        let pattern = try fetchHarmonicPattern(patternName: sectionPart.patternName, styleName: styleName, feelName: feelName)
                        eventBuilder = HarmonicEventBuilder(pattern: pattern, key: key)
                    }
                } catch {
                    fatalError(error.localizedDescription)
                }
                
                let events = eventBuilder.buildEvents(startingPulse: currentPulse)
                
                partMap[part.id, default: []].append(contentsOf: events)
            }
            let maxOff = partMap.values.flatMap { $0.map(\.offsetOff) }.max() ?? 0
            currentPulse = maxOff
            Logger.midi.debug("End of section maxOff: \(maxOff)")
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
    
    private func fetchDrumPattern(patternName: String, styleName: String, feelName: String) throws -> DrumPattern {
        let fetchDescriptor = FetchDescriptor<DrumPattern>(predicate: #Predicate { pattern in
            pattern.name == patternName
        })
        
        let patterns = try modelContext.fetch(fetchDescriptor)
        
        guard let pattern = patterns.first(where: {
            ($0.style?.name == nil || $0.style?.name == styleName)
            && ($0.feel?.name == nil || $0.feel?.name == feelName)
        } ) else {
            // TODO: get a better error
            throw NSError(domain: "JamTrackGenerator", code: 43, userInfo: nil)
        }
        
        return pattern
    }
    
    private func fetchHarmonicPattern(patternName: String, styleName: String, feelName: String) throws -> HarmonicPattern {
        let fetchDescriptor = FetchDescriptor<HarmonicPattern>(predicate: #Predicate { pattern in
            pattern.name == patternName
        })
        
        let patterns = try modelContext.fetch(fetchDescriptor)
        
        guard let pattern = patterns.first(where: {
            ($0.style?.name == nil || $0.style?.name == styleName)
            && ($0.feel?.name == nil || $0.feel?.name == feelName)
        } ) else {
            // TODO: get a better error
            throw NSError(domain: "JamTrackGenerator", code: 43, userInfo: nil)
        }
        
        return pattern
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
}

