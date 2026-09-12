import SwiftData
import Testing
@testable import JamTrackGenerator

@MainActor
struct JamTrackDetailViewModelTests {
    @Test
    func initialDraftStartsClean() throws {
        let fixture = try Fixture()

        #expect(!fixture.viewModel.hasUnsavedChanges)
        #expect(fixture.viewModel.draft.name == fixture.jamTrack.name)
        #expect(fixture.viewModel.draft.parts.count == fixture.jamTrack.parts.count)
        #expect(fixture.viewModel.draft.sections.count == fixture.jamTrack.jamTrackSections.count)
    }

    @Test
    func draftEditsDoNotMutatePersistedModelsBeforeSave() throws {
        let fixture = try Fixture()
        let originalPartCount = fixture.jamTrack.parts.count
        let originalPattern = fixture.sectionPart.patternName

        fixture.viewModel.name = "Unsaved Name"
        fixture.viewModel.addPart(instrument: fixture.drums)
        fixture.viewModel.setPatternReference(
            .harmonic(fixture.sharedHarmonicPatternB.persistentModelID),
            for: fixture.viewModel.draft.sections[0].id,
            partID: fixture.viewModel.draft.parts[0].id
        )

        #expect(fixture.viewModel.hasUnsavedChanges)
        #expect(fixture.jamTrack.name == "Original")
        #expect(fixture.jamTrack.parts.count == originalPartCount)
        #expect(fixture.sectionPart.patternName == originalPattern)
    }

    @Test
    func catalogSettersMutateOnlyDraftAndMarkItDirty() throws {
        let fixture = try Fixture()
        let partID = fixture.viewModel.draft.parts[0].id
        let sectionID = fixture.viewModel.draft.sections[0].id

        fixture.viewModel.setStyle(nil)
        fixture.viewModel.setFeel(nil)
        fixture.viewModel.setKey(nil)
        fixture.viewModel.setInstrument(fixture.drums.persistentModelID, for: partID)
        fixture.viewModel.setSongSection(nil, for: sectionID)

        #expect(fixture.viewModel.draft.styleID == nil)
        #expect(fixture.viewModel.draft.feelID == nil)
        #expect(fixture.viewModel.draft.keyID == nil)
        #expect(fixture.viewModel.draft.parts[0].instrumentID == fixture.drums.persistentModelID)
        #expect(fixture.viewModel.draft.sections[0].songSectionID == nil)
        #expect(fixture.viewModel.hasUnsavedChanges)
        #expect(fixture.jamTrack.style?.persistentModelID != nil)
        #expect(fixture.jamTrack.feel?.persistentModelID != nil)
        #expect(fixture.jamTrack.key?.persistentModelID != nil)
        #expect(fixture.jamTrack.parts[0].instrument?.persistentModelID == fixture.guitar.persistentModelID)
        #expect(fixture.jamTrack.jamTrackSections[0].songSection?.persistentModelID != nil)
    }

    @Test
    func saveAppliesDraftChanges() throws {
        let fixture = try Fixture()
        fixture.viewModel.name = "Saved Name"
        fixture.viewModel.addPart(instrument: fixture.drums)
        fixture.viewModel.setPatternReference(
            .harmonic(fixture.newHarmonicPattern.persistentModelID),
            for: fixture.viewModel.draft.sections[0].id,
            partID: fixture.viewModel.draft.parts[0].id
        )

        #expect(fixture.viewModel.save(modelContext: fixture.context))

        #expect(fixture.jamTrack.name == "Saved Name")
        #expect(fixture.jamTrack.parts.count == 2)
        #expect(fixture.jamTrack.jamTrackSections[0].sectionParts[0].patternName == "New Pattern")
        #expect(!fixture.viewModel.hasUnsavedChanges)
    }

