import Foundation
import SwiftData

struct PatternImportSelection {
    let isSelected: Bool
    let useStyle: Bool
    let useFeel: Bool
    let patternName: String
}

enum PatternImportServiceError: LocalizedError {
    case message(String)
    
    var errorDescription: String? {
        switch self {
        case .message(let message):
            message
        }
    }
}

@MainActor
struct PatternImportService {
    let modelContext: ModelContext
    let drumNotes: [DrumNote]
    let trackNotes: [MidiTrackData]
    
    func validatePatternName(
        for track: MidiTrackData,
        selections: [MidiTrackData: PatternImportSelection],
        selectedStyle: Style?,
        selectedFeel: Feel?
    ) -> String? {
        let selection = selections[track] ?? PatternImportSelection(isSelected: false, useStyle: false, useFeel: false, patternName: "")
        let name = selection.patternName.trimmingCharacters(in: .whitespacesAndNewlines)
        let style = selection.useStyle ? selectedStyle : nil
        let feel = selection.useFeel ? selectedFeel : nil
        
        if !name.isEmpty && name.count < 2 {
            return "Pattern name must be at least 2 characters long."
        }
        
        let duplicateInTracks = trackNotes.filter { otherTrack in
            let otherSelection = selections[otherTrack] ?? PatternImportSelection(isSelected: false, useStyle: false, useFeel: false, patternName: "")
            return otherTrack != track &&
                otherSelection.isSelected &&
                otherSelection.patternName.trimmingCharacters(in: .whitespacesAndNewlines) == name &&
                (otherSelection.useStyle ? selectedStyle : nil) == style &&
                (otherSelection.useFeel ? selectedFeel : nil) == feel &&
                otherTrack.isDrumTrack == track.isDrumTrack
        }.count
        
        if duplicateInTracks > 0 {
            return "Pattern with name '\(name)', style '\(style?.name ?? "None")', and feel '\(feel?.name ?? "None")' is already in use among selected tracks."
        }
        
        do {
            if track.isDrumTrack {
                let patterns = try modelContext.fetch(FetchDescriptor<DrumPattern>(predicate: drumPatternPredicate(name: name, style: style, feel: feel)))
                if !patterns.isEmpty {
                    return "Pattern with name '\(name)', style '\(style?.name ?? "None")', and feel '\(feel?.name ?? "None")' already exists in the database."
                }
            } else {
                let patterns = try modelContext.fetch(FetchDescriptor<HarmonicPattern>(predicate: harmonicPatternPredicate(name: name, style: style, feel: feel)))
                if !patterns.isEmpty {
                    return "Pattern with name '\(name)', style '\(style?.name ?? "None")', and feel '\(feel?.name ?? "None")' already exists in the database."
                }
            }
        } catch {
            return "Failed to check for existing patterns: \(error.localizedDescription)"
        }
        
        return nil
    }
    
    func importSelectedTracks(
        selections: [MidiTrackData: PatternImportSelection],
        selectedStyle: Style?,
        selectedFeel: Feel?
    ) throws {
        let selectedTracks = trackNotes.filter { selections[$0]?.isSelected == true }
        
        guard !selectedTracks.isEmpty else {
            throw PatternImportServiceError.message("No tracks selected for import.")
        }
        
        for track in selectedTracks {
            let selection = selections[track] ?? PatternImportSelection(isSelected: false, useStyle: false, useFeel: false, patternName: "")
            let patternName = resolvedPatternName(for: track, selection: selection)
            let style = selection.useStyle ? selectedStyle : nil
            let feel = selection.useFeel ? selectedFeel : nil
            
            if track.isDrumTrack {
                guard let drumNotesInPattern = createDrumNotesInPattern(for: track) else {
                    throw PatternImportServiceError.message("Some tracks could not be imported due to invalid notes.")
                }
                
                let newDrumPattern = DrumPattern(name: patternName, style: style, feel: feel)
                drumNotesInPattern.forEach { $0.pattern = newDrumPattern }
                newDrumPattern.drumNotesInPattern = drumNotesInPattern
                modelContext.insert(newDrumPattern)
            } else {
                let baseOctave = track.notes.first.map { UInt8($0.note / 12 - 1) } ?? 4
                let keyNoteName = track.keySignature.hasSuffix("m") ? String(track.keySignature.dropLast()) : track.keySignature
                let rootMidiValue = calculateMidiValueForNote(noteName: keyNoteName, octave: baseOctave)
                
                guard rootMidiValue != 255,
                      let harmonicNotesInPattern = createHarmonicNotesInPattern(for: track, rootValue: rootMidiValue) else {
                    throw PatternImportServiceError.message("Some tracks could not be imported due to invalid notes.")
                }
                
                let newHarmonicPattern = HarmonicPattern(
                    name: patternName,
                    style: style,
                    feel: feel,
                    baseOctave: baseOctave
                )
                
                harmonicNotesInPattern.forEach { $0.pattern = newHarmonicPattern }
                newHarmonicPattern.harmonicNotesInPattern = harmonicNotesInPattern
                modelContext.insert(newHarmonicPattern)
            }
        }
        
        try modelContext.save()
    }
    
