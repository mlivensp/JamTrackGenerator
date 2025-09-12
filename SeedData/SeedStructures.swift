//
//  SeedStructures.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/5/25.
//

import Foundation

struct DrumNoteSeed: Codable {
    var name: String
    var value: UInt8
}

struct FeelSeed: Codable {
    var name: String
}

struct InstrumentSeed: Codable {
    var name: String
    var programNumber: UInt8
    var family: String
}

struct InstrumentFamilySeed: Codable {
    var name: String
}

struct ScaleDegreeSeed: Codable {
    var name: String
    var ordinal: Int
}

struct ScaledNoteSeed: Codable {
    var note: String
    var scaleDegreeName: String
}

struct KeySeed: Codable {
    var key: String
    var notes: [ScaledNoteSeed]
}

struct NoteSeed: Codable {
    var name: String
    var value: UInt8
}

struct SongSectionSeed: Codable {
    var name: String
    var sortOrder: UInt8
}

struct StyleSeed: Codable {
    var name: String
}

struct HarmonicNoteInPatternSeed: Codable {
    var scaleDegree: String
    var octave: UInt8
    var timestampOn: UInt
    var timestampOff: UInt
}

struct HarmonicPatternSeed: Codable {
    var name: String
    var style: String
    var feel: String
    var songSection: String
    var notes: [HarmonicNoteInPatternSeed]
}

struct DrumNoteInPatternSeed: Codable {
    var drumNote: String
    var timestampOn: UInt
    var timestampOff: UInt
}

struct DrumPatternSeed: Codable {
    var name: String
    var style: String
    var feel: String
    var songSection: String
    var notes: [DrumNoteInPatternSeed]
}
