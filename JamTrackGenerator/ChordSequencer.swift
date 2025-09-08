//
//  ChordSequencer.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/18/25.
//

import Foundation

struct ChordSequencer {
    private let form: String
    private let key: Key
    
    init(form: String, key: Key) {
        self.form = form
        self.key = key
    }
    
    func calcChordProgression() -> [Measure] {
        let oneChord = Chord(name: key.root.name + "7", duration: .whole)
        let fourChord = Chord(name: key.fourth.name + "7", duration: .whole)
        let fiveChord = Chord(name: key.fifth.name + "7", duration: .whole)
        let oneMeasure = Measure(thangs: [oneChord])
        let fourMeasure = Measure(thangs: [fourChord])
        let fiveMeasure = Measure(thangs: [fiveChord])
        return [oneMeasure, oneMeasure, oneMeasure, oneMeasure, fourMeasure, fourMeasure,
                oneMeasure, oneMeasure, fiveMeasure, fourMeasure, oneMeasure, fiveMeasure]
    }
}
