//
//  HarmonicEventBuilder.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/9/25.
//

import Foundation
import SwiftData

struct HarmonicEventBuilder: EventBuilder {
    var pattern: HarmonicPattern
    
    init(modelContext: ModelContext, patternName: String) throws {
        let fetchDescriptor = FetchDescriptor<HarmonicPattern>(predicate: #Predicate { pattern in
            pattern.name == patternName
        })
        
        if let pattern = try modelContext.fetch(fetchDescriptor).first {
            self.pattern = pattern
        } else {
            // TODO: get a better error
            throw NSError(domain: "JamTrackGenerator", code: 1, userInfo: nil)
        }
    }
    
    func buildEvents(startingPulse: UInt) -> [EventDescriptor] {
        []
    }
}