    private func resolvedPatternName(for track: MidiTrackData, selection: PatternImportSelection) -> String {
        let trimmedName = selection.patternName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return trimmedName
        }
        
        if let index = trackNotes.firstIndex(of: track), track.name.isEmpty {
            return "Imported Pattern \(index + 1)"
        }
        
        return track.name
    }
    
    private func calculateMidiValueForNote(noteName: String, octave: UInt8) -> UInt8 {
        let fetchDescriptor = FetchDescriptor<RawNote>(predicate: #Predicate { rawNote in
            rawNote.name == noteName
        })
        
        do {
            if let rawNote = try modelContext.fetch(fetchDescriptor).first {
                return (octave + 1) * 12 + rawNote.distanceFromC
            }
        } catch {
            return 255
        }
        
        return 255
    }
    
    private func createDrumNotesInPattern(for track: MidiTrackData) -> [DrumNoteInPattern]? {
        let drumNotesInPattern = track.notes.compactMap { midiNote -> DrumNoteInPattern? in
            guard let drumNote = drumNotes.first(where: { $0.midiValue == midiNote.note }) else {
                return nil
            }
            
            return DrumNoteInPattern(
                pattern: DrumPattern(name: "Imported"),
                drumNote: drumNote,
                timestampOn: UInt(midiNote.tickOn),
                timestampOff: UInt(midiNote.tickOff)
            )
        }
        
        return drumNotesInPattern.isEmpty ? nil : drumNotesInPattern
    }
    
    private func createHarmonicNotesInPattern(for track: MidiTrackData, rootValue: UInt8) -> [HarmonicNoteInPattern]? {
        let harmonicNotesInPattern = track.notes.compactMap { midiNote -> HarmonicNoteInPattern? in
            let halfSteps = Int8(midiNote.note) - Int8(rootValue)
            return HarmonicNoteInPattern(
                pattern: HarmonicPattern(name: "Temporary", style: nil, feel: nil, baseOctave: 4),
                halfSteps: halfSteps,
                timestampOn: UInt(midiNote.tickOn),
                timestampOff: UInt(midiNote.tickOff)
            )
        }
        
        return harmonicNotesInPattern.isEmpty ? nil : harmonicNotesInPattern
    }
    
    private func drumPatternPredicate(name: String, style: Style?, feel: Feel?) -> Predicate<DrumPattern> {
        let styleID = style?.id
        let feelID = feel?.id
        
        switch (styleID, feelID) {
        case (nil, nil):
            return #Predicate { pattern in
                pattern.name == name &&
                pattern.style == nil &&
                pattern.feel == nil
            }
        case (let styleID?, nil):
            return #Predicate { pattern in
                pattern.name == name &&
                pattern.style != nil &&
                pattern.style?.id == styleID &&
                pattern.feel == nil
            }
        case (nil, let feelID?):
            return #Predicate { pattern in
                pattern.name == name &&
                pattern.style == nil &&
                pattern.feel != nil &&
                pattern.feel?.id == feelID
            }
        case (let styleID?, let feelID?):
            return #Predicate { pattern in
                pattern.name == name &&
                pattern.style != nil &&
                pattern.style?.id == styleID &&
                pattern.feel != nil &&
                pattern.feel?.id == feelID
            }
        }
    }
    
    private func harmonicPatternPredicate(name: String, style: Style?, feel: Feel?) -> Predicate<HarmonicPattern> {
        let styleID = style?.id
        let feelID = feel?.id
        
        switch (styleID, feelID) {
        case (nil, nil):
            return #Predicate { pattern in
                pattern.name == name &&
                pattern.style == nil &&
                pattern.feel == nil
            }
        case (let styleID?, nil):
            return #Predicate { pattern in
                pattern.name == name &&
                pattern.style != nil &&
                pattern.style?.id == styleID &&
                pattern.feel == nil
            }
        case (nil, let feelID?):
            return #Predicate { pattern in
                pattern.name == name &&
                pattern.style == nil &&
                pattern.feel != nil &&
                pattern.feel?.id == feelID
            }
        case (let styleID?, let feelID?):
            return #Predicate { pattern in
                pattern.name == name &&
                pattern.style != nil &&
                pattern.style?.id == styleID &&
                pattern.feel != nil &&
                pattern.feel?.id == feelID
            }
        }
    }
}
