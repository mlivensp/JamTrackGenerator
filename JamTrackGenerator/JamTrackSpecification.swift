//
//  JamTrackSpecification.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/18/25.
//

import Foundation

 @Observable class JamTrackSpecification {
     var includeDrumTrack: Bool = true
     var includeBassTrack: Bool = true
     var feel: Feel = .shuffle
     var bpm: UInt8 = 105
     var key: String = "A"
     var numberOfChoruses: Int = 3
    // key signature
    // time signature
    // tempo
    // template
}
