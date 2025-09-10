//
//  Global.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/27/25.
//

import Foundation

typealias Pulse = UInt32
typealias Velocity = UInt8
typealias Octave = UInt8

typealias Style = SchemaV1.Style
typealias Note = SchemaV1.Note
typealias Key = SchemaV1.Key
typealias NoteInKey = SchemaV1.NoteInKey
typealias ScaleDegree = SchemaV1.ScaleDegree
typealias Feel = SchemaV1.Feel
typealias SongSection = SchemaV1.SongSection
typealias Section = SchemaV1.Section
typealias HarmonicPattern = SchemaV1.HarmonicPattern
typealias HarmonicNoteInPattern = SchemaV1.HarmonicNoteInPattern
typealias InstrumentFamily = SchemaV1.InstrumentFamily
typealias Instrument = SchemaV1.Instrument
typealias Part = SchemaV1.Part
typealias Definition = SchemaV1.Definition
typealias SectionPart = SchemaV1.SectionPart
typealias DrumNote = SchemaV1.DrumNote
typealias DrumNoteInPattern = SchemaV1.DrumNoteInPattern
typealias DrumPattern = SchemaV1.DrumPattern


let currentSchema = SchemaV1.self

struct Global {
    static let pulsesPerQuarterNote: UInt32 = 480
}


extension String {
    func camelCaseToCapitalizedWords() -> String {
        var words: [String] = []
        var currentWord = ""
        
        // Iterate through each character
        for (index, char) in self.enumerated() {
            // If character is uppercase and not the first character, start new word
            if char.isUppercase && !currentWord.isEmpty {
                words.append(currentWord)
                currentWord = String(char)
            } else {
                currentWord.append(char)
            }
            
            // Add the last word if we're at the end
            if index == self.count - 1 {
                words.append(currentWord)
            }
        }
        
        // Capitalize each word and join with spaces
        return words
            .filter { !$0.isEmpty }
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
