//
//  HarmonicPattern+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/28/25.
//

import Foundation

extension HarmonicPattern {
    var sortedNotes: [SchemaV1.HarmonicNoteInPattern] {
        harmonicNotesInPattern.sorted { $0.timestampOn < $1.timestampOn }
    }

}
