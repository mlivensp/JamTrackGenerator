//
//  Feel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/30/25.
//

import Foundation

enum Feel: CaseIterable, Identifiable, CustomStringConvertible {
    case straight
    case shuffle
    case slow
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .straight:
            return "Straight"
        case .shuffle:
            return "Shuffle"
        case .slow:
            return "Slow"
        }
    }
}
