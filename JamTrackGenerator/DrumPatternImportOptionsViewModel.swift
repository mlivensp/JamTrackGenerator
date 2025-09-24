import SwiftData
import Foundation

extension DrumPatternImportOptionsView {
    @Observable class ViewModel {
        // MARK: - Properties
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
        
        // MARK: - Computed Properties
        var isDoneButtonEnabled: Bool {
            selectedTracks.values.contains(where: { $0 })
        }
        
        var selectedTracksCount: Int {
            selectedTracks.filter { $0.value }.count
        }
        
        // MARK: - Initialization
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
        
        // MARK: - Private Methods
        private func initializeTrackData() {
            trackNotes.forEach { track in
                selectedTracks[track] = false
                useStyleForTrack[track] = false
                useFeelForTrack[track] = false
                patternNames[track] = ""
            }
        }
        
        // MARK: - Validation Methods
        func validatePatternName(for track: MidiTrackData) -> String? {
            let name = patternNames[track]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let style = useStyleForTrack[track] ?? false ? selectedStyle : nil
            let feel = useFeelForTrack[track] ?? false ? selectedFeel : nil
            
            // Check for empty name when custom name is provided
            if !name.isEmpty && name.count < 2 {
                return "Pattern name must be at least 2 characters long."
            }
            
            // Check for duplicates among selected tracks
            let duplicateInTracks = trackNotes.filter { otherTrack in
                otherTrack != track &&
                selectedTracks[otherTrack] == true &&
                patternNames[otherTrack]?.trimmingCharacters(in: .whitespacesAndNewlines) == name &&
                (useStyleForTrack[otherTrack] ?? false ? selectedStyle : nil) == style &&
                (useFeelForTrack[otherTrack] ?? false ? selectedFeel : nil) == feel
            }.count
            
            if duplicateInTracks > 0 {
                return "Pattern with name '\(name)', style '\(style?.name ?? "None")', and feel '\(feel?.name ?? "None")' is already in use among selected tracks."
            }
            
            // Check for duplicates in the database
            do {
                let styleID = style?.id
                let feelID = feel?.id
                
                // Create a predicate based on style and feel being nil or non-nil
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
            } catch {
                return "Failed to check for existing patterns: \(error.localizedDescription)"
            }
            
            return nil
        }
        
        func validateGlobalStyle() -> String? {
            guard selectedStyle != nil else { return nil }
            // Add specific style validation logic if needed
            return nil
        }
        
        func validateGlobalFeel() -> String? {
            guard selectedFeel != nil else { return nil }
            // Add specific feel validation logic if needed
            return nil
        }
        
        // MARK: - Import Method
        func importSelectedTracks(completion: @escaping (Bool) -> Void) {
            let selected = Array(selectedTracks.filter { $0.value }.keys) // Convert keys to Array
            
            if selected.isEmpty {
                errorMessage = "No tracks selected for import."
                showError = true
                completion(false)
                return
            }
            
            // Validate all selected tracks
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
            
            // All validations passed - proceed with import
            performImport(for: selected) { success in
                if success {
                    try? self.modelContext.save()
                }
                completion(success)
            }
        }
        
        // MARK: - Private Import Methods
        private func performImport(for selectedTracks: [MidiTrackData], completion: @escaping (Bool) -> Void) {
            var hasError = false
            
            for track in selectedTracks {
                guard let drumNotesInPattern = createDrumNotesInPattern(for: track) else {
                    hasError = true
                    continue
                }
                
                let customName = patternNames[track]?.trimmingCharacters(in: .whitespacesAndNewlines)
                let patternName = customName?.isEmpty ?? true
                    ? (track.name.isEmpty ? "Imported Pattern \(trackNotes.firstIndex(of: track)! + 1)" : track.name)
                    : customName!
                
                let style = useStyleForTrack[track] ?? false ? selectedStyle : nil
                let feel = useFeelForTrack[track] ?? false ? selectedFeel : nil
                
                let newDrumPattern = DrumPattern(
                    name: patternName,
                    style: style,
                    feel: feel
                )
                
                newDrumPattern.drumNotesInPattern = drumNotesInPattern
                modelContext.insert(newDrumPattern)
            }
            
            if hasError {
                errorMessage = "Some tracks could not be imported due to invalid drum notes."
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
                    pattern: DrumPattern(name: "Imported"), // Will be set after DrumPattern creation
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
    }
}
