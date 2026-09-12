import Foundation

enum MockMIDI {
    // ---------------------------------------------------------------------
    // MARK: - Raw MIDI File Data Fixtures (as byte arrays)
    // ---------------------------------------------------------------------
    
    /// Raw MIDI data representing an empty MIDI file with format 0 and 0 ticks per quarter note.
    /// This corresponds to the original `emptyFile()` fixture.
    static let emptyFileData: [UInt8] = [
        0x4D, 0x54, 0x68, 0x64,             // Header chunk type "MThd"
        0x00, 0x00, 0x00, 0x06,             // Header length = 6 bytes
        0x00, 0x00,                         // Format 0 (single track)
        0x00, 0x01,                         // Number of tracks = 1
        0x01, 0xE0,                         // Division = 480 ticks per quarter note (0x01E0 = 480)
        
        0x4D, 0x54, 0x72, 0x6B,             // Track chunk type "MTrk"
        0x00, 0x00, 0x00, 0x04,             // Track chunk length = 4 bytes
        
        0x00,                               // Delta time 0
        0xFF, 0x2F, 0x00                    // End of Track meta event
    ]

    /// Raw malformed MIDI data (invalid header).
    /// This corresponds to the original `malformedFile()` fixture.
    static let malformedFileData: [UInt8] = [
        0x00, 0xFF, 0x00
    ]
    
    /// Raw MIDI data representing a single track with overlapping note events on C4.
    /// This corresponds to the original `overlappingNotesTrack()` fixture.
    static let overlappingNotesTrackData: [UInt8] = [
        // Header chunk
        0x4D, 0x54, 0x68, 0x64,             // "MThd"
        0x00, 0x00, 0x00, 0x06,             // header length 6 bytes
        0x00, 0x00,                         // format 0 (single track)
        0x00, 0x01,                         // 1 track
        0x01, 0xE0,                         // division 480 ticks per quarter note
        
        // Track chunk
        0x4D, 0x54, 0x72, 0x6B,             // "MTrk"
        0x00, 0x00, 0x00, 0x18,             // track length 24 bytes
        
        // Events:
        0x00,                               // delta 0
        0x90, 0x3C, 0x64,                   // Note On, channel 0, note 60 (C4), velocity 100
        
        0x0A,                               // delta 10
        0x90, 0x3C, 0x64,                   // Note On, channel 0, note 60, velocity 100 (overlapping)
        
        0x0A,                               // delta 10
        0x80, 0x3C, 0x00,                   // Note Off, channel 0, note 60, velocity 0
        
        0x0A,                               // delta 10
        0x80, 0x3C, 0x00,                   // Note Off, channel 0, note 60, velocity 0
        
        0x00,                               // delta 0
        0xFF, 0x00, 0x01, 0x00              // Sequence Number meta event, sequence = 0
    ]

    /// Raw MIDI data representing a track with no note events, only meta events.
    /// This corresponds to the original `noNotesTrack()` fixture.
    static let noNotesTrackData: [UInt8] = [
        // Header chunk
        0x4D, 0x54, 0x68, 0x64,
        0x00, 0x00, 0x00, 0x06,
        0x00, 0x00,
        0x00, 0x01,
        0x01, 0xE0,
        
        // Track chunk
        0x4D, 0x54, 0x72, 0x6B,
        0x00, 0x00, 0x00, 0x12,
        
        0x00,                               // delta 0
        0xFF, 0x03, 0x07,                   // Track/Sequence Name meta event, length 7
        0x4D, 0x65, 0x74, 0x61, 0x4F, 0x6E, 0x6C, 0x79, // "MetaOnly" (7 bytes)
        
        0x00,                               // delta 0
        0xFF, 0x59, 0x02,                   // Key Signature meta event, length 2
        0x00,                               // flatsOrSharps: 0
        0x00,                               // majorKey = true (0 = major)
        
        0x00,                               // delta 0
        0xFF, 0x00, 0x01, 0x00              // Sequence Number meta event, sequence = 0
    ]

    /// Raw MIDI data representing a drum track with a note on and note off on channel 9.
    /// This corresponds to the original `ambiguousDrumTrack()` fixture.
    static let ambiguousDrumTrackData: [UInt8] = [
        // Header chunk
        0x4D, 0x54, 0x68, 0x64,
        0x00, 0x00, 0x00, 0x06,
        0x00, 0x00,
        0x00, 0x01,
        0x01, 0xE0,
        
        // Track chunk
        0x4D, 0x54, 0x72, 0x6B,
        0x00, 0x00, 0x00, 0x15,
        
        0x00,                               // delta 0
        0xFF, 0x03, 0x05,                   // Track/Sequence Name meta event, length 5
        0x42, 0x65, 0x61, 0x74, 0x73,       // "Beats"
        
        0x00,                               // delta 0
        0x99, 0x15, 0x5A,                   // Note On, channel 9, note 21 (A1), velocity 90
        
        0xF0, 0x78,                         // delta 240 (240 decimal = 0xF0 0x78 in variable length quantity)
        0x89, 0x15, 0x00,                   // Note Off, channel 9, note 21, velocity 0
        
        0x00,                               // delta 0
        0xFF, 0x00, 0x01, 0x00              // Sequence Number meta event, sequence = 0
    ]
    
    // ---------------------------------------------------------------------
    // MARK: - Helper Methods
    // ---------------------------------------------------------------------
    
    /// Returns `Data` from the given `[UInt8]` MIDI byte array.
    static func data(from bytes: [UInt8]) -> Data {
        return Data(bytes)
    }
    
    static var emptyFile: Data { data(from: emptyFileData) }
    static var malformedFile: Data { data(from: malformedFileData) }
    static var overlappingNotesTrack: Data { data(from: overlappingNotesTrackData) }
    static var noNotesTrack: Data { data(from: noNotesTrackData) }
    static var ambiguousDrumTrack: Data { data(from: ambiguousDrumTrackData) }
}
