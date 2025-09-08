//
//  Key+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/5/25.
//

import Foundation

extension NoteInKey {
    var sortOrder: Int {
        scaleDegree?.ordinal ?? 0
    }
    
    subscript (scaleDegree: ScaleDegree) -> String {
        guard let noteInKey = key?.notes.first(where: { $0.scaleDegree == scaleDegree } ) else {
            fatalError("Missing note with scaleDegree \(scaleDegree.name) in key \(key?.name ?? "")")
        }
        
        return noteInKey.note?.name ?? ""
    }
}
