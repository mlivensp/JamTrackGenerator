////
////  JamTrackDetailViewModelTests.swift
////  JamTrackGeneratorTests
////
////  Created by Michael Livenspargar on 10/16/25.
////
//
//import SwiftData
//import Testing
//@testable import JamTrackGenerator
//
//@MainActor
//struct JamTrackEditorViewModelTests {
//    @Test
//    func testPrepareForSaveInsertsNewModels() throws {
//        // Setup in-memory model container
//        let container = try ModelContainer(
//            for: Style.self, Feel.self, Key.self,  JamTrack.self, Part.self, JamTrackSection.self, SectionPart.self, Instrument.self, InstrumentFamily.self,
//            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
//        )
//        let context = container.mainContext
//
//        let style = Style(name: "Rock")
//        let feel = Feel(name: "Hard")
//        let key = Key(noteName: "C", sharpsOrFlats: 0, isMajor: true)
//        let instrumentFamily = InstrumentFamily(name: "Electric", sortOrder: 0)
//        let instrument = Instrument(name: "Guitar", programNumber: 1, instrumentFamily: instrumentFamily)
//        context.insert(style)
//        context.insert(feel)
//        context.insert(key)
//        context.insert(instrumentFamily)
//        context.insert(instrument)
//        // Create a dummy JamTrack
//        let jamTrack = JamTrack(name: "Test", style: style, key: key, feel: feel, bpm: 120, includeCountIn: true)
//        context.insert(jamTrack)
//
//        // Create ViewModel
//        let viewModel = JamTrackDetailView.ViewModel(jamTrack: jamTrack)
//
//        // Add new Part
//        let newPart = Part(jamTrack: jamTrack, instrument: instrument, order: 99)
//        viewModel.parts.append(newPart)
//
//        // Add new Section and SectionPart
//        let songSection = SongSection(name: "Verse", sortOrder: 1) // assuming SongSection is a @Model
//        let newSection = JamTrackSection(jamTrack: nil, songSection: songSection, order: 99)
//        let newSectionPart = SectionPart(section: newSection, part: newPart, patternName: "Pattern A")
//        newSection.sectionParts.append(newSectionPart)
//        viewModel.sections.append(newSection)
//
//        // Call prepareForSave
//        viewModel.prepareForSave(modelContext: context)
//
//        // Assertions
//        #expect(newPart.modelContext != nil)
//        #expect(newSection.modelContext != nil)
//        #expect(newSectionPart.modelContext != nil)
//
//        #expect(newPart.jamTrack == jamTrack)
//        #expect(newSection.jamTrack == jamTrack)
//        #expect(newSectionPart.section == newSection)
//    }
//}
