//
//  SongSectionViewModel.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/1/25.
//

import Foundation

struct Section: Hashable, Identifiable, CustomStringConvertible {
    let id = UUID()
    let section: SongSection
    
    var description: String {
        section.description
    }
}
