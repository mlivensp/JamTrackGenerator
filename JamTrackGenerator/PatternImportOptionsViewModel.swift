import SwiftData
import Foundation

extension PatternImportOptionsView {
    @Observable class ViewModel {
        private var modelContext: ModelContext!
        private let drumNotes: [DrumNote]
        private let styles: [Style]
        private let feels: [Feel]
        let trackNotes: [MidiTrackData]
        
        var selectedTracks: [MidiTrackData: Bool] = [:]
        var useStyleForTrack: [MidiTrackData: Bool] = [:]
        var useFeelForTrack: [MidiTrackData: Bool] = [:]
        var patternNames: [MidiTrackData: String] = [:]
        var selectedStyle: Style? = nil
        var selectedFeel: Feel? = nil
        var showError = false
        var errorMessage = ""
        
        var isDoneButtonEnabled: Bool {
            selectedTracks.values.contains(where: { $0 })
        }
        
        var selectedTracksCount: Int {
            selectedTracks.filter { $0.value }.count
        }
        
        init(
            drumNotes: [DrumNote],
            styles: [Style],
            feels: [Feel],
            trackNotes: [MidiTrackData]
        ) {
            self.drumNotes = drumNotes
            self.styles = styles
            self.feels = feels
            self.trackNotes = trackNotes
            
            initializeTrackData()
        }
        
        func configure(with modelContext: ModelContext) {
            self.modelContext = modelContext
        }
        
        private func initializeTrackData() {
            trackNotes.forEach { track in
                selectedTracks[track] = false
                useStyleForTrack[track] = false
                useFeelForTrack[track] = false
                patternNames[track] = ""
            }
        }
        
        func validatePatternName(for track: MidiTrackData) -> String? {
            let name = patternNames[track]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let style = useStyleForTrack[track] ?? false ? selectedStyle : nil
            let feel = useFeelForTrack[track] ?? false ? selectedFeel : nil
            
            if !name.isEmpty && name.count < 2 {
                return "Pattern name must be at least 2 characters long."
            }
            
            let duplicateInTracks = trackNotes.filter { otherTrack in
                otherTrack != track &&
                selectedTracks[otherTrack] == true &&
                patternNames[otherTrack]?.trimmingCharacters(in: .whitespacesAndNewlines) == name &&
                (useStyleForTrack[otherTrack] ?? false ? selectedStyle : nil) == style &&
                (useFeelForTrack[otherTrack] ?? false ? selectedFeel : nil) == feel &&
                otherTrack.isDrumTrack == track.isDrumTrack
            }.count
            
            if duplicateInTracks > 0 {
                return "Pattern with name '\(name)', style '\(style?.name ?? "None")', and feel '\(feel?.name ?? "None")' is already in use among selected tracks."
            }
            
            do {
                let styleID = style?.id
                let feelID = feel?.id
                
                if track.isDrumTrack {
                    var predicate: Predicate<DrumPattern>
                    switch (styleID, feelID) {
                    case (nil, nil):
                        predicate = #Predicate { pattern in
                            pattern.name == name &&
                            pattern.style == nil &&
                            pattern.feel == nil
                        }
                    case (let styleID?, nil):
                        predicate = #Predicate { pattern in
                            pattern.name == name &&
                            pattern.style != nil &&
                            pattern.style?.id == styleID &&
                            pattern.feel == nil
                        }
                    case (nil, let feelID?):
                        predicate = #Predicate { pattern in
                            pattern.name == name &&
                            pattern.style == nil &&
                            pattern.feel != nil &&
                            pattern.feel?.id == feelID
                        }
                    case (let styleID?, let feelID?):
                        predicate = #Predicate { pattern in
                            pattern.name == name &&
                            pattern.style != nil &&
                            pattern.style?.id == styleID &&
                            pattern.feel != nil &&
                            pattern.feel?.id == feelID
                        }
                    }
                    
