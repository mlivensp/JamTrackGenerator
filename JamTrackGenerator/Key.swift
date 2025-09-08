////
////  Key.swift
////  JamTrackGenerator
////
////  Created by Michael Livenspargar on 8/20/25.
////
//
//import Foundation
//
//struct Key {
//    let notes: [String]
//    
//    init(_ key: String) {
//        self.notes = Self.keys[key] ?? []
//    }
//    
//    subscript (index: ScaleDegree) -> String {
//        return notes[Int(index.rawValue)]
//    }
//    
//    var root: String {
//        notes.first ?? ""
//    }
//    
//    var second: String {
//        notes[2]
//    }
//    
//    var third: String {
//        notes[4]
//    }
//    
//    var fourth: String {
//        notes[5]
//    }
//    
//    var fifth: String {
//        notes[7]
//    }
//    
//    var sixth: String {
//        notes[9]
//    }
//    
//    var seventh: String {
//        notes[11]
//    }
//    
//    static let keys = [
//        "C": ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"],
//        "G": ["G", "G♯", "A", "A♯", "B", "C", "C♯", "D", "D♯", "E", "F", "F♯"],
//        "D": ["D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B", "C", "C♯"],
//        "A": ["A", "A♯", "B", "C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯"],
//        "E": ["E", "F", "F♯", "G", "G♯", "A", "A♯", "B", "C", "C♯", "D", "D♯"],
//        "B": ["B", "C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯"],
//        "F♯": ["F♯", "G", "G♯", "A", "A♯", "B", "C", "C♯", "D", "D♯", "E", "F"],
//        "C♯": ["C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B", "C"],
//        "G♭": ["G♭", "G", "A♭", "A", "B♭", "C♭", "C", "D♭", "D", "E♭", "E", "F"],
//        "D♭": ["D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B", "C"],
//        "A♭": ["A♭", "A", "B♭", "C♭", "C", "D♭", "D", "E♭", "E", "F", "G♭", "G"],
//        "E♭": ["E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B", "C", "D♭", "D"],
//        "B♭": ["B♭", "C♭", "C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A"],
//        "F": ["F", "G♭", "G", "A♭", "A", "B♭", "B", "C", "D♭", "D", "E♭", "E"]
//    ]
//}