    @Test
    func addSectionBeyondUInt8MaximumSavesInAscendingOrder() throws {
        let fixture = try Fixture()
        fixture.viewModel.draft.sections[0].order = 255

        fixture.viewModel.addSection(songSection: fixture.songSection)

        #expect(fixture.viewModel.draft.sections.map(\.order) == [255, 256])
        #expect(fixture.viewModel.sortedSections.map(\.order) == [255, 256])
        #expect(fixture.viewModel.save(modelContext: fixture.context))
        #expect(fixture.jamTrack.sortedSections.map(\.order) == [255, 256])
    }

    @Test
    func patternSelectionRetainsExactIdentityWhenNamesMatch() throws {
        let fixture = try Fixture()
        let section = fixture.viewModel.draft.sections[0]
        let part = fixture.viewModel.draft.parts[0]

        fixture.viewModel.setPatternReference(
            .harmonic(fixture.sharedHarmonicPatternB.persistentModelID),
            for: section.id,
            partID: part.id
        )

        #expect(
            fixture.viewModel.patternReference(for: section.id, partID: part.id)
                == .harmonic(fixture.sharedHarmonicPatternB.persistentModelID)
        )
        #expect(
            fixture.viewModel.patternReference(for: section.id, partID: part.id)
                != .harmonic(fixture.sharedHarmonicPatternA.persistentModelID)
        )
        #expect(fixture.viewModel.save(modelContext: fixture.context))
        #expect(fixture.sectionPart.patternName == "Shared Pattern")
    }

    @Test
    func saveWithMismatchedPatternReferenceLeavesGraphUnchanged() throws {
        let fixture = try Fixture()
        let section = fixture.viewModel.draft.sections[0]
        let part = fixture.viewModel.draft.parts[0]

        fixture.viewModel.name = "Changed Name"
        fixture.viewModel.setPatternReference(
            .drum(fixture.drumPattern.persistentModelID),
            for: section.id,
            partID: part.id
        )

        #expect(!fixture.viewModel.save(modelContext: fixture.context))
        #expect(fixture.viewModel.errorMessage == "Save failed: a drum pattern is assigned to a non-drums part.")
        #expect(fixture.jamTrack.name == "Original")
        #expect(fixture.sectionPart.patternName == "Original Pattern")
        #expect(!fixture.context.hasChanges)
    }

    @Test
    func saveAndCreateExportURLDoesNotExportWhenValidationFails() throws {
        let fixture = try Fixture()
        let section = fixture.viewModel.draft.sections[0]
        let part = fixture.viewModel.draft.parts[0]

        fixture.viewModel.setPatternReference(
            .drum(fixture.drumPattern.persistentModelID),
            for: section.id,
            partID: part.id
        )

        #expect(fixture.viewModel.saveAndCreateExportURL(modelContext: fixture.context) == nil)
        #expect(fixture.viewModel.errorMessage == "Save failed: a drum pattern is assigned to a non-drums part.")
        #expect(!fixture.viewModel.isSavingAndCreatingExportURL)
        #expect(fixture.jamTrack.name == "Original")
        #expect(!fixture.context.hasChanges)
    }

    @Test
    func saveWithMissingPatternReferenceLeavesGraphUnchanged() throws {
        let fixture = try Fixture()
        let section = fixture.viewModel.draft.sections[0]
        let part = fixture.viewModel.draft.parts[0]

        fixture.viewModel.name = "Changed Name"
        fixture.viewModel.setPatternReference(
            .harmonic(try fixture.makeInvalidHarmonicPatternID()),
            for: section.id,
            partID: part.id
        )

        #expect(!fixture.viewModel.save(modelContext: fixture.context))
        #expect(fixture.viewModel.errorMessage == "Save failed: the selected harmonic pattern is no longer available.")
        #expect(fixture.jamTrack.name == "Original")
        #expect(fixture.sectionPart.patternName == "Original Pattern")
        #expect(!fixture.context.hasChanges)
    }

    @Test
    func saveWithInvalidCatalogSelectionLeavesGraphUnchanged() throws {
        let fixture = try Fixture()
        let originalDraft = fixture.viewModel.draft
        let invalidKeyID = try fixture.makeInvalidKeyID()

        fixture.viewModel.name = "Changed Name"
        fixture.viewModel.setKey(invalidKeyID)

        #expect(!fixture.viewModel.save(modelContext: fixture.context))
        #expect(fixture.viewModel.errorMessage == "Save failed: select a key, style, and feel.")
        #expect(fixture.jamTrack.name == "Original")
        #expect(fixture.jamTrack.parts.map(\.persistentModelID) == originalDraft.parts.compactMap(\.persistentID))
        #expect(fixture.jamTrack.jamTrackSections.map(\.persistentModelID) == originalDraft.sections.compactMap(\.persistentID))
        #expect(fixture.sectionPart.patternName == "Original Pattern")
        #expect(fixture.viewModel.draft.name == "Changed Name")
        #expect(!fixture.context.hasChanges)
    }

    @Test
    func saveWithInvalidLaterSectionLeavesPartsAndGraphUnchanged() throws {
        let fixture = try Fixture()
        let originalPartIDs = fixture.jamTrack.parts.map(\.persistentModelID)
        let originalSectionIDs = fixture.jamTrack.jamTrackSections.map(\.persistentModelID)

        fixture.viewModel.name = "Changed Name"
        fixture.viewModel.addPart(instrument: fixture.drums)
        fixture.viewModel.setSongSection(
            try fixture.makeInvalidSongSectionID(),
            for: fixture.viewModel.draft.sections[0].id
        )

        #expect(!fixture.viewModel.save(modelContext: fixture.context))
        #expect(fixture.viewModel.errorMessage == "Save failed: each section needs a song section.")
        #expect(fixture.jamTrack.name == "Original")
        #expect(fixture.jamTrack.parts.map(\.persistentModelID) == originalPartIDs)
        #expect(fixture.jamTrack.jamTrackSections.map(\.persistentModelID) == originalSectionIDs)
        #expect(fixture.sectionPart.patternName == "Original Pattern")
        #expect(fixture.viewModel.hasUnsavedChanges)
        #expect(!fixture.context.hasChanges)
    }

    @Test
    func saveWithDanglingSectionPartLeavesPartsAndGraphUnchanged() throws {
        let fixture = try Fixture()
        let originalPartIDs = fixture.jamTrack.parts.map(\.persistentModelID)
        let originalSectionIDs = fixture.jamTrack.jamTrackSections.map(\.persistentModelID)
        let sectionID = fixture.viewModel.draft.sections[0].id

        fixture.viewModel.name = "Changed Name"
        fixture.viewModel.addPart(instrument: fixture.drums)
        fixture.viewModel.setPatternReference(
            .harmonic(fixture.newHarmonicPattern.persistentModelID),
            for: sectionID,
            partID: UUID()
        )

        #expect(!fixture.viewModel.save(modelContext: fixture.context))
        #expect(fixture.viewModel.errorMessage == "Save failed: a section references a deleted part.")
        #expect(fixture.jamTrack.name == "Original")
        #expect(fixture.jamTrack.parts.map(\.persistentModelID) == originalPartIDs)
        #expect(fixture.jamTrack.jamTrackSections.map(\.persistentModelID) == originalSectionIDs)
        #expect(fixture.sectionPart.patternName == "Original Pattern")
        #expect(fixture.viewModel.hasUnsavedChanges)
        #expect(!fixture.context.hasChanges)
    }

    @Test
    func resetRestoresInitialCleanDraft() throws {
        let fixture = try Fixture()
        let initialDraft = fixture.viewModel.draft

        fixture.viewModel.name = "Changed"
        fixture.viewModel.addPart(instrument: fixture.drums)
        fixture.viewModel.removeSection(id: fixture.viewModel.draft.sections[0].id)
        #expect(fixture.viewModel.hasUnsavedChanges)

        fixture.viewModel.reset()

        #expect(fixture.viewModel.draft == initialDraft)
        #expect(!fixture.viewModel.hasUnsavedChanges)
    }

    private final class Fixture {
        let context: ModelContext
        let jamTrack: JamTrack
        let guitar: Instrument
        let drums: Instrument
        let songSection: SongSection
        let sectionPart: SectionPart
        let drumPattern: DrumPattern
        let newHarmonicPattern: HarmonicPattern
        let sharedHarmonicPatternA: HarmonicPattern
        let sharedHarmonicPatternB: HarmonicPattern
        let viewModel: JamTrackDetailView.ViewModel

        init() throws {
            let schema = SchemaV1.schema
            let container = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            )
            context = container.mainContext

            let style = Style(name: "Rock")
            let feel = Feel(name: "Straight")
            let key = Key(noteName: "C", sharpsOrFlats: 0, isMajor: true)
            let family = InstrumentFamily(name: "Band", sortOrder: 0)
            guitar = Instrument(name: "Guitar", programNumber: 1, instrumentFamily: family)
            drums = Instrument(name: "Drums", programNumber: 0, instrumentFamily: family)
            songSection = SongSection(name: "Verse", sortOrder: 0)
            jamTrack = JamTrack(name: "Original", style: style, key: key, feel: feel, bpm: 120)
            let part = Part(jamTrack: jamTrack, instrument: guitar)
            let section = JamTrackSection(jamTrack: jamTrack, songSection: songSection, order: 0)
            sectionPart = SectionPart(section: section, part: part, patternName: "Original Pattern")
            let originalHarmonicPattern = HarmonicPattern(name: "Original Pattern", style: style, feel: feel)
            newHarmonicPattern = HarmonicPattern(name: "New Pattern", style: style, feel: feel)
            sharedHarmonicPatternA = HarmonicPattern(name: "Shared Pattern", style: style, feel: feel)
            sharedHarmonicPatternB = HarmonicPattern(name: "Shared Pattern", style: style, feel: feel)
            drumPattern = DrumPattern(name: "Drum Pattern", style: style, feel: feel)

            jamTrack.parts = [part]
            jamTrack.jamTrackSections = [section]
            section.sectionParts = [sectionPart]
            context.insert(style)
            context.insert(feel)
            context.insert(key)
            context.insert(family)
            context.insert(guitar)
            context.insert(drums)
            context.insert(songSection)
            context.insert(jamTrack)
            context.insert(part)
            context.insert(section)
            context.insert(sectionPart)
            context.insert(originalHarmonicPattern)
            context.insert(newHarmonicPattern)
            context.insert(sharedHarmonicPatternA)
            context.insert(sharedHarmonicPatternB)
            context.insert(drumPattern)
            try context.save()

            viewModel = JamTrackDetailView.ViewModel(jamTrack: jamTrack)
        }

        func makeInvalidKeyID() throws -> PersistentIdentifier {
            let container = try ModelContainer(
                for: SchemaV1.schema,
                configurations: ModelConfiguration(schema: SchemaV1.schema, isStoredInMemoryOnly: true)
            )
            let key = Key(noteName: "D", sharpsOrFlats: 2, isMajor: true)
            container.mainContext.insert(key)
            try container.mainContext.save()
            return key.persistentModelID
        }

        func makeInvalidSongSectionID() throws -> PersistentIdentifier {
            let container = try ModelContainer(
                for: SchemaV1.schema,
                configurations: ModelConfiguration(schema: SchemaV1.schema, isStoredInMemoryOnly: true)
            )
            let songSection = SongSection(name: "Chorus", sortOrder: 1)
            container.mainContext.insert(songSection)
            try container.mainContext.save()
            return songSection.persistentModelID
        }

        func makeInvalidHarmonicPatternID() throws -> PersistentIdentifier {
            let container = try ModelContainer(
                for: SchemaV1.schema,
                configurations: ModelConfiguration(schema: SchemaV1.schema, isStoredInMemoryOnly: true)
            )
            let pattern = HarmonicPattern(name: "Missing")
            container.mainContext.insert(pattern)
            try container.mainContext.save()
            return pattern.persistentModelID
        }
    }
}
