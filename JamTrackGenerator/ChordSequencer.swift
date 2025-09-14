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
        let oneRoot = key.pitchedNote(distanceFromRoot: 0)
        let fourthRoot = key.pitchedNote(distanceFromRoot: 5)
        let fifthRoot = key.pitchedNote(distanceFromRoot: 7)
        let oneChord = Chord(name: oneRoot.rawNote.name + "7", duration: .whole)
        let fourChord = Chord(name: fourthRoot.rawNote.name + "7", duration: .whole)
        let fiveChord = Chord(name: fifthRoot.rawNote.name + "7", duration: .whole)
        let oneMeasure = Measure(thangs: [oneChord])
        let fourMeasure = Measure(thangs: [fourChord])
        let fiveMeasure = Measure(thangs: [fiveChord])
        return [oneMeasure, oneMeasure, oneMeasure, oneMeasure, fourMeasure, fourMeasure,
                oneMeasure, oneMeasure, fiveMeasure, fourMeasure, oneMeasure, fiveMeasure]
    }
}
