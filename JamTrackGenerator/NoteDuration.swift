//
//  NoteDuration.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/19/25.
//

import Foundation

struct NoteDuration: Equatable {
    let value: UInt16
    
    init(_ value: UInt16) {
        self.value = value
    }
    
    static var whole: NoteDuration {
        NoteDuration(Constants.pulsesPerQuarterNote * 4)
    }
    
    static var half: NoteDuration {
        NoteDuration(Constants.pulsesPerQuarterNote * 2)
    }
    
    static var quarter: NoteDuration {
        NoteDuration(Constants.pulsesPerQuarterNote)
    }
    
    static var eighth: NoteDuration {
        NoteDuration(Constants.pulsesPerQuarterNote / 2)
    }
    
    static var eighthTripletSwing: NoteDuration {
        NoteDuration(Constants.pulsesPerQuarterNote / 3 * 2)
    }
    
    static var eighthTriplet: NoteDuration {
        NoteDuration(Constants.pulsesPerQuarterNote / 3)
    }
}
