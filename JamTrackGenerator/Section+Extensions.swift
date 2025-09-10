//
//  Section+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/8/25.
//

import Foundation

extension Section {
    func addSongSection(songSection: SongSection) {
        self.songSection = songSection
        songSection.sections.append(self)
    }
}
