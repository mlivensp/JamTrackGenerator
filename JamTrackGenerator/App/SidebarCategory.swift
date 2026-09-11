//
//  SidebarCategory.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/13/25.
//

import Foundation

enum SidebarCategory: String, CaseIterable, Identifiable, Hashable {
    case jamTracks = "Jam Tracks"
    case styles = "Styles"
    case feels = "Feels"
    case drumPatterns = "Drum Patterns"
    case harmonicPatterns = "Harmonic Patterns"

    var id: String { rawValue }
}
