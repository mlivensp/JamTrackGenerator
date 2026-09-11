import SwiftData
import Foundation

extension PatternImportView {
    @Observable class ViewModel {
        private var modelContext: ModelContext!
        private let drumNotes: [DrumNote]
        let trackNotes: [MidiTrackData]
        
        var selectedTracks: [MidiTrackData: Bool] = [:]
        var useStyleForTrack: [MidiTrackData: Bool] = [:]
        var useFeelForTrack: [MidiTrackData: Bool] = [:]
        var patternNames: [MidiTrackData: String] = [:]
        var errorMessages: [MidiTrackData: String] = [:]
        var selectedStyle: Style? = nil
        var selectedFeel: Feel? = nil
        var showError = false
        var singleErrorMessage = ""
        
        var errorMessage: String {
            singleErrorMessage
        }
        
        var isDoneButtonEnabled: Bool {
            selectedTracks.values.contains(where: { $0 }) && errorMessages.isEmpty && singleErrorMessage.isEmpty
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
            self.trackNotes = trackNotes
            _ = styles
            _ = feels
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
            guard let importService else {
                return "Pattern import is not ready."
            }
            
            return importService.validatePatternName(
                for: track,
                selections: selections,
                selectedStyle: selectedStyle,
                selectedFeel: selectedFeel
            )
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
                singleErrorMessage = "No tracks selected for import."
                showError = true
                completion(false)
                return
            }
            
            singleErrorMessage = ""
            var validationErrors: [String] = []
            
            for track in selected {
                if let nameError = validatePatternName(for: track) {
                    errorMessages[track] = nameError
                } else {
                    errorMessages[track] = nil
                }
            }
            
            if let styleError = validateGlobalStyle() {
                validationErrors.append("Style: \(styleError)")
            }
            
            if let feelError = validateGlobalFeel() {
                validationErrors.append("Feel: \(feelError)")
            }
            
            if !validationErrors.isEmpty || !errorMessages.isEmpty {
                singleErrorMessage = validationErrors.isEmpty
                    ? "Resolve track validation errors before importing."
                    : validationErrors.joined(separator: "\n")
                showError = true
                completion(false)
                return
            }
            
            guard let importService else {
                singleErrorMessage = "Pattern import is not ready."
                showError = true
                completion(false)
                return
            }
            
            do {
                try importService.importSelectedTracks(
                    selections: selections,
                    selectedStyle: selectedStyle,
                    selectedFeel: selectedFeel
                )
                completion(true)
            } catch {
                singleErrorMessage = error.localizedDescription
                showError = true
                completion(false)
            }
        }
        
        private var selections: [MidiTrackData: PatternImportSelection] {
            Dictionary(uniqueKeysWithValues: trackNotes.map { track in
                (
                    track,
                    PatternImportSelection(
                        isSelected: selectedTracks[track] ?? false,
                        useStyle: useStyleForTrack[track] ?? false,
                        useFeel: useFeelForTrack[track] ?? false,
                        patternName: patternNames[track] ?? ""
                    )
                )
            })
        }
        
        private var importService: PatternImportService? {
            guard let modelContext else { return nil }
            return PatternImportService(
                modelContext: modelContext,
                drumNotes: drumNotes,
                trackNotes: trackNotes
            )
        }
    }
}
