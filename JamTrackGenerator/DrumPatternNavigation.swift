//
//  DrumPatternNavigation.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/18/25.
//

import Foundation

enum DrumPatternNavigation: Hashable {
    case existing(DrumPattern)
    case importOptions([MidiTrackData])
}

extension DrumPatternNavigation: CustomStringConvertible {
    var description: String {
        switch self {
        case .existing(let pattern):
            return "Existing: \(pattern)"
        case .importOptions(_):
            return "Import Options: [...]"
        }
    }
}
