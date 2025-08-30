//
//  NoteDuration.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/19/25.
//

import Foundation

struct NoteDuration: Equatable {
    let value: UInt32
    
    init(_ value: UInt32) {
        self.value = value
    }
    
    static var whole: NoteDuration {
        NoteDuration(Global.pulsesPerQuarterNote * 4)
    }
    
    static var half: NoteDuration {
        NoteDuration(Global.pulsesPerQuarterNote * 2)
    }
    
    static var quarter: NoteDuration {
        NoteDuration(Global.pulsesPerQuarterNote)
    }
    
    static var eighth: NoteDuration {
        NoteDuration(Global.pulsesPerQuarterNote / 2)
    }
    
    static var eighthTripletSwing: NoteDuration {
        NoteDuration(Global.pulsesPerQuarterNote / 3 * 2)
    }
    
    static var eighthTriplet: NoteDuration {
        NoteDuration(Global.pulsesPerQuarterNote / 3)
    }
}
