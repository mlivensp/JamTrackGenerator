//
//  Song.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/28/25.
//

import Foundation

struct Song {
    var tracks: [Track] = []
    var channel: UInt8 = 0
    
    mutating func buildTracks(definition: Definition) {
//        if definition.includeDrumTrack {
//            tracks.append(buildDrumTrack(definition: definition))
//        }
//        
//        if definition.includeBassTrack {
//            tracks.append(buildBassTrack(definition: definition))
//        }
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
