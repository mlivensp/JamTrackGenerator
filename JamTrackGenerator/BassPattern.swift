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
            let note = Note(degree: key[degree], octave: octave)
            result.append(HarmonicEvent(notes: [(note, 100)], duration: duration.value))
        }
        
        return result
    }
    
    var pattern0: [NoteDescriptor] {
        var events: [NoteDescriptor] = []
        var pulseAtMeasureStart: UInt16 = 0
        
        // bar 1
        var pitches: [(ScaleDegree, Octave)] = [ (.root, 2), (.third, 3), (.fourth, 3), (.sixth, 3), (.fifth, 3)]
        var measureEvents = createFourthBeatSwingTripletsEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 2
        pitches = [(.root, 2), (.third, 3), (.fifth, 3), (.fourth, 3)]
        measureEvents = createQuarterNoteMeasureEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 3
        pitches = [ (.root, 2), (.third, 3), (.fourth, 3), (.sixth, 3), (.fifth, 3)]
        measureEvents = createFourthBeatSwingTripletsEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 4
        pitches = [ (.root, 2), (.fifth, 3), (.sixth, 3), (.third, 3)]
        measureEvents = createQuarterNoteMeasureEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 5
        pitches = [ (.fourth, 3), (.sixth, 3), (.root, 3), (.second, 3), (.root, 3)]
        measureEvents = createFourthBeatSwingTripletsEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 6
        pitches = [ (.fourth, 3), (.sixth, 3), (.minor7th, 3), (.seventh, 3)]
        measureEvents = createQuarterNoteMeasureEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 7
        pitches = [ (.root, 2), (.third, 3), (.fourth, 3), (.sixth, 3), (.fifth, 3)]
        measureEvents = createFourthBeatSwingTripletsEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 8
        pitches = [ (.root, 2), (.third, 3), (.fourth, 3), (.flat5th, 3)]
        measureEvents = createQuarterNoteMeasureEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 9
        pitches = [ (.fifth, 3), (.seventh, 3), (.fifth, 3), (.flat5th, 3)]
        measureEvents = createQuarterNoteMeasureEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 10
        pitches = [ (.fourth, 3), (.sixth, 3), (.minor7th, 3), (.seventh, 3)]
        measureEvents = createQuarterNoteMeasureEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 11
        pitches = [ (.root, 3), (.third, 3), (.fourth, 3), (.fifth, 3)]
        measureEvents = createQuarterNoteMeasureEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        // bar 12
        pitches = [ (.fifth, 3), (.sixth, 3), (.minor7th, 3), (.seventh, 3)]
        measureEvents = createQuarterNoteMeasureEvents(pitches: pitches, startPulse: pulseAtMeasureStart)
        events.append(contentsOf: measureEvents)
        pulseAtMeasureStart += NoteDuration.whole.value

        return events
        
    }
    
    fileprivate func createFourthBeatSwingTripletsEvents(pitches: [(ScaleDegree, Octave)], startPulse: UInt16) -> [NoteDescriptor] {
        var events: [NoteDescriptor] = []
        var event: NoteDescriptor
        var nextPulse: UInt16 = startPulse
        for (i, (degree, octave)) in pitches.enumerated() {
            let duration = i == 4 ? NoteDuration.eighthTriplet : i == 3 ? NoteDuration.eighthTripletSwing : NoteDuration.quarter
            (event, nextPulse) = addEvent(degree: degree, octave: octave, onPulse: nextPulse, duration: duration)
            events.append(event)
        }
        return events

    }
    
    fileprivate func createQuarterNoteMeasureEvents(pitches: [(ScaleDegree, Octave)], startPulse: UInt16) -> [NoteDescriptor] {
        var events: [NoteDescriptor] = []
        var event: NoteDescriptor
        var nextPulse: UInt16 = startPulse
        for (degree, octave) in pitches {
            (event, nextPulse) = addEvent(degree: degree, octave: octave, onPulse: nextPulse, duration: .quarter)
            events.append(event)
        }
        return events
    }
    
    fileprivate func addEvent(degree: ScaleDegree, octave: Octave, onPulse: UInt16, duration: NoteDuration) -> (NoteDescriptor, UInt16) {
        let offPulse = onPulse + duration.value
        let event = NoteDescriptor(note: .init(degree: key[degree], octave: octave), on: onPulse, off: offPulse)
        return (event, offPulse)
    }
    
    static let bassPattern1: [(ScaleDegree, Octave, NoteDuration)] = [
//        (.root, 1, .quarter), (.third, 2, .quarter), (.fourth, 2, .quarter), (.sixth, 2, .eighthTripletSwing), (.fifth, 2, .eighthTriplet),
//        (.root, 1, .quarter), (.third, 2, .quarter), (.fifth, 2, .quarter), (.fourth, 2, .quarter),
//        (.root, 1, .quarter), (.third, 2, .quarter), (.fourth, 2, .quarter), (.sixth, 2, .eighthTripletSwing), (.fifth, 2, .eighthTriplet),
//        (.root, 1, .quarter), (.sixth, 2, .quarter), (.fifth, 2, .quarter), (.third, 2, .quarter),
//        (.fourth, 2, .quarter), (.sixth, 2, .quarter), (.root, 1, .quarter), (.second, 1, .eighthTripletSwing), (.root, 1, .eighthTriplet),
//        (.fourth, 2, .quarter), (.sixth, 2, .quarter), (.minor7th, 2, .quarter), (.seventh, 2, .quarter),
//        (.root, 1, .quarter), (.third, 2, .quarter), (.fourth, 2, .quarter), (.sixth, 2, .eighthTripletSwing), (.fifth, 2, .eighthTriplet),
//        (.root, 1, .quarter), (.third, 2, .quarter), (.fourth, 2, .quarter), (.flat5th, 2, .quarter),
//        (.fifth, 2, .quarter), (.seventh, 2, .quarter), (.fifth, 2, .quarter), (.flat5th, 2, .quarter),
//        (.fourth, 2, .quarter), (.sixth, 2, .quarter), (.minor7th, 2, .quarter), (.seventh, 2, .quarter),
        (.root, 1, .quarter), (.third, 2, .quarter), (.fourth, 2, .quarter), (.fifth, 2, .quarter),
        (.fifth, 2, .quarter), (.sixth, 2, .quarter), (.minor7th, 2, .quarter), (.seventh, 2, .quarter)
    ]
}
