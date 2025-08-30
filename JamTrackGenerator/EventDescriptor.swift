//
//  SongSectionPattern.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/28/25.
//

import Foundation

protocol EventDescriptor {
    var midiValue: UInt8 { get }
    var on: UInt32 { get }
    var off: UInt32 { get }
    var onVelocity: UInt8 { get }
    var offVelocity: UInt8 { get }
    
    var onOffOffset: UInt32 { get set }
    
//    var offsetOn: UInt16 { get }
//    var offsetOff: UInt16 { get }
}

extension EventDescriptor {
    var offsetOn: UInt32 {
        on + onOffOffset
    }
    
    var offsetOff: UInt32 {
        off + onOffOffset
    }
}
