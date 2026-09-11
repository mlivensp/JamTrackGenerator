import SwiftData

enum JamTrackTemplateService {
    static func makeDefaultJamTrack(in modelContext: ModelContext) -> JamTrack {
        let jamTrack = JamTrack()
        jamTrack.name = "New Jam Track"
        
        let styleFetchDescriptor = FetchDescriptor<Style>(predicate: #Predicate { style in
            style.name == "12 Bar Blues"
        })
        
        let keyFetchDescriptor = FetchDescriptor<Key>(predicate: #Predicate { key in
            key.noteName == "A" && key.isMajor == true
        })
        
        let feelFetchDescriptor = FetchDescriptor<Feel>(predicate: #Predicate { feel in
            feel.name == "Shuffle"
        })
        
        let countInSectionFetchDescriptor = FetchDescriptor<SongSection>(predicate: #Predicate { section in
            section.name == "Count In"
        })
        
        let chorusSectionFetchDescriptor = FetchDescriptor<SongSection>(predicate: #Predicate { section in
            section.name == "Chorus"
        })
        
        let drumsFetchDescriptor = FetchDescriptor<Instrument>(predicate: #Predicate { instrument in
            instrument.name == "Drums"
        })
        
        let bassFetchDescriptor = FetchDescriptor<Instrument>(predicate: #Predicate { instrument in
            instrument.name == "Electric Bass (pick)"
        })
        
        let countInPatternFetchDescriptor = FetchDescriptor<DrumPattern>(predicate: #Predicate { pattern in
            pattern.name == "Count In"
        })
        
        let basicBeatFetchDescriptor = FetchDescriptor<DrumPattern>(predicate: #Predicate { pattern in
            pattern.name == "Basic Beat"
        })
        
        let bassLineFetchDescriptor = FetchDescriptor<HarmonicPattern>(predicate: #Predicate { pattern in
            pattern.name == "Bass Line"
        })
        
        var sectionMap: [String: JamTrackSection] = [:]
        var partMap: [String: Part] = [:]
        
        do {
            jamTrack.style = try modelContext.fetch(styleFetchDescriptor).first
            jamTrack.key = try modelContext.fetch(keyFetchDescriptor).first
            jamTrack.feel = try modelContext.fetch(feelFetchDescriptor).first
            
            if let countInSection = try modelContext.fetch(countInSectionFetchDescriptor).first {
                sectionMap["Count In"] = jamTrack.addSection(songSection: countInSection)
            }
            
            if let chorusSection = try modelContext.fetch(chorusSectionFetchDescriptor).first {
                sectionMap["Chorus"] = jamTrack.addSection(songSection: chorusSection)
            }
            
            if let drums = try modelContext.fetch(drumsFetchDescriptor).first {
                partMap["Drums"] = jamTrack.addPart(instrument: drums)
            }
            
            if let bass = try modelContext.fetch(bassFetchDescriptor).first {
                partMap["Bass"] = jamTrack.addPart(instrument: bass)
            }
            
            if let countInPattern = try modelContext.fetch(countInPatternFetchDescriptor).first,
               let section = sectionMap["Count In"],
               let part = partMap["Drums"] {
                jamTrack.addSectionPart(section: section, part: part, patternName: countInPattern.name)
            }
            
            let basicBeatPatterns = try modelContext.fetch(basicBeatFetchDescriptor)
            if let basicBeatPattern = basicBeatPatterns.first(where: {
                $0.style?.name == "12 Bar Blues" && $0.feel?.name == "Shuffle"
            }),
               let section = sectionMap["Chorus"],
               let part = partMap["Drums"] {
                jamTrack.addSectionPart(section: section, part: part, patternName: basicBeatPattern.name)
            }
            
            let bassLinePatterns = try modelContext.fetch(bassLineFetchDescriptor)
            if let bassLinePattern = bassLinePatterns.first(where: {
                $0.style?.name == "12 Bar Blues" && $0.feel?.name == "Shuffle"
            }),
               let section = sectionMap["Chorus"],
               let part = partMap["Bass"] {
                jamTrack.addSectionPart(section: section, part: part, patternName: bassLinePattern.name)
            }
        } catch {
            fatalError("Fatal error fetching JamTrack defaults: \(error.localizedDescription)")
        }
        
        return jamTrack
    }
}
