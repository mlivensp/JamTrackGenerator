//
//  Definition+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/5/25.
//

import Foundation
import SwiftData

extension Definition {
    func addStyle(style: Style) {
        self.style = style
        style.definitions.append(self)
    }
    
    func addFeel(feel: Feel) {
        self.feel = feel
        feel.definitions.append(self)
    }
    
    func addKey(key: Key) {
        self.key = key
        key.definitions.append(self)
    }
    
    func addSection(songSection: SongSection) -> Section {
        let order = ( self.sections.map { $0.order }.max() ?? 0 ) + 1
        let section = Section(definition: self, songSection: songSection, order: order)
        sections.append(section)
        songSection.sections.append(section)
        return section
    }
    
    func addPart(instrument: Instrument) -> Part {
        let part = Part(definition: self, instrument: instrument)
        parts.append(part)
        instrument.parts.append(part)
        return part
    }
    
    func addSectionPart(section: Section, part: Part, patternName: String) {
        let sectionPart = SectionPart(section: section, part: part, patternName: patternName)
        section.sectionParts.append(sectionPart)
        part.sectionParts.append(sectionPart)
    }
    
    static func newDefinition(modelContext: ModelContext) -> Definition {
        let definition = Definition()
        definition.name = "New Jam Track"
        
        let styleFetchDescriptor = FetchDescriptor<Style>(predicate: #Predicate { style in
            style.name == "12 Bar Blues"
        })
                                                          
        let keysFetchDescriptor = FetchDescriptor<Key>(predicate: #Predicate { key in
            key.name == "A Major"
        })
                                                          
        let feelFetchDescriptor = FetchDescriptor<Feel>(predicate: #Predicate { feel in
            feel.name == "Shuffle"
        })
                                                          
        let songSectionCountInFetchDescriptor = FetchDescriptor<SongSection>(predicate: #Predicate { section in
            section.name == "Count In"
        })
        
        
        let songSectionChorusFetchDescriptor = FetchDescriptor<SongSection>(predicate: #Predicate { section in
            section.name == "Chorus"
        })

        let drumsFetchDescriptor = FetchDescriptor<Instrument>(predicate: #Predicate { instrument in
            instrument.name == "Drums"
        })
        
        let bassFetchDescriptor = FetchDescriptor<Instrument>(predicate: #Predicate { instrument in
            instrument.name == "Electric Bass (pick)"
        })
        
        let countInFetchDescriptor = FetchDescriptor<DrumPattern>(predicate: #Predicate { pattern in
            pattern.name == "Count In"
        })
        
        let basicBeatFetchDescriptor = FetchDescriptor<DrumPattern>(predicate: #Predicate { pattern in
            pattern.name == "Basic Beat"
        })
        
        let walkingBassFetchDescriptor = FetchDescriptor<HarmonicPattern>(predicate: #Predicate { pattern in
            pattern.name == "Walking Bass"
        })
        
        var sectionMap: [String: Section] = [:]
        var partMap: [String: Part] = [:]
        
        do {
            if let style = try modelContext.fetch(styleFetchDescriptor).first {
                definition.style = style
            }
            
            if let key = try modelContext.fetch(keysFetchDescriptor).first {
                definition.key = key
            }
            
            if let feel = try modelContext.fetch(feelFetchDescriptor).first {
                definition.feel = feel
            }
            
            if let countInSongSection = try modelContext.fetch(songSectionCountInFetchDescriptor).first {
                let section = definition.addSection(songSection: countInSongSection)
                sectionMap["Count In"] = section
            }

            if let chorusSongSection = try modelContext.fetch(songSectionChorusFetchDescriptor).first {
                let section = definition.addSection(songSection: chorusSongSection)
                sectionMap["Chorus"] = section
            }
            
            if let drums = try modelContext.fetch(drumsFetchDescriptor).first {
                let part = definition.addPart(instrument: drums)
                partMap["Drums"] = part
            }
            
            if let bass = try modelContext.fetch(bassFetchDescriptor).first {
                let part = definition.addPart(instrument: bass)
                partMap["Bass"] = part
            }
            
            if let countInPattern = try modelContext.fetch(countInFetchDescriptor).first {
                if let section = sectionMap["Count In"],
                   let part = partMap["Drums"] {
                    definition.addSectionPart(section: section, part: part, patternName: countInPattern.name)
                }
            }

            let basicBeatPatterns = try modelContext.fetch(basicBeatFetchDescriptor)
            
            if let basicBeatPattern = basicBeatPatterns.first(where: {
                $0.style?.name == "12 Bar Blues" && $0.feel?.name == "Shuffle"
            } ) {
                if let section = sectionMap["Chorus"],
                   let part = partMap["Drums"] {
                    definition.addSectionPart(section: section, part: part, patternName: basicBeatPattern.name)
                }
            }
            
            let walkingBassPatterns = try modelContext.fetch(walkingBassFetchDescriptor)
            
            if let walkingBassPattern = walkingBassPatterns.first(where: {
                $0.style?.name == "12 Bar Blues" && $0.feel?.name == "Shuffle"
            }) {
                if let section = sectionMap["Chorus"],
                   let part = partMap["Bass"] {
                    definition.addSectionPart(section: section, part: part, patternName: walkingBassPattern.name)
                }
            }
        } catch {
            fatalError("Fatal error fetching Definition defaults: \(error.localizedDescription)")
        }

        return definition
    }
    
    func createMidiDocument(modelContext: ModelContext) -> MidiDocument {
        var song = Song(modelContext: modelContext)
        song.buildTracks(definition: self)
        var document = MidiDocument(song: song, bpm: bpm)
        document.encodeMidi()
        return document
    }
    

    func encodeToMidi(modelContext: ModelContext) -> Data {
        var document = createMidiDocument(modelContext: modelContext)
        let midiData = document.encodeMidiToData()
        return Data(midiData)
    }
}
