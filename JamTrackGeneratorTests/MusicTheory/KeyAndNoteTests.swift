//
//  KeyAndNoteTests.swift
//  JamTrackGeneratorTests
//
//  Created by Michael Livenspargar on 8/20/25.
//

@testable import JamTrackGenerator
import Testing

struct KeyAndNoteTests {

    @Test func testC() async throws {
        let key = Key("C")
        #expect(key.third == "E", "Third note of C should be E")
        #expect(key.fourth == "F", "Fourth note of C should be F")
        #expect(key.fifth == "G", "Fifth note of C should be G")
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testG() async throws {
        let key = Key("G")
        #expect(key.third == "B", "Third note of G should be B")
        #expect(key.fourth == "C", "Fourth note of G should be C")
        #expect(key.fifth == "D", "Fifth note of G should be D")
    }
    
    @Test func testB() async throws {
        let key = Key("B")
        #expect(key.third == "D♯", "Third note of B should be D♯")
        #expect(key.fourth == "E", "Fourth note of B should be E")
        #expect(key.fifth == "F♯", "Fifth note of B should be F#")
    }
    
    @Test func testDegreesOfD() {
        let key = Key("D")
        #expect(key[.root] == "D")
        #expect(key[.minor2nd] == "D♯")
        #expect(key[.second] == "E")
        #expect(key[.minor3rd] == "F")
        #expect(key[.third] == "F♯")
        #expect(key[.fourth] == "G")
        #expect(key[.flat5th] == "G♯")
        #expect(key[.fifth] == "A")
        #expect(key[.minor6th] == "A♯")
        #expect(key[.sixth] == "B")
        #expect(key[.minor7th] == "C")
        #expect(key[.seventh] == "C♯")
    }
}
