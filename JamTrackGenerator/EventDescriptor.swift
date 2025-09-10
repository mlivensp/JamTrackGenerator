//
//  SongSectionPattern.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/28/25.
//

import Foundation

struct EventDescriptor {
    var midiValue: UInt8
    var on: UInt
    var off: UInt
    var onVelocity: UInt8
    var offVelocity: UInt8
    
    var onOffOffset: UInt = 0
    
//    var offsetOn: UInt16 { get }
//    var offsetOff: UInt16 { get }
}

extension EventDescriptor {
    var offsetOn: UInt {
        on + onOffOffset
    }
    
    var offsetOff: UInt {
        off + onOffOffset
    }
}
