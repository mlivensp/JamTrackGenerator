import Testing
import SwiftData
@testable import JamTrackGenerator
import Foundation

@Suite("PatternImportOptionsViewModel Tests")
struct PatternImportOptionsViewModelTests {
    var modelContext: ModelContext!
    var viewModel: PatternImportOptionsView.ViewModel!
    var drumNotes: [DrumNote]!
    var styles: [Style]!
    var feels: [Feel]!
    var trackNotes: [MidiTrackData]!
    
    mutating func setUp() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Style.self,
                 Feel.self,
                 RawNote.self,
                 Key.self,
                 NoteInKey.self,
                 ScaleDegree.self,
                 SongSection.self,
                 JamTrackSection.self,
                 InstrumentFamily.self,
                 Instrument.self,
                 Part.self,
                 JamTrack.self,
                 DrumNoteInPattern.self,
                 DrumPattern.self,
                 HarmonicNoteInPattern.self,
                 HarmonicPattern.self,
                 SectionPart.self,
                 DrumNote.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        
        drumNotes = [
            DrumNote(name: "Kick", midiValue: 36),
            DrumNote(name: "Snare", midiValue: 38)
        ]
        styles = [
            Style(name: "Rock"),
            Style(name: "Jazz")
        ]
        feels = [
            Feel(name: "Straight"),
            Feel(name: "Swing")
        ]
        trackNotes = [
            MidiTrackData(
                name: "Drums",
                isDrumTrack: true,
                notes: [
                    MidiNote(note: 36, tickOn: 0, tickOff: 100, velocityOn: 100, velocityOff: 0, channel: 10)
                ],
                keySignature: "C Major"
            ),
            MidiTrackData(
                name: "Piano",
                isDrumTrack: false,
                notes: [
                    MidiNote(note: 72, tickOn: 0, tickOff: 100, velocityOn: 100, velocityOff: 0, channel: 0),
                    MidiNote(note: 74, tickOn: 200, tickOff: 300, velocityOn: 100, velocityOff: 0, channel: 0)
                ],
                keySignature: "C Major"
            )
        ]
        
        drumNotes.forEach { modelContext.insert($0) }
        styles.forEach { modelContext.insert($0) }
        feels.forEach { modelContext.insert($0) }
        
