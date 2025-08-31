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
    
    mutating func buildTracks(specification: JamTrackSpecification) {
        if specification.includeDrumTrack {
            tracks.append(buildDrumTrack(specification: specification))
        }
        
        if specification.includeBassTrack {
            tracks.append(buildBassTrack(specification: specification))

        }
    }
    
    mutating func buildDrumTrack(specification: JamTrackSpecification) -> Track {
        var descriptors: [EventDescriptor] = []
        let pattern = DrumPattern.pattern05
        let maxPulse = pattern.chorus.last?.off ?? 0
        var currentOffset = UInt32(0)
        for _ in 0..<specification.numberOfChoruses {
            let copy = pattern.chorus.map { descriptor in
                var newDescriptor = descriptor
                newDescriptor.onOffOffset = currentOffset
                return newDescriptor
            }
            
            descriptors.append(contentsOf: copy)
            currentOffset += maxPulse
        }
        
        return Track(channel: 9, events: descriptors)
    }
    
    mutating func buildBassTrack(specification: JamTrackSpecification) -> Track {
        var descriptors: [EventDescriptor] = []
        let pattern = BassPattern(key: Key(specification.key)).pattern0
        let maxPulse = pattern.last?.off ?? 0
        var currentOffset = UInt32(0)
        for _ in 0..<specification.numberOfChoruses {
            let copy = pattern.map { descriptor in
                var newDescriptor = descriptor
                newDescriptor.onOffOffset = currentOffset
                return newDescriptor
            }
            
            descriptors.append(contentsOf: copy)
            currentOffset += maxPulse
        }
        
        let channel = nextChannel()
        return Track(channel: channel, program: .electricBassFinger, events: descriptors)
    }
    
    mutating private func nextChannel() -> UInt8 {
        channel += 1
        
        if channel == 9 {
            channel += 1
        }
        
        return channel
    }
}
