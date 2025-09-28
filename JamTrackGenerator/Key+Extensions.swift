//
//  Key+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/6/25.
//

import Foundation

extension Key {
    subscript (_ ordinal: Int8) -> NoteInKey {
        guard ordinal >= 0 && ordinal < 12 else {
            fatalError("ordinal is out of range for key[ordinal]: \(ordinal)")
        }
        let sortedNotes = notesInKey.sorted { $0.sortOrder < $1.sortOrder }
//        print("\(sortedNotes[0].description) \(sortedNotes[1].description) \(sortedNotes[2].description) \(sortedNotes[3].description) \(sortedNotes[4].description) \(sortedNotes[5].description) \(sortedNotes[6].description) \(sortedNotes[7].description)")
//        for noteInKey in sortedNotes {
//            print("\(self.name): \(noteInKey.description), \(noteInKey.scaleDegree?.name ?? "nil")")
//        }
//        let value = sortedNotes[Int(ordinal)]
//        print("\(self.name): \(value.description)")
        return sortedNotes[Int(ordinal)]
    }
    
    func addNoteInKey(_ noteInKey: NoteInKey) {
        noteInKey.key = self
        notesInKey.append(noteInKey)
    }
    
    func pitchedNote(distanceFromRoot halfSteps: Int8, octave: UInt8 = 0) -> PitchedNote {
        guard let root = notesInKey.first(where: { $0.scaleDegree?.name == "Root" } ) else {
            fatalError("root not found for key \(self.noteName)")
        }
        
        guard let rawRootNote = root.rawNote else {
            fatalError("note not found on root in key \(self.noteName)")
        }
        
        var signedHalfSteps: Int8 = 0
        let rawHalfSteps: Int8
        let octaveIncrementer: Int8
        var relativeDistanceFromC: Int8
        
        if halfSteps < 0 {
            relativeDistanceFromC = Int8(rawRootNote.distanceFromC) + halfSteps
//            print("relativeDistanceFromC: \(relativeDistanceFromC)")
            octaveIncrementer = (relativeDistanceFromC / 12) - (relativeDistanceFromC < 0 ? 1 : 0)
            signedHalfSteps = 12 + halfSteps
            if signedHalfSteps < 0 {
                rawHalfSteps = abs(signedHalfSteps)
            } else {
                rawHalfSteps = signedHalfSteps
            }
        } else {
            rawHalfSteps = halfSteps
            relativeDistanceFromC = 0
            octaveIncrementer = (Int8(rawRootNote.distanceFromC) + halfSteps) / 12
        }
        
        let noteNumber = rawHalfSteps % 12
        let newNoteInKey = self[noteNumber]
//        print("octaveIncrementer: \(octaveIncrementer)")
        let newOctave = UInt8(Int8(octave) + octaveIncrementer)
        guard let newRawNote = newNoteInKey.rawNote else {
            fatalError("no rawNote for noteInKey")
        }
        
        let pitchedNote = PitchedNote(rawNote: newRawNote, octave: newOctave)
//        print(#function, "root: \(root) halfSteps: \(halfSteps) signedHalfSteps: \(signedHalfSteps) rawHalfSteps: \(rawHalfSteps) noteNumber: \(noteNumber) relativeDistanceFromC: \(relativeDistanceFromC) octaveIncrementer: \(octaveIncrementer) newOctave: \(newOctave) newRawNote: \(newRawNote) pitchedNote: \(pitchedNote)")

        print("octave: \(octave) octaveIncrementer: \(octaveIncrementer) note: \(pitchedNote.description)")
        return pitchedNote
    }
}
//    func noteOfDegree(scaleDegree: ScaleDegree) -> RawNote {
//        let sortedNotes = notes.sorted { $0.sortOrder < $1.sortOrder }
//        return sortedNotes[scaleDegree.ordinal].rawNote ?? RawNote(name: "Unknown", valueForMidiCalculation: 0)
//    }
//    
//    var root: RawNote {
//        let sortedNotes = notes.sorted { $0.sortOrder < $1.sortOrder }
//        return sortedNotes[0].rawNote ?? RawNote(name: "Unknown", valueForMidiCalculation: 0)
//    }
//    
//    var fourth: RawNote {
//        let sortedNotes = notes.sorted { $0.sortOrder < $1.sortOrder }
//        return sortedNotes[3].rawNote ?? RawNote(name: "Unknown", valueForMidiCalculation: 0)
//    }
//    
//    var fifth: RawNote {
//        let sortedNotes = notes.sorted { $0.sortOrder < $1.sortOrder }
//        return sortedNotes[4].rawNote ?? RawNote(name: "Unknown", valueForMidiCalculation: 0)
//    }
//}
