//
//  Measure.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/19/25.
//

import Foundation

struct Measure: Equatable {    
    var thangs: [any MeasureThang]
    
    init(thangs: [any MeasureThang]) {
        self.thangs = thangs
    }
    
    static func == (lhs: Measure, rhs: Measure) -> Bool {
        return false
    }
}
