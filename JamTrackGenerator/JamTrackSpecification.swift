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
     var bpm: UInt8 = 80
     var key: String = "C"
     var numberOfChoruses: Int = 3
    // key signature
    // time signature
    // tempo
    // template
}
