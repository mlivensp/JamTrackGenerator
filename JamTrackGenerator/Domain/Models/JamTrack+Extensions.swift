//
//  JamTrack+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/5/25.
//

import Foundation

extension JamTrack: Identifiable {}
extension JamTrack: Hashable {}

extension JamTrack {
    var sortedSections: [JamTrackSection] {
        self.jamTrackSections.sorted(by: { $0.order < $1.order })
    }
    
    var sortedParts: [Part] {
        self.parts.sorted(by: { $0.order < $1.order })
    }
    
    func addSection(songSection: SongSection) -> JamTrackSection {
        let order = ( self.jamTrackSections.map { $0.order }.max() ?? 0 ) + 1
        let section = JamTrackSection(jamTrack: self, songSection: songSection, order: order)
        jamTrackSections.append(section)
        songSection.sections.append(section)
        return section
    }
    
    func addSectionPart(section: JamTrackSection, part: Part, patternName: String) {
        let sectionPart = SectionPart(section: section, part: part, patternName: patternName)
        section.sectionParts.append(sectionPart)
    }
}
