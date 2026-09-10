//
//  ChordProgressionTests.swift
//  JamTrackGeneratorTests
//
//  Created by Michael Livenspargar on 8/18/25.
//

@testable import JamTrackGenerator
import Testing

struct ChordProgressionTests {

    @Test func testBasic12BarBluesInE() async throws {
        let sequencer = ChordSequencer(form: "12 Bar Blues", key: "E")
        let one = Measure(thangs: [Chord(name: "E7", duration: .whole)])
        let four = Measure(thangs: [Chord(name: "A7", duration: .whole)])
        let five = Measure(thangs: [Chord(name: "B7", duration: .whole)])
        let expected = [one,one,one,one,four,four,one,one,five,four,one,five]
        let calcProgression = sequencer.calcChordProgression()
        #expect(calcProgression.count == expected.count)
        for (i, measure) in calcProgression.enumerated() {
            #expect(measure.thangs.count == expected[i].thangs.count)
            for (j, thang) in measure.thangs.enumerated() {
                let calcedChord = thang as! Chord
                let expectedChord = expected[i].thangs[j] as! Chord
                #expect(calcedChord == expectedChord)
            }
        }
    }

    @Test func testBasic12BarBluesInA() async throws {
        let sequencer = ChordSequencer(form: "12 Bar Blues", key: "A")
        let one = Measure(thangs: [Chord(name: "A7", duration: .whole)])
        let four = Measure(thangs: [Chord(name: "D7", duration: .whole)])
        let five = Measure(thangs: [Chord(name: "E7", duration: .whole)])
        let expected = [one,one,one,one,four,four,one,one,five,four,one,five]
        let calcProgression = sequencer.calcChordProgression()
        #expect(calcProgression.count == expected.count)
        for (i, measure) in calcProgression.enumerated() {
            #expect(measure.thangs.count == expected[i].thangs.count)
            for (j, thang) in measure.thangs.enumerated() {
                let calcedChord = thang as! Chord
                let expectedChord = expected[i].thangs[j] as! Chord
                #expect(calcedChord == expectedChord)
            }
        }
    }

    @Test func testBasic12BarBluesInBFlat() async throws {
        let sequencer = ChordSequencer(form: "12 Bar Blues", key: "B♭")
        let one = Measure(thangs: [Chord(name: "B♭7", duration: .whole)])
        let four = Measure(thangs: [Chord(name: "E♭7", duration: .whole)])
        let five = Measure(thangs: [Chord(name: "F7", duration: .whole)])
        let expected = [one,one,one,one,four,four,one,one,five,four,one,five]
        let calcProgression = sequencer.calcChordProgression()
        #expect(calcProgression.count == expected.count)
        for (i, measure) in calcProgression.enumerated() {
            #expect(measure.thangs.count == expected[i].thangs.count)
            for (j, thang) in measure.thangs.enumerated() {
                let calcedChord = thang as! Chord
                let expectedChord = expected[i].thangs[j] as! Chord
                #expect(calcedChord == expectedChord)
            }
        }
    }

}
