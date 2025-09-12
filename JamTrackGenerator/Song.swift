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
    
    mutating func buildTracks(definition: Definition) {
        // need to move through each song section, in order
        // build each track out for that section
        // need to store partial tracks in progress
        // each part needs a unique id
        var currentPulse: UInt = 0
        var drumPartId: ObjectIdentifier? = nil
        var partMap: [ObjectIdentifier: [EventDescriptor]] = [:]
        var programMap: [ObjectIdentifier: UInt8] = [:]
        
        for section in definition.sections.sorted(by: { $0.order < $1.order } ) {
            for sectionPart in section.sectionParts {
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
                        eventBuilder = try DrumEventBuilder(modelContext: modelContext, styleName: definition.style?.name ?? "", feelName: definition.feel?.name ?? "", patternName: sectionPart.patternName)
                    }
                    else {
                        guard let key = definition.key else {
                            fatalError("no key defined for song")
                        }
                        
                        programMap[part.id] = instrument.programNumber
                        eventBuilder = try HarmonicEventBuilder(modelContext: modelContext, songKey: key, patternName: sectionPart.patternName)
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
            
            if let drumPartId {
                if partId == drumPartId {
                    channel = UInt8(9)
                    program = nil
                } else {
                    channel = nextChannel()
                    program = programMap[partId]
                }
            } else {
                channel = nextChannel()
                program = programMap[partId]
            }
            
            tracks.append(Track(channel: channel, program: program, events: events))
        }
    }
    
//    func buildDrumEvents(modelContext: ModelContext, patternName: String, currentPulse: UInt) -> [EventDescriptor] {
//    }
//    
//    func buildHarmonicEvents(modelContext: ModelContext, patternName: String, currentPulse: UInt) -> [EventDescriptor] {
//        []
//    }
    
//    mutating func buildDrumTrack(definition: Definition) -> Track {
//        var descriptors: [EventDescriptor] = []
//        let drumPattern = DrumPattern(definition: definition)
//        let pattern = drumPattern.pattern05
//        let maxPulse = pattern.chorus.last?.off ?? 0
//        var currentOffset = UInt32(0)
//        
//        if definition.includeCountIn {
//            let (countInDescriptors, lastPulse) = buildCountInDescriptors()
//            currentOffset = lastPulse
//            descriptors.append(contentsOf: countInDescriptors)
//        }
//        
//        for _ in 0..<definition.numberOfChoruses {
//            let copy = pattern.chorus.map { descriptor in
//                var newDescriptor = descriptor
//                newDescriptor.onOffOffset = currentOffset
//                return newDescriptor
//            }
//            
//            descriptors.append(contentsOf: copy)
//            currentOffset += maxPulse
//        }
//        
//        return Track(channel: 9, events: descriptors)
//    }
//    
//    fileprivate func buildCountInDescriptors() -> ([EventDescriptor], UInt32) {
//        var descriptors: [EventDescriptor] = []
//        var currentPulse = UInt32(0)
//        var offPulse = currentPulse + NoteDuration.quarter.value
//        descriptors.append(DrumDescriptor(part: .sideStick, on: currentPulse, off: offPulse))
//        currentPulse = offPulse
//        offPulse = currentPulse + NoteDuration.quarter.value
//        currentPulse = offPulse // rest
//        offPulse = currentPulse + NoteDuration.quarter.value
//        descriptors.append(DrumDescriptor(part: .sideStick, on: currentPulse, off: offPulse))
//        currentPulse = offPulse
//        offPulse = currentPulse + NoteDuration.quarter.value
//        currentPulse = offPulse
//        for _ in 0..<4 {
//            offPulse = currentPulse + NoteDuration.quarter.value
//            descriptors.append(DrumDescriptor(part: .sideStick, on: currentPulse, off: offPulse))
//            currentPulse = offPulse
//        }
//        
//        return (descriptors, offPulse)
//    }
//    
//    mutating func buildBassTrack(definition: Definition) -> Track {
//        var descriptors: [EventDescriptor] = []
//        let pattern = BassPattern(key: Key(definition.key)).pattern0
//        let maxPulse = pattern.last?.off ?? 0
//        var currentOffset = UInt32(0)
//        
//        if definition.includeCountIn {
//            currentOffset += NoteDuration.whole.value * 2 // 2 measures of rest
//        }
//        
//        for _ in 0..<definition.numberOfChoruses {
//            let copy = pattern.map { descriptor in
//                var newDescriptor = descriptor
//                newDescriptor.onOffOffset = currentOffset
//                return newDescriptor
//            }
//            
//            descriptors.append(contentsOf: copy)
//            currentOffset += maxPulse
//        }
//        
//        let channel = nextChannel()
//        return Track(channel: channel, program: .electricBassFinger, events: descriptors)
//    }
    
    mutating private func nextChannel() -> UInt8 {
        channel += 1
        
        if channel == 9 {
            channel += 1
        }
        
        return channel
    }
}
