//
//  KeyAndNoteTests.swift
//  JamTrackGeneratorTests
//
//  Created by Michael Livenspargar on 8/20/25.
//

import Foundation
@testable import JamTrackGenerator
import SwiftData
import Testing

@MainActor
struct KeyAndNoteTests {
    let container: ModelContainer
    
    init() async throws {
        let schema = Schema([
            Style.self,
            RawNote.self,
            Key.self,
            NoteInKey.self,
            Feel.self,
            SongSection.self,
            Section.self,
            InstrumentFamily.self,
            Instrument.self,
            Part.self,
            JamTrack.self,
            ScaleDegree.self,
            HarmonicNoteInPattern.self,
            HarmonicPattern.self,
            SectionPart.self,
            DrumNote.self,
            DrumNoteInPattern.self,
            DrumPattern.self,
            
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            container.setup()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // we have a key, a number of halfsteps, and a base octave
    // now we need a note that is a certain number of halfsteps from the key root
    
    @Test func testPitchedNotesFromC2() async throws {
        let keyFetchDescriptor = FetchDescriptor<Key>()
        let keys = try container.mainContext.fetch(keyFetchDescriptor)
        guard let key = keys.first(where: { $0.name == "C Major"} ) else {
            fatalError("key not found")
        }

        var pitchedNote = key.pitchedNote(distanceFromRoot: 0, octave: 2)
        #expect(pitchedNote.description == "C2", "0 of C2 should be C2 not \(pitchedNote.description)")
        
        pitchedNote = key.pitchedNote(distanceFromRoot: 2, octave: 2)
        #expect(pitchedNote.description == "D2", "2 of C2 should be D2 not \(pitchedNote.description)")
    }
    
    @Test func testPitchedNotesFromG2() async throws {
        let keyFetchDescriptor = FetchDescriptor<Key>()
        let keys = try container.mainContext.fetch(keyFetchDescriptor)
        guard let key = keys.first(where: { $0.name == "G Major"} ) else {
            fatalError("key not found")
        }
        
        var pitchedNote = key.pitchedNote(distanceFromRoot: 0, octave: 2)
        #expect(pitchedNote.description == "G2", "1 of G2 should be G2 not \(pitchedNote.description)")
        pitchedNote = key.pitchedNote(distanceFromRoot: 4, octave: 2)
        #expect(pitchedNote.description == "B2", "4 of G2 should be B2 not \(pitchedNote.description)")
        pitchedNote = key.pitchedNote(distanceFromRoot: 7, octave: 2)
        #expect(pitchedNote.description == "D3", "7 of G2 should be D3 not \(pitchedNote.description)")
        pitchedNote = key.pitchedNote(distanceFromRoot: 10, octave: 2)
        #expect(pitchedNote.description == "F3", "10 of G2 should be F3 not \(pitchedNote.description)")
        
        pitchedNote = key.pitchedNote(distanceFromRoot: -2, octave: 2)
        #expect(pitchedNote.description == "F2", "-2 of G2 should be F2 not \(pitchedNote.description)")
        
        pitchedNote = key.pitchedNote(distanceFromRoot: -2, octave: 2)
        #expect(pitchedNote.description == "F2", "-2 of G2 should be F2 not \(pitchedNote.description)")
        
        pitchedNote = key.pitchedNote(distanceFromRoot: -10, octave: 2)
        #expect(pitchedNote.description == "A1", "-10 of G2 should be A1 not \(pitchedNote.description)")
    }
}


//    @Test func testC() async throws {
//        let key = Key("C")
//        #expect(key.third == "E", "Third note of C should be E")
//        #expect(key.fourth == "F", "Fourth note of C should be F")
//        #expect(key.fifth == "G", "Fifth note of C should be G")
//        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
//    }
//
//    @Test func testG() async throws {
//        let key = Key("G")
//        #expect(key.third == "B", "Third note of G should be B")
//        #expect(key.fourth == "C", "Fourth note of G should be C")
//        #expect(key.fifth == "D", "Fifth note of G should be D")
//    }
//
//    @Test func testB() async throws {
//        let key = Key("B")
//        #expect(key.third == "D♯", "Third note of B should be D♯")
//        #expect(key.fourth == "E", "Fourth note of B should be E")
//        #expect(key.fifth == "F♯", "Fifth note of B should be F#")
//    }
//
//    @Test func testDegreesOfD() {
//        let key = Key("D")
//        #expect(key[.root] == "D")
//        #expect(key[.minor2nd] == "D♯")
//        #expect(key[.second] == "E")
//        #expect(key[.minor3rd] == "F")
//        #expect(key[.third] == "F♯")
//        #expect(key[.fourth] == "G")
//        #expect(key[.flat5th] == "G♯")
//        #expect(key[.fifth] == "A")
//        #expect(key[.minor6th] == "A♯")
//        #expect(key[.sixth] == "B")
//        #expect(key[.minor7th] == "C")
//        #expect(key[.seventh] == "C♯")
//    }
