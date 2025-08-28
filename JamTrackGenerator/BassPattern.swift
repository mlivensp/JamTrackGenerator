//
//  BassPattern.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/22/25.
//

import Foundation

struct BassPattern {
    let key: Key
    
    init(key: Key) {
        self.key = key
    }
    
    func generate(pattern: [(ScaleDegree, Octave, NoteDuration)]) -> [HarmonicEvent] {
        var result: [HarmonicEvent] = []
        for (degree, octave, duration) in pattern {
            let note = Note(pitch: key[degree], octave: octave)
            result.append(HarmonicEvent(notes: [(note, 100)], duration: duration.value))
        }
        
        return result
    }
    
    typealias Octave = Int
    
    static let bassPattern1: [(ScaleDegree, Octave, NoteDuration)] = [
        (.root, 1, .quarter), (.third, 2, .quarter), (.fourth, 2, .quarter), (.sixth, 2, .eighthTripletSwing), (.fifth, 2, .eighthTriplet),
        (.root, 1, .quarter), (.third, 2, .quarter), (.fifth, 2, .quarter), (.fourth, 2, .quarter),
        (.root, 1, .quarter), (.third, 2, .quarter), (.fourth, 2, .quarter), (.sixth, 2, .eighthTripletSwing), (.fifth, 2, .eighthTriplet),
        (.root, 1, .quarter), (.sixth, 2, .quarter), (.fifth, 2, .quarter), (.third, 2, .quarter),
        (.fourth, 2, .quarter), (.sixth, 2, .quarter), (.root, 1, .quarter), (.second, 1, .eighthTripletSwing), (.root, 1, .eighthTriplet),
        (.fourth, 2, .quarter), (.sixth, 2, .quarter), (.minor7th, 2, .quarter), (.seventh, 2, .quarter),
        (.root, 1, .quarter), (.third, 2, .quarter), (.fourth, 2, .quarter), (.sixth, 2, .eighthTripletSwing), (.fifth, 2, .eighthTriplet),
        (.root, 1, .quarter), (.third, 2, .quarter), (.fourth, 2, .quarter), (.flat5th, 2, .quarter),
        (.fifth, 2, .quarter), (.seventh, 2, .quarter), (.fifth, 2, .quarter), (.flat5th, 2, .quarter),
        (.fourth, 2, .quarter), (.sixth, 2, .quarter), (.minor7th, 2, .quarter), (.seventh, 2, .quarter),
        (.root, 1, .quarter), (.third, 2, .quarter), (.fourth, 2, .quarter), (.fifth, 2, .quarter),
        (.fifth, 2, .quarter), (.sixth, 2, .quarter), (.minor7th, 2, .quarter), (.seventh, 2, .quarter)
    ]
}
