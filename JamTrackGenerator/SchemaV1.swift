//
//  SchemaV1.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/4/25.
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        
    ]
    
    @Model class Style {
        var name: String
        
        @Relationship(deleteRule: .cascade, inverse: \DrumPattern.style) var drumPatterns: [DrumPattern]
        @Relationship(deleteRule: .cascade, inverse: \HarmonicPattern.style) var harmonicPatterns: [HarmonicPattern]
        @Relationship(deleteRule: .cascade, inverse: \Definition.style) var definitions: [Definition]
        
        init(name: String, drumPatterns: [DrumPattern] = [], harmonicPatterns: [HarmonicPattern] = [], definitions: [Definition] = []) {
            self.name = name
            self.drumPatterns = drumPatterns
            self.harmonicPatterns = harmonicPatterns
            self.definitions = definitions
        }
    }

    @Model class Feel {
        var name: String
        
        @Relationship(deleteRule: .nullify, inverse: \DrumPattern.feel) var drumPatterns: [DrumPattern]
        @Relationship(deleteRule: .nullify, inverse: \HarmonicPattern.feel) var harmonicPatterns: [HarmonicPattern]
        @Relationship(deleteRule: .nullify, inverse: \Definition.feel) var definitions: [Definition]
        
        init(name: String, drumPatterns: [DrumPattern] = [], harmonicPatterns: [HarmonicPattern] = [], definitions: [Definition] = []) {
            self.name = name
            self.drumPatterns = drumPatterns
            self.harmonicPatterns = harmonicPatterns
            self.definitions = definitions
        }
    }

    @Model class Note {
        var name: String
        var valueForMidiCalculation: UInt8
        
        @Relationship(deleteRule: .nullify, inverse: \NoteInKey.note) var noteInKeys: [NoteInKey]
        
        init(name: String, valueForMidiCalculation: UInt8, noteInKeys: [NoteInKey] = []) {
            self.name = name
            self.valueForMidiCalculation = valueForMidiCalculation
            self.noteInKeys = noteInKeys
        }
    }

    @Model class Key {
        var name: String
        
        @Relationship(deleteRule: .cascade, inverse: \Definition.key) var definitions: [Definition]
        @Relationship(deleteRule: .cascade, inverse: \NoteInKey.key) var notes: [NoteInKey]
        
        init(name: String, definitions: [Definition] = [], notes: [NoteInKey] = []) {
            self.name = name
            self.definitions = definitions
            self.notes = notes
        }
    }
    
    @Model class NoteInKey {
        var key: Key?
        var note: Note?
        var scaleDegree: ScaleDegree?
        
        init(key: Key, note: Note, scaleDegree: ScaleDegree) {
            self.key = key
            self.note = note
            self.scaleDegree = scaleDegree
        }
    }
    
    @Model class SongSection {
        var name: String
        var sortOrder: UInt8
        
        @Relationship(deleteRule: .nullify, inverse: \Section.songSection) var sections: [Section]
        
        init(name: String, sortOrder: UInt8, sections: [Section] = []) {
            self.name = name
            self.sortOrder = sortOrder
            self.sections = sections
        }
    }
    
    @Model class Section {
        var definition: Definition?
        var songSection: SongSection?
        var order: UInt8
        
        @Relationship(deleteRule: .cascade, inverse: \SectionPart.section) var sectionParts: [SectionPart]
        
        init(definition: Definition?, songSection: SongSection, order: UInt8, sectionParts: [SectionPart] = []) {
            self.definition = definition
            self.songSection = songSection
            self.order = order
            self.sectionParts = sectionParts
        }
    }
    
    @Model class InstrumentFamily {
        var name: String
        
        @Relationship(deleteRule: .nullify, inverse: \Instrument.instrumentFamily) var instruments: [Instrument]
        
        init(name: String, instruments: [Instrument] = []) {
            self.name = name
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
        var definition: Definition?
        var instrument: Instrument?
        
        @Relationship(deleteRule: .cascade, inverse: \SectionPart.part) var sectionParts: [SectionPart]
        
        init(definition: Definition, instrument: Instrument, sectionParts: [SectionPart] = []) {
            self.instrument = instrument
            self.definition = definition
            self.sectionParts = sectionParts
        }
    }

    @Model class Definition {
        var name: String
        var style: Style?
        var key: Key?
        var feel: Feel?
        var bpm: UInt8
        var includeCountIn: Bool
        
        @Relationship(deleteRule: .cascade, inverse: \Section.definition) var sections: [Section]
        @Relationship(deleteRule: .cascade, inverse: \Part.definition) var parts: [Part]
        
        init(name: String = "", style: Style? = nil, key: Key? = nil, feel: Feel? = nil, bpm: UInt8 = 120, includeCountIn: Bool = true, sections: [Section] = [], parts: [Part] = [], sectionPartPatterns: [SectionPart] = []) {
            self.name = name
            self.style = style
            self.key = key
            self.feel = feel
            self.bpm = bpm
            self.includeCountIn = includeCountIn
            self.sections = sections
            self.parts = parts
        }
    }
    
    @Model class ScaleDegree {
        var name: String
        var ordinal: Int
        
        @Relationship(deleteRule: .cascade, inverse: \NoteInKey.scaleDegree) var noteInKeys: [NoteInKey]
        @Relationship(deleteRule: .cascade, inverse: \HarmonicNoteInPattern.scaleDegree) var harmonicNotesInPattern: [HarmonicNoteInPattern]
        
        init(name: String, ordinal: Int, noteInKeys: [NoteInKey] = [], harmonicNotesInPattern: [HarmonicNoteInPattern] = []) {
            self.name = name
            self.ordinal = ordinal
            self.noteInKeys = noteInKeys
            self.harmonicNotesInPattern = harmonicNotesInPattern
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
        var name: String
        var style: Style?
        var feel: Feel?
        
        @Relationship(deleteRule: .cascade, inverse: \DrumNoteInPattern.pattern) var drumNotesInPattern: [DrumNoteInPattern]
        
        init(name: String, style: Style?, feel: Feel?, drumNotesInPattern: [DrumNoteInPattern] = []) {
            self.name = name
            self.style = style
            self.feel = feel
            self.drumNotesInPattern = drumNotesInPattern
        }
    }
    
    @Model class HarmonicNoteInPattern {
        var pattern: HarmonicPattern?
        var scaleDegree: ScaleDegree?
        var octave: UInt8
        var timestampOn: UInt
        var timestampOff: UInt
        
        init(pattern: HarmonicPattern, scaleDegree: ScaleDegree?, octave: UInt8, timestampOn: UInt, timestampOff: UInt) {
            self.pattern = pattern
            self.scaleDegree = scaleDegree
            self.octave = octave
            self.timestampOn = timestampOn
            self.timestampOff = timestampOff
        }
    }

    @Model class HarmonicPattern {
        var name: String
        var style: Style?
        var feel: Feel?
        
        @Relationship(deleteRule: .cascade, inverse: \HarmonicNoteInPattern.pattern) var harmonicNotesInPattern: [HarmonicNoteInPattern]
        
        init(name: String, style: Style?, feel: Feel?, harmonicNotesInPattern: [HarmonicNoteInPattern] = []) {
            self.name = name
            self.style = style
            self.feel = feel
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
        var section: Section?
        var part: Part?
        var patternName: String
        
        init(section: Section, part: Part, patternName: String) {
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
