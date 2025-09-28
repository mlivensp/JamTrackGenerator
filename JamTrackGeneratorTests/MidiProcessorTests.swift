import Testing
@testable import JamTrackGenerator
import Foundation

let processor = MidiProcessor()

@Test("Process all tracks")
func testProcessAllTracks() throws {
    let data = Data(MockMIDI.overlappingNotesTrackData)
    let url = try writeTempDataFile(data)
    let tracks = try processor.process(url: url, filter: .all)
    #expect(!tracks.isEmpty)
}

@Test("Filter drum tracks")
func testDrumTrackFiltering() throws {
    let data = Data(MockMIDI.ambiguousDrumTrackData)
    let url = try writeTempDataFile(data)
    let tracks = try processor.process(url: url, filter: .drumsOnly)
    #expect(tracks.allSatisfy { $0.isDrumTrack })
}

@Test("Filter non-drum tracks")
func testNonDrumTrackFiltering() throws {
    let data = Data(MockMIDI.noNotesTrackData)
    let url = try writeTempDataFile(data)
    let tracks = try processor.process(url: url, filter: .nonDrumsOnly)
    #expect(tracks.allSatisfy { !$0.isDrumTrack })
}

@Test("Note parsing accuracy")
func testNoteParsingAccuracy() throws {
    let data = Data(MockMIDI.overlappingNotesTrackData)
    let url = try writeTempDataFile(data)
    let tracks = try processor.process(url: url)
    let notes = tracks.flatMap(\.notes)
    #expect(!notes.isEmpty)
    #expect(notes.allSatisfy { $0.tickOn < $0.tickOff })
}

@Test("Key signature fallback")
func testKeySignatureFallback() throws {
    let data = Data(MockMIDI.noNotesTrackData)
    let url = try writeTempDataFile(data)
    let tracks = try processor.process(url: url)
    #expect(tracks.allSatisfy { !$0.keySignature.isEmpty })
}

@Test("Empty MIDI file")
func testEmptyMIDIFile() throws {
    let data = Data(MockMIDI.emptyFileData)
    let url = try writeTempDataFile(data)
    let tracks = try processor.process(url: url)
    #expect(tracks.isEmpty)
}

@Test("Malformed MIDI file throws")
func testMalformedMIDIFileThrows() throws {
    let data = Data(MockMIDI.malformedFileData)
    let url = try writeTempDataFile(data)
    do {
        _ = try processor.process(url: url)
        #expect(false, "Expected error, but didn't get one")
    } catch {
        // Success: Threw an error as expected
    }
}

@Test("Overlapping notes are parsed")
func testOverlappingNotes() throws {
    let data = Data(MockMIDI.overlappingNotesTrackData)
    let url = try writeTempDataFile(data)
    let tracks = try processor.process(url: url)
    let notes = tracks.flatMap(\.notes)
    #expect(notes.count > 1)
    #expect(notes.contains { note in
        notes.contains { other in
            other != note && other.tickOn < note.tickOff && other.tickOff > note.tickOn
        }
    })
}

@Test("Track with no notes")
func testTrackWithNoNotes() throws {
    let data = Data(MockMIDI.noNotesTrackData)
    let url = try writeTempDataFile(data)
    let tracks = try processor.process(url: url)
    #expect(tracks.allSatisfy { $0.notes.isEmpty })
}

@Test("Ambiguous drum track detection")
func testAmbiguousDrumTrackDetection() throws {
    let data = Data(MockMIDI.ambiguousDrumTrackData)
    let url = try writeTempDataFile(data)
    let tracks = try processor.process(url: url, filter: .drumsOnly)
    #expect(!tracks.isEmpty)
    #expect(tracks.allSatisfy { $0.isDrumTrack })
}

// MARK: - Helpers

func writeTempDataFile(_ data: Data) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mid")
    try data.write(to: url)
    return url
}
