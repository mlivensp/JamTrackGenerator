//
//  SeedImporter.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/5/25.
//

import Foundation
import SwiftData

@MainActor
struct SeedImporter {
    func importSeedData(container: ModelContainer) {
        if let resourcePath = Bundle.main.resourcePath {
            let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath)
            print("Bundle contents: \(contents ?? [])")
        }

        let context = container.mainContext
        let styleMap = importStyleData(context: context)
        importFeelData(context: context)
        
        let scaleDegreeMap = importScaleDegreeData(context: context)
        let noteMap = importNoteData(context: context)
        importKeyData(context: context, scaleDegreeMap: scaleDegreeMap, noteMap: noteMap)
        
        importSongSectionData(context: context)
        importInstrumentData(context: context)
        
        let drumNoteMap = importDrumNoteData(context: context)
        importDrumPatternData(context: context, styleMap: styleMap, drumNoteMap: drumNoteMap)
        importHarmonicPatternData(context: context, styleMap: styleMap, scaleDegreeMap: scaleDegreeMap)
    }
    
    func importStyleData(context: ModelContext) -> [String: Style] {
        guard let styleURL = Bundle.main.url(forResource: "style", withExtension: "json")
        else {
            print("Failed to load style JSON file")
            return [:]
        }
        guard let styleData = try? Data(contentsOf: styleURL)
        else {
            print("Failed to read style JSON file")
            return [:]
        }

        guard let styleSeeds = try? JSONDecoder().decode([StyleSeed].self, from: styleData)
        else {
            print("Failed to decode style data")
            return [:]
        }
        
        var styleMap: [String: Style] = [:]
        for seed in styleSeeds {
            let style = Style(name: seed.name)
            styleMap[seed.name] = style
            context.insert(style)
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save styles: \(error.localizedDescription)")
        }

        return styleMap
    }
    
    func importFeelData(context: ModelContext) {
        guard let feelURL = Bundle.main.url(forResource: "feel", withExtension: "json")
        else {
            print("Failed to load feel JSON file")
            return
        }
              guard let feelData = try? Data(contentsOf: feelURL)
        else {
            print("Failed to read feel JSON file")
            return
        }
              guard let feelSeeds = try? JSONDecoder().decode([FeelSeed].self, from: feelData)
        else {
            print("Failed to decode feel JSON file")
            return
        }
        
        for feelSeed in feelSeeds {
            let feel = Feel(name: feelSeed.name)
            context.insert(feel)
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save feels: \(error.localizedDescription)")
        }
    }
    
    func importNoteData(context: ModelContext) -> [String:Note] {
        guard let noteURL = Bundle.main.url(forResource: "note", withExtension: "json")
        else {
            print("Failed to load note JSON file")
            return [:]
        }
              guard let noteData = try? Data(contentsOf: noteURL)
        else {
            print("Failed to read note JSON file")
            return [:]
        }
              guard let noteSeeds = try? JSONDecoder().decode([NoteSeed].self, from: noteData)
        else {
            print("Failed to decode note JSON file")
            return [:]
        }
        
        var noteMap: [String:Note] = [:]
        for seed in noteSeeds {
            let note = Note(name: seed.name, valueForMidiCalculation: seed.value)
            context.insert(note)
            noteMap[note.name] = note
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save notes: \(error.localizedDescription)")
        }
        return noteMap
    }
    
    func importScaleDegreeData(context: ModelContext) -> [String:ScaleDegree] {
        guard let scaleDegreeURL = Bundle.main.url(forResource: "scaleDegree", withExtension: "json"),
              let scaleDegreeData = try? Data(contentsOf: scaleDegreeURL),
              let scaleDegreeSeeds = try? JSONDecoder().decode([ScaleDegreeSeed].self, from: scaleDegreeData)
        else {
            print("Failed to load scale degree JSON file")
            return [:]
        }
        
        var scaleDegreeMap: [String:ScaleDegree] = [:]
        for seed in scaleDegreeSeeds {
            let scaleDegree = ScaleDegree(name: seed.name, ordinal: seed.ordinal)
            context.insert(scaleDegree)
            scaleDegreeMap[seed.name] = scaleDegree
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save scaleDegrees: \(error.localizedDescription)")
        }

        return scaleDegreeMap
    }

    func importKeyData(context: ModelContext, scaleDegreeMap: [String:ScaleDegree], noteMap: [String:Note]) {
        guard let keyURL = Bundle.main.url(forResource: "key", withExtension: "json")
        else {
            print("Failed to load key JSON file")
            return
        }
              guard let keyData = try? Data(contentsOf: keyURL)
        else {
            print("Failed to read key JSON file")
            return
        }
              guard let keySeeds = try? JSONDecoder().decode([KeySeed].self, from: keyData)
        else {
            print("Failed to decode key JSON file")
            return
        }
        
        for seed in keySeeds {
            let key = Key(name: seed.key)
            context.insert(key)
            
            for noteInKeySeed in seed.notes {
                guard let note = noteMap[noteInKeySeed.note] else {
                    fatalError("Missing note: \(noteInKeySeed.note)")
                }
                guard let degree = scaleDegreeMap[noteInKeySeed.scaleDegreeName] else {
                    fatalError("Missing scale degree: \(noteInKeySeed.scaleDegreeName)")
                }
                key.notes.append(NoteInKey(key: key, note: note, scaleDegree: degree))
            }
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save keys: \(error.localizedDescription)")
        }
    }
    
    func importSongSectionData(context: ModelContext) {
        guard let songSectionURL = Bundle.main.url(forResource: "songSection", withExtension: "json")
        else {
            print("Failed to load song section JSON file")
            return
        }
              guard let songSectionData = try? Data(contentsOf: songSectionURL)
        else {
            print("Failed to read song section JSON file")
            return
        }
              guard let songSectionSeeds = try? JSONDecoder().decode([SongSectionSeed].self, from: songSectionData)
        else {
            print("Failed to decode song section JSON file")
            return
        }
        
        for songSectionSeed in songSectionSeeds {
            let songSection = SongSection(name: songSectionSeed.name, sortOrder: songSectionSeed.sortOrder)
            context.insert(songSection)
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save songSections: \(error.localizedDescription)")
        }
    }
    
    func importInstrumentData(context: ModelContext) {
        guard let familyURL = Bundle.main.url(forResource: "instrumentFamilies", withExtension: "json"),
              let instrumentURL = Bundle.main.url(forResource: "instrument", withExtension: "json"),
              let familyData = try? Data(contentsOf: familyURL),
              let instrumentData = try? Data(contentsOf: instrumentURL),
              let familySeeds = try? JSONDecoder().decode([InstrumentFamilySeed].self, from: familyData),
              let instrumentSeeds = try? JSONDecoder().decode([InstrumentSeed].self, from: instrumentData)
        else {
            print("Failed to load JSON files")
            return
        }

        // Insert families
        var familyMap: [String: InstrumentFamily] = [:]
        for seed in familySeeds {
            let family = InstrumentFamily(name: seed.name)
            context.insert(family)
            familyMap[seed.name] = family
        }

        // Insert instruments
        for seed in instrumentSeeds {
            guard let instrumentFamily = familyMap[seed.family] else {
                fatalError("Unknown instrument family: \(seed.family)")
            }
            let instrument = Instrument(name: seed.name, programNumber: seed.programNumber, instrumentFamily: instrumentFamily)
            context.insert(instrument)
        }

        do {
            try context.save()
        } catch {
            fatalError("Failed to save instruments: \(error.localizedDescription)")
        }
    }
    
    func importDrumNoteData(context: ModelContext) -> [String: DrumNote] {
        guard let drumNoteURL = Bundle.main.url(forResource: "drumNote", withExtension: "json"),
              let drumNoteData = try? Data(contentsOf: drumNoteURL),
              let drumNoteSeeds = try? JSONDecoder().decode([DrumNoteSeed].self, from: drumNoteData)
        else {
            print("Failed to load drum note JSON file")
            return [:]
        }
        
        var drumNoteMap: [String: DrumNote] = [:]
        for drumNoteSeed in drumNoteSeeds {
            let drumNote = DrumNote(name: drumNoteSeed.name, midiValue: drumNoteSeed.value)
            drumNoteMap[drumNoteSeed.name] = drumNote
            context.insert(drumNote)
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save drumNotes: \(error.localizedDescription)")
        }
        return drumNoteMap
    }
    
    func importDrumPatternData(context: ModelContext, styleMap: [String: Style], drumNoteMap: [String: DrumNote]) {
        guard let drumPatternURL = Bundle.main.url(forResource: "drumPattern", withExtension: "json"),
              let drumPatternData = try? Data(contentsOf: drumPatternURL),
              let drumPatternSeeds = try? JSONDecoder().decode([DrumPatternSeed].self, from: drumPatternData)
        else {
            print("Failed to load drum pattern JSON file")
            return
        }
        
        for drumPatternSeed in drumPatternSeeds {
            let style = styleMap[drumPatternSeed.style]
            let drumPattern = DrumPattern(name: drumPatternSeed.name, style: style)
            context.insert(drumPattern)
            
            for drumNoteInPatternSeed in drumPatternSeed.notes {
                guard let drumNote = drumNoteMap[drumNoteInPatternSeed.drumNote] else {
                    fatalError("Missing drum note \(drumNoteInPatternSeed.drumNote)")
                }
                let drumNoteInPattern = DrumNoteInPattern(pattern: drumPattern, drumNote: drumNote, timestampOn: drumNoteInPatternSeed.timestampOn, timestampOff: drumNoteInPatternSeed.timestampOff)
                drumPattern.drumNotesInPattern.append(drumNoteInPattern)
            }
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save drumPatterns: \(error.localizedDescription)")
        }
    }
    
    func importHarmonicPatternData(context: ModelContext, styleMap: [String: Style], scaleDegreeMap: [String: ScaleDegree]) {
        guard let patternURL = Bundle.main.url(forResource: "harmonicPattern", withExtension: "json"),
              let patternData = try? Data(contentsOf: patternURL),
              let patternSeeds = try? JSONDecoder().decode([HarmonicPatternSeed].self, from: patternData)
        else {
            print("Failed to load pattern JSON file")
            return
        }
        
        for patternSeed in patternSeeds {
            guard let style = styleMap[patternSeed.style] else {
                fatalError("Missing style \(patternSeed.style)")
            }
            
            let pattern = HarmonicPattern(name: patternSeed.name, style: style)
            context.insert(pattern)
            
            for harmonicNoteInPatternSeed in patternSeed.notes {
                guard let scaleDegree = scaleDegreeMap[harmonicNoteInPatternSeed.scaleDegree] else {
                    fatalError("Missing scaleDegree \(harmonicNoteInPatternSeed.scaleDegree)")
                }
                
                let harmonicNoteInPattern = HarmonicNoteInPattern(pattern: pattern, scaleDegree: scaleDegree, octave: harmonicNoteInPatternSeed.octave, timestampOn: harmonicNoteInPatternSeed.timestampOn, timestampOff: harmonicNoteInPatternSeed.timestampOff)
                pattern.harmonicNotesInPattern.append(harmonicNoteInPattern)
            }
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save harmonicPatterns: \(error.localizedDescription)")
        }
    }
}