                    let fetchDescriptor = FetchDescriptor<DrumPattern>(predicate: predicate)
                    let existingPatterns = try modelContext.fetch(fetchDescriptor)
                    if !existingPatterns.isEmpty {
                        return "Pattern with name '\(name)', style '\(style?.name ?? "None")', and feel '\(feel?.name ?? "None")' already exists in the database."
                    }
                } else {
                    var predicate: Predicate<HarmonicPattern>
                    switch (styleID, feelID) {
                    case (nil, nil):
                        predicate = #Predicate { pattern in
                            pattern.name == name &&
                            pattern.style == nil &&
                            pattern.feel == nil
                        }
                    case (let styleID?, nil):
                        predicate = #Predicate { pattern in
                            pattern.name == name &&
                            pattern.style != nil &&
                            pattern.style?.id == styleID &&
                            pattern.feel == nil
                        }
                    case (nil, let feelID?):
                        predicate = #Predicate { pattern in
                            pattern.name == name &&
                            pattern.style == nil &&
                            pattern.feel != nil &&
                            pattern.feel?.id == feelID
                        }
                    case (let styleID?, let feelID?):
                        predicate = #Predicate { pattern in
                            pattern.name == name &&
                            pattern.style != nil &&
                            pattern.style?.id == styleID &&
                            pattern.feel != nil &&
                            pattern.feel?.id == feelID
                        }
                    }
                    
                    let fetchDescriptor = FetchDescriptor<HarmonicPattern>(predicate: predicate)
                    let existingPatterns = try modelContext.fetch(fetchDescriptor)
                    if !existingPatterns.isEmpty {
                        return "Pattern with name '\(name)', style '\(style?.name ?? "None")', and feel '\(feel?.name ?? "None")' already exists in the database."
                    }
                }
            } catch {
                return "Failed to check for existing patterns: \(error.localizedDescription)"
            }
            
            return nil
        }
        
        func validateGlobalStyle() -> String? {
            guard selectedStyle != nil else { return nil }
            return nil
        }
        
        func validateGlobalFeel() -> String? {
            guard selectedFeel != nil else { return nil }
            return nil
        }
        
        func importSelectedTracks(completion: @escaping (Bool) -> Void) {
            let selected = Array(selectedTracks.filter { $0.value }.keys)
            
            if selected.isEmpty {
                errorMessage = "No tracks selected for import."
                showError = true
                completion(false)
                return
            }
            
            var validationErrors: [String] = []
            
            for track in selected {
                if let nameError = validatePatternName(for: track) {
                    let trackName = track.name.isEmpty ? "Track \(trackNotes.firstIndex(of: track)! + 1)" : track.name
                    validationErrors.append("Track '\(trackName)': \(nameError)")
                }
            }
            
            if let styleError = validateGlobalStyle() {
                validationErrors.append("Style: \(styleError)")
            }
            
            if let feelError = validateGlobalFeel() {
                validationErrors.append("Feel: \(feelError)")
            }
            
            if !validationErrors.isEmpty {
                errorMessage = validationErrors.joined(separator: "\n")
                showError = true
                completion(false)
                return
            }
            
            performImport(for: selected) { success in
                if success {
                    try? self.modelContext.save()
                }
                completion(success)
            }
        }
        
        private func performImport(for selectedTracks: [MidiTrackData], completion: @escaping (Bool) -> Void) {
            var hasError = false
            
            for track in selectedTracks {
                let customName = patternNames[track]?.trimmingCharacters(in: .whitespacesAndNewlines)
                let patternName = customName?.isEmpty ?? true
                    ? (track.name.isEmpty ? "Imported Pattern \(trackNotes.firstIndex(of: track)! + 1)" : track.name)
                    : customName!
                
                let style = useStyleForTrack[track] ?? false ? selectedStyle : nil
                let feel = useFeelForTrack[track] ?? false ? selectedFeel : nil
                
                if track.isDrumTrack {
                    guard let drumNotesInPattern = createDrumNotesInPattern(for: track) else {
                        hasError = true
                        continue
                    }
                    
                    let newDrumPattern = DrumPattern(
                        name: patternName,
                        style: style,
                        feel: feel
                    )
                    
                    drumNotesInPattern.forEach { $0.pattern = newDrumPattern }
                    newDrumPattern.drumNotesInPattern = drumNotesInPattern
                    modelContext.insert(newDrumPattern)
                } else {
                    let baseOctave = track.notes.first.map { UInt8($0.note / 12 - 1) } ?? 4
                    guard let harmonicNotesInPattern = createHarmonicNotesInPattern(for: track) else {
                        hasError = true
                        continue
                    }
                    
                    let newHarmonicPattern = HarmonicPattern(
                        name: patternName,
                        style: style,
                        feel: feel,
                        baseOctave: baseOctave
                    )
                    
                    harmonicNotesInPattern.forEach { note in
                        note.pattern = newHarmonicPattern
                        // half steps is distance from root in baseOctave to current note (note.midiValue - root.midiValue)
                        let halfSteps = Int8(2)
//                        let halfSteps = Int8(max(min(Int(note.noteValue) - Int(baseOctave * 12 + 12), 127), -128))
                        note.halfSteps = halfSteps
                    }
                    newHarmonicPattern.harmonicNotesInPattern = harmonicNotesInPattern
                    modelContext.insert(newHarmonicPattern)
                }
            }
            
            if hasError {
                errorMessage = "Some tracks could not be imported due to invalid notes."
                showError = true
                completion(false)
            } else {
                completion(true)
            }
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
            
            guard !drumNotesInPattern.isEmpty else {
                return nil
            }
            
            return drumNotesInPattern
        }
        
        private func createHarmonicNotesInPattern(for track: MidiTrackData) -> [HarmonicNoteInPattern]? {
            let harmonicNotesInPattern = track.notes.compactMap { midiNote -> HarmonicNoteInPattern? in
                return HarmonicNoteInPattern(
                    pattern: HarmonicPattern(name: "Temporary", style: nil, feel: nil, baseOctave: 4),
                    halfSteps: 0,
                    timestampOn: UInt(midiNote.tickOn),
                    timestampOff: UInt(midiNote.tickOff)
                )
            }
            
            guard !harmonicNotesInPattern.isEmpty else {
                return nil
            }
            
            return harmonicNotesInPattern
        }
    }
}
