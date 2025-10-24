//
//  SchemaV1.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/4/25.
//

import Foundation
import SwiftData
import SwiftUI

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        
    ]
    
    @Model class Style {
        var name: String
        
        @Relationship(deleteRule: .cascade, inverse: \DrumPattern.style) var drumPatterns: [DrumPattern]
        @Relationship(deleteRule: .cascade, inverse: \HarmonicPattern.style) var harmonicPatterns: [HarmonicPattern]
        @Relationship(deleteRule: .cascade, inverse: \JamTrack.style) var jamTracks: [JamTrack]
        
        init(name: String, drumPatterns: [DrumPattern] = [], harmonicPatterns: [HarmonicPattern] = [], jamTracks: [JamTrack] = []) {
            self.name = name
            self.drumPatterns = drumPatterns
            self.harmonicPatterns = harmonicPatterns
            self.jamTracks = jamTracks
        }
    }

    @Model class Feel {
        var name: String
        
        @Relationship(deleteRule: .nullify, inverse: \DrumPattern.feel) var drumPatterns: [DrumPattern]
        @Relationship(deleteRule: .nullify, inverse: \HarmonicPattern.feel) var harmonicPatterns: [HarmonicPattern]
        @Relationship(deleteRule: .nullify, inverse: \JamTrack.feel) var definitions: [JamTrack]
        
        init(name: String, drumPatterns: [DrumPattern] = [], harmonicPatterns: [HarmonicPattern] = [], definitions: [JamTrack] = []) {
            self.name = name
            self.drumPatterns = drumPatterns
            self.harmonicPatterns = harmonicPatterns
            self.definitions = definitions
        }
    }

    @Model class RawNote {
        var name: String
        var distanceFromC: UInt8
        
        @Relationship(deleteRule: .nullify, inverse: \NoteInKey.rawNote) var noteInKeys: [NoteInKey]
        
        init(name: String, distanceFromC: UInt8, noteInKeys: [NoteInKey] = []) {
            self.name = name
            self.distanceFromC = distanceFromC
            self.noteInKeys = noteInKeys
        }
    }

    @Model class Key {
        var noteName: String
        var sharpsOrFlats: Int8
        var isMajor: Bool
        
        @Relationship(deleteRule: .cascade, inverse: \JamTrack.key) var definitions: [JamTrack]
        @Relationship(deleteRule: .cascade, inverse: \NoteInKey.key) var notesInKey: [NoteInKey]
        
        init(noteName: String, sharpsOrFlats: Int8, isMajor: Bool, definitions: [JamTrack] = [], notesInKey: [NoteInKey] = []) {
            self.noteName = noteName
            self.sharpsOrFlats = sharpsOrFlats
            self.isMajor = isMajor
            self.definitions = definitions
            self.notesInKey = notesInKey
        }
    }
    
    @Model class NoteInKey {
        var key: Key?
        var rawNote: RawNote?
        var scaleDegree: ScaleDegree?
        
        init(key: Key, rawNote: RawNote, scaleDegree: ScaleDegree) {
            self.key = key
            self.rawNote = rawNote
            self.scaleDegree = scaleDegree
        }
    }
    
    @Model class SongSection {
        var name: String
        var sortOrder: UInt8
        
        @Relationship(deleteRule: .nullify, inverse: \JamTrackSection.songSection) var sections: [JamTrackSection]
        
        init(name: String, sortOrder: UInt8, sections: [JamTrackSection] = []) {
            self.name = name
            self.sortOrder = sortOrder
            self.sections = sections
        }
    }
    
    @Model class JamTrackSection {
        var jamTrack: JamTrack?
        var songSection: SongSection?
        // TODO: add number of times to repeat
        var order: UInt8
        @Transient var uuid: UUID = UUID()

        @Relationship(deleteRule: .cascade, inverse: \SectionPart.section) var sectionParts: [SectionPart]
        
        init(jamTrack: JamTrack?, songSection: SongSection, order: UInt8, sectionParts: [SectionPart] = []) {
            self.jamTrack = jamTrack
            self.songSection = songSection
            self.order = order
            self.sectionParts = sectionParts
        }
    }
    
    @Model class InstrumentFamily {
        var name: String
        var sortOrder: Int
        
        @Relationship(deleteRule: .nullify, inverse: \Instrument.instrumentFamily) var instruments: [Instrument]
        
        init(name: String, sortOrder: Int, instruments: [Instrument] = []) {
            self.name = name
            self.sortOrder = sortOrder
            self.instruments = instruments
        }
    }

    @Model class Instrument {
        var name: String
        var programNumber: UInt8
        var instrumentFamily: InstrumentFamily?
        
        @Relationship(deleteRule: .cascade, inverse: \Part.instrument) var parts: [Part]
        
        init(name: String, programNumber: UInt8, instrumentFamily: InstrumentFamily?, parts: [Part] = []) {
            self.name = name
            self.programNumber = programNumber
            self.instrumentFamily = instrumentFamily
            self.parts = parts
        }
    }
    
    @Model class Part {
        var jamTrack: JamTrack?
        var instrument: Instrument? {
            didSet {
                print("instrument changed to \(String(describing: instrument?.name ?? "nil"))")
            }
        }
        var order: Int
        @Transient var uuid: UUID = UUID()

        @Relationship(deleteRule: .cascade, inverse: \SectionPart.part) var sectionParts: [SectionPart]
        
        init(jamTrack: JamTrack, instrument: Instrument, order: Int = 0, sectionParts: [SectionPart] = []) {
            self.instrument = instrument
            self.order = order
            self.jamTrack = jamTrack
            self.sectionParts = sectionParts
        }
    }

    @Model class JamTrack {
        var name: String
        var style: Style?
        var key: Key?
        var feel: Feel?
        var bpm: UInt8
        var includeCountIn: Bool
        
        @Relationship(deleteRule: .cascade, inverse: \JamTrackSection.jamTrack) var jamTrackSections: [JamTrackSection]
        // TODO: I really want this to be private but I haven't found a way to make a binding to the parts array work
        @Relationship(deleteRule: .cascade, inverse: \Part.jamTrack) var parts: [Part]
        
        init(name: String = "", style: Style? = nil, key: Key? = nil, feel: Feel? = nil, bpm: UInt8 = 120, includeCountIn: Bool = true, jamTrackSections: [JamTrackSection] = [], parts: [Part] = [], sectionPartPatterns: [SectionPart] = []) {
            self.name = name
            self.style = style
            self.key = key
            self.feel = feel
            self.bpm = bpm
            self.includeCountIn = includeCountIn
            self.jamTrackSections = jamTrackSections
            self.parts = parts
        }
        
        func addPart(instrument: Instrument) -> Part {
            let maxOrder = parts.map(\.order).max() ?? 0
            let part = Part(jamTrack: self, instrument: instrument, order: maxOrder + 1)
            parts.append(part)
            return part
        }

        func deletePart(part: Part) {
            if let partIndex = parts.firstIndex(of: part) {
                parts.remove(at: partIndex)
            }
        }
    }
    
    @Model class ScaleDegree {
        var name: String
        var ordinal: UInt8
        
        @Relationship(deleteRule: .cascade, inverse: \NoteInKey.scaleDegree) var noteInKeys: [NoteInKey]
        
        init(name: String, ordinal: UInt8, noteInKeys: [NoteInKey] = []) {
            self.name = name
            self.ordinal = ordinal
            self.noteInKeys = noteInKeys
        }
    }
    
    @Model class DrumNoteInPattern {
        var pattern: DrumPattern?
        var drumNote: DrumNote?
        var timestampOn: UInt
        var timestampOff: UInt
        
        init(pattern: DrumPattern, drumNote: DrumNote?, timestampOn: UInt, timestampOff: UInt) {
            self.pattern = pattern
            self.drumNote = drumNote
            self.timestampOn = timestampOn
            self.timestampOff = timestampOff
        }
    }
    
    @Model class DrumPattern {
        var id: UUID = UUID()
        var name: String
        var style: Style?
        var feel: Feel?
        
        @Relationship(deleteRule: .cascade, inverse: \DrumNoteInPattern.pattern) var drumNotesInPattern: [DrumNoteInPattern]
        
        init(name: String = "", style: Style? = nil, feel: Feel? = nil, drumNotesInPattern: [DrumNoteInPattern] = []) {
            self.name = name
            self.style = style
            self.feel = feel
            self.drumNotesInPattern = drumNotesInPattern
        }
    }
    
    @Model class HarmonicNoteInPattern {
        var pattern: HarmonicPattern?
        var halfSteps: Int8
        var timestampOn: UInt
        var timestampOff: UInt
        
        init(pattern: HarmonicPattern, halfSteps: Int8, timestampOn: UInt, timestampOff: UInt) {
            self.pattern = pattern
            self.halfSteps = halfSteps
            self.timestampOn = timestampOn
            self.timestampOff = timestampOff
        }
    }

    @Model class HarmonicPattern {
        var id: UUID = UUID()
        var name: String
        var style: Style?
        var feel: Feel?
        var baseOctave: UInt8
        
        @Relationship(deleteRule: .cascade, inverse: \HarmonicNoteInPattern.pattern) var harmonicNotesInPattern: [HarmonicNoteInPattern]
        
        init(name: String, style: Style?, feel: Feel?, baseOctave: UInt8, harmonicNotesInPattern: [HarmonicNoteInPattern] = []) {
            self.name = name
            self.style = style
            self.feel = feel
            self.baseOctave = baseOctave
            self.harmonicNotesInPattern = harmonicNotesInPattern
            
            if let style {
                style.harmonicPatterns.append(self)
            }
            
            if let feel {
                feel.harmonicPatterns.append(self)
            }
        }
    }
    
    @Model class SectionPart {
        var section: JamTrackSection?
        var part: Part?
        var patternName: String
        
        init(section: JamTrackSection, part: Part, patternName: String) {
            self.section = section
            self.part = part
            self.patternName = patternName
        }
    }
    
    @Model class DrumNote {
        var name: String
        var midiValue: UInt8
        
        init(name: String, midiValue: UInt8) {
            self.name = name
            self.midiValue = midiValue
        }
    }
}