        viewModel = PatternImportOptionsView.ViewModel(
            drumNotes: drumNotes,
            styles: styles,
            feels: feels,
            trackNotes: trackNotes
        )
        viewModel.configure(with: modelContext)
    }
    
    mutating func tearDown() {
        modelContext = nil
        viewModel = nil
        drumNotes = nil
        styles = nil
        feels = nil
        trackNotes = nil
    }
    
    @Test("Initialization sets default state correctly")
    mutating func testInitialization() throws {
        try setUp()
        #expect(viewModel.selectedTracks.count == trackNotes.count)
        #expect(viewModel.useStyleForTrack.count == trackNotes.count)
        #expect(viewModel.useFeelForTrack.count == trackNotes.count)
        #expect(viewModel.patternNames.count == trackNotes.count)
        #expect(viewModel.selectedStyle == nil)
        #expect(viewModel.selectedFeel == nil)
        #expect(viewModel.showError == false)
        #expect(viewModel.errorMessage.isEmpty)
        #expect(viewModel.isDoneButtonEnabled == false)
        #expect(viewModel.selectedTracksCount == 0)
        
        for track in trackNotes {
            #expect(viewModel.selectedTracks[track] == false)
            #expect(viewModel.useStyleForTrack[track] == false)
            #expect(viewModel.useFeelForTrack[track] == false)
            #expect(viewModel.patternNames[track] == "")
        }
        tearDown()
    }
    
    @Test("Selecting tracks updates isDoneButtonEnabled and selectedTracksCount")
    mutating func testTrackSelection() throws {
        try setUp()
        viewModel.selectedTracks[trackNotes[0]] = true
        #expect(viewModel.isDoneButtonEnabled == true)
        #expect(viewModel.selectedTracksCount == 1)
        
        viewModel.selectedTracks[trackNotes[1]] = true
        #expect(viewModel.selectedTracksCount == 2)
        
        viewModel.selectedTracks[trackNotes[0]] = false
        #expect(viewModel.isDoneButtonEnabled == true)
        #expect(viewModel.selectedTracksCount == 1)
        
        viewModel.selectedTracks[trackNotes[1]] = false
        #expect(viewModel.isDoneButtonEnabled == false)
        #expect(viewModel.selectedTracksCount == 0)
        tearDown()
    }
    
    @Test("Pattern name validation detects short names")
    mutating func testPatternNameValidationShortName() throws {
        try setUp()
        viewModel.patternNames[trackNotes[0]] = "A"
        let error = viewModel.validatePatternName(for: trackNotes[0])
        #expect(error == "Pattern name must be at least 2 characters long.")
        tearDown()
    }
    
    @Test("Pattern name validation detects duplicates among selected tracks")
    mutating func testPatternNameValidationDuplicatesInTracks() throws {
        try setUp()
        let drumTrack2 = MidiTrackData(
            name: "Drums2",
            isDrumTrack: true,
            notes: [
                MidiNote(note: 38, tickOn: 0, tickOff: 100, velocityOn: 100, velocityOff: 0, channel: 10)
            ],
            keySignature: "C Major"
        )
        trackNotes.append(drumTrack2)
        viewModel = PatternImportOptionsView.ViewModel(
            drumNotes: drumNotes,
            styles: styles,
            feels: feels,
            trackNotes: trackNotes
        )
        viewModel.configure(with: modelContext)
        
        viewModel.selectedTracks[trackNotes[0]] = true
        viewModel.selectedTracks[drumTrack2] = true
        viewModel.patternNames[trackNotes[0]] = "TestPattern"
        viewModel.patternNames[drumTrack2] = "TestPattern"
        viewModel.useStyleForTrack[trackNotes[0]] = true
        viewModel.useStyleForTrack[drumTrack2] = true
        viewModel.useFeelForTrack[trackNotes[0]] = true
        viewModel.useFeelForTrack[drumTrack2] = true
        viewModel.selectedStyle = styles[0]
        viewModel.selectedFeel = feels[0]
        
        let error = viewModel.validatePatternName(for: drumTrack2)
        #expect(error == "Pattern with name 'TestPattern', style 'Rock', and feel 'Straight' is already in use among selected tracks.")
        tearDown()
    }
    
    @Test("Pattern name validation allows same name for different track types")
    mutating func testPatternNameValidationSameNameDifferentTrackTypes() throws {
        try setUp()
        viewModel.selectedTracks[trackNotes[0]] = true
        viewModel.selectedTracks[trackNotes[1]] = true
        viewModel.patternNames[trackNotes[0]] = "TestPattern"
        viewModel.patternNames[trackNotes[1]] = "TestPattern"
        viewModel.useStyleForTrack[trackNotes[0]] = true
        viewModel.useStyleForTrack[trackNotes[1]] = true
        viewModel.useFeelForTrack[trackNotes[0]] = true
        viewModel.useFeelForTrack[trackNotes[1]] = true
        viewModel.selectedStyle = styles[0]
        viewModel.selectedFeel = feels[0]
        
        let error = viewModel.validatePatternName(for: trackNotes[1])
        #expect(error == nil)
        tearDown()
    }
    
    @Test("Pattern name validation allows same name with different style or feel")
    mutating func testPatternNameValidationSameNameDifferentStyleOrFeel() throws {
        try setUp()
        viewModel.selectedTracks[trackNotes[0]] = true
        viewModel.selectedTracks[trackNotes[1]] = true
        viewModel.patternNames[trackNotes[0]] = "TestPattern"
        viewModel.patternNames[trackNotes[1]] = "TestPattern"
        viewModel.useStyleForTrack[trackNotes[0]] = true
        viewModel.useStyleForTrack[trackNotes[1]] = true
        viewModel.useFeelForTrack[trackNotes[0]] = true
        viewModel.useFeelForTrack[trackNotes[1]] = false
        viewModel.selectedStyle = styles[0]
        viewModel.selectedFeel = feels[0]
        
        let error = viewModel.validatePatternName(for: trackNotes[1])
        #expect(error == nil)
        tearDown()
    }
    
    @Test("Drum pattern name validation detects duplicates in database")
    mutating func testDrumPatternNameValidationDuplicatesInDatabase() throws {
        try setUp()
        let existingPattern = DrumPattern(name: "TestPattern", style: styles[0], feel: feels[0])
        modelContext.insert(existingPattern)
        try modelContext.save()
        
        viewModel.selectedTracks[trackNotes[0]] = true
        viewModel.patternNames[trackNotes[0]] = "TestPattern"
        viewModel.useStyleForTrack[trackNotes[0]] = true
        viewModel.useFeelForTrack[trackNotes[0]] = true
        viewModel.selectedStyle = styles[0]
        viewModel.selectedFeel = feels[0]
        
        let error = viewModel.validatePatternName(for: trackNotes[0])
        #expect(error == "Pattern with name 'TestPattern', style 'Rock', and feel 'Straight' already exists in the database.")
        tearDown()
    }
    
    @Test("Harmonic pattern name validation detects duplicates in database")
    mutating func testHarmonicPatternNameValidationDuplicatesInDatabase() throws {
        try setUp()
        let existingPattern = HarmonicPattern(name: "TestPattern", style: styles[0], feel: feels[0], baseOctave: 4)
        modelContext.insert(existingPattern)
        try modelContext.save()
        
        viewModel.selectedTracks[trackNotes[1]] = true
        viewModel.patternNames[trackNotes[1]] = "TestPattern"
        viewModel.useStyleForTrack[trackNotes[1]] = true
        viewModel.useFeelForTrack[trackNotes[1]] = true
        viewModel.selectedStyle = styles[0]
        viewModel.selectedFeel = feels[0]
        
        let error = viewModel.validatePatternName(for: trackNotes[1])
        #expect(error == "Pattern with name 'TestPattern', style 'Rock', and feel 'Straight' already exists in the database.")
        tearDown()
    }
    
    @Test("Pattern name validation detects duplicates in database with nil style and feel")
    mutating func testPatternNameValidationDuplicatesInDatabaseNilStyleAndFeel() throws {
        try setUp()
        let existingDrumPattern = DrumPattern(name: "TestPattern", style: nil, feel: nil)
        let existingHarmonicPattern = HarmonicPattern(name: "TestPattern", style: nil, feel: nil, baseOctave: 4)
        modelContext.insert(existingDrumPattern)
        modelContext.insert(existingHarmonicPattern)
        try modelContext.save()
        
        viewModel.selectedTracks[trackNotes[0]] = true
        viewModel.patternNames[trackNotes[0]] = "TestPattern"
        viewModel.useStyleForTrack[trackNotes[0]] = false
        viewModel.useFeelForTrack[trackNotes[0]] = false
        
        let drumError = viewModel.validatePatternName(for: trackNotes[0])
        #expect(drumError == "Pattern with name 'TestPattern', style 'None', and feel 'None' already exists in the database.")
        
        viewModel.selectedTracks[trackNotes[1]] = true
        viewModel.patternNames[trackNotes[1]] = "TestPattern"
        viewModel.useStyleForTrack[trackNotes[1]] = false
        viewModel.useFeelForTrack[trackNotes[1]] = false
        
        let harmonicError = viewModel.validatePatternName(for: trackNotes[1])
        #expect(harmonicError == "Pattern with name 'TestPattern', style 'None', and feel 'None' already exists in the database.")
        tearDown()
    }
    
    @Test("Pattern name validation detects duplicates in database with style only")
    mutating func testPatternNameValidationDuplicatesInDatabaseStyleOnly() throws {
        try setUp()
        let existingPattern = DrumPattern(name: "TestPattern", style: styles[0], feel: nil)
        modelContext.insert(existingPattern)
        try modelContext.save()
        
        viewModel.selectedTracks[trackNotes[0]] = true
        viewModel.patternNames[trackNotes[0]] = "TestPattern"
        viewModel.useStyleForTrack[trackNotes[0]] = true
        viewModel.useFeelForTrack[trackNotes[0]] = false
        viewModel.selectedStyle = styles[0]
        
        let error = viewModel.validatePatternName(for: trackNotes[0])
        #expect(error == "Pattern with name 'TestPattern', style 'Rock', and feel 'None' already exists in the database.")
        tearDown()
    }
    
    @Test("Pattern name validation detects duplicates in database with feel only")
    mutating func testPatternNameValidationDuplicatesInDatabaseFeelOnly() throws {
        try setUp()
        let existingPattern = DrumPattern(name: "TestPattern", style: nil, feel: feels[0])
        modelContext.insert(existingPattern)
        try modelContext.save()
        
        viewModel.selectedTracks[trackNotes[0]] = true
        viewModel.patternNames[trackNotes[0]] = "TestPattern"
        viewModel.useStyleForTrack[trackNotes[0]] = false
        viewModel.useFeelForTrack[trackNotes[0]] = true
        viewModel.selectedFeel = feels[0]
        
        let error = viewModel.validatePatternName(for: trackNotes[0])
        #expect(error == "Pattern with name 'TestPattern', style 'None', and feel 'Straight' already exists in the database.")
        tearDown()
    }
    
    @Test("Pattern name validation allows valid names")
    mutating func testPatternNameValidationValid() throws {
        try setUp()
        viewModel.patternNames[trackNotes[0]] = "ValidPattern"
        let error = viewModel.validatePatternName(for: trackNotes[0])
        #expect(error == nil)
        tearDown()
    }
    
    @Test("Global style and feel validation returns nil when not set")
    mutating func testGlobalStyleFeelValidationNil() throws {
        try setUp()
        #expect(viewModel.validateGlobalStyle() == nil)
        #expect(viewModel.validateGlobalFeel() == nil)
        tearDown()
    }
    
    @Test("Global style and feel validation returns nil when set")
    mutating func testGlobalStyleFeelValidationSet() throws {
        try setUp()
        viewModel.selectedStyle = styles[0]
        viewModel.selectedFeel = feels[0]
        #expect(viewModel.validateGlobalStyle() == nil)
        #expect(viewModel.validateGlobalFeel() == nil)
        tearDown()
    }
    
    @Test("Import fails with no selected tracks")
    mutating func testImportNoTracks() async throws {
        try setUp()
        var success: Bool = false
        await viewModel.importSelectedTracks { result in
            success = result
        }
        #expect(success == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage == "No tracks selected for import.")
        tearDown()
    }
    
    @Test("Import fails with duplicate pattern in database")
    mutating func testImportFailsWithDuplicateInDatabase() async throws {
        try setUp()
        let existingPattern = DrumPattern(name: "DrumPattern", style: styles[0], feel: feels[0])
        modelContext.insert(existingPattern)
        try modelContext.save()
        
        viewModel.selectedTracks[trackNotes[0]] = true
        viewModel.patternNames[trackNotes[0]] = "DrumPattern"
        viewModel.useStyleForTrack[trackNotes[0]] = true
        viewModel.useFeelForTrack[trackNotes[0]] = true
        viewModel.selectedStyle = styles[0]
        viewModel.selectedFeel = feels[0]
        
        var success: Bool = false
        await viewModel.importSelectedTracks { result in
            success = result
        }
        #expect(success == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("Pattern with name 'DrumPattern', style 'Rock', and feel 'Straight' already exists in the database."))
        tearDown()
    }
    
    @Test("Import succeeds with valid drum track")
    mutating func testImportSuccessDrumTrack() async throws {
        try setUp()
        viewModel.selectedTracks[trackNotes[0]] = true
        viewModel.patternNames[trackNotes[0]] = "DrumPattern"
        viewModel.useStyleForTrack[trackNotes[0]] = true
        viewModel.useFeelForTrack[trackNotes[0]] = true
        viewModel.selectedStyle = styles[0]
        viewModel.selectedFeel = feels[0]
        
        var success: Bool = false
        await viewModel.importSelectedTracks { result in
            success = result
        }
        #expect(success == true)
        #expect(viewModel.showError == false)
        
        let fetchDescriptor = FetchDescriptor<DrumPattern>()
        let patterns = try modelContext.fetch(fetchDescriptor)
        #expect(patterns.count == 1)
        #expect(patterns.first?.name == "DrumPattern")
        #expect(patterns.first?.style?.name == "Rock")
        #expect(patterns.first?.feel?.name == "Straight")
        #expect(patterns.first?.drumNotesInPattern.count == 1)
        #expect(patterns.first?.drumNotesInPattern.first?.drumNote?.midiValue == 36)
        tearDown()
    }
    
    @Test("Import succeeds with valid harmonic track")
    mutating func testImportSuccessHarmonicTrack() async throws {
        try setUp()
        viewModel.selectedTracks[trackNotes[1]] = true
        viewModel.patternNames[trackNotes[1]] = "HarmonicPattern"
        viewModel.useStyleForTrack[trackNotes[1]] = true
        viewModel.useFeelForTrack[trackNotes[1]] = true
        viewModel.selectedStyle = styles[0]
        viewModel.selectedFeel = feels[0]
        
        var success: Bool = false
        await viewModel.importSelectedTracks { result in
            success = result
        }
        #expect(success == true)
        #expect(viewModel.showError == false)
        
        let fetchDescriptor = FetchDescriptor<HarmonicPattern>()
        let patterns = try modelContext.fetch(fetchDescriptor)
        #expect(patterns.count == 1)
        #expect(patterns.first?.name == "HarmonicPattern")
        #expect(patterns.first?.style?.name == "Rock")
        #expect(patterns.first?.feel?.name == "Straight")
        #expect(patterns.first?.harmonicNotesInPattern.count == 2)
        #expect(patterns.first?.baseOctave == 5)
        #expect(patterns.first?.harmonicNotesInPattern[0].halfSteps == 0)
        #expect(patterns.first?.harmonicNotesInPattern[1].halfSteps == 2)
        tearDown()
    }
}
