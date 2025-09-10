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
        for section in definition.sections.sorted(by: { $0.order < $1.order } ) {
            for sectionPart in section.sectionParts {
                guard let instrument = sectionPart.part?.instrument else {
                    fatalError((#file as NSString).lastPathComponent + "#" + #function + ": no instrument for part")
                }
                
                let events: [EventDescriptor]
                if instrument.name == "Drum" {
                    events = buildDrumEvents(patternName: sectionPart.patternName, currentPulse: currentPulse)
                } else {
                    events = buildHarmonicEvents(patternName: sectionPart.patternName, currentPulse: currentPulse)
                }
                
                currentPulse = events.map( { $0.offsetOff } ).max() ?? currentPulse
                print("section #\(section.order) part #\(sectionPart.part?.instrument.name ?? "unknown") pattern: \(sectionPart.patternName)")
            }
        }
        
//        var trackMap = [ObjectIdentifier: Any]()
//        trackMap[definition.parts[0].id] = definition.parts[0]
//        if definition.includeDrumTrack {
//            tracks.append(buildDrumTrack(definition: definition))
//        }
//        
//        if definition.includeBassTrack {
//            tracks.append(buildBassTrack(definition: definition))
//        }
    }
    
    func buildDrumEvents(patternName: String, currentPulse: UInt) -> [EventDescriptor] {
        []
    }
    
    func buildHarmonicEvents(patternName: String, currentPulse: UInt) -> [EventDescriptor] {
        []
    }
    
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
