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
        fixture.viewModel.setPatternName(
            "Unsaved Pattern",
            for: fixture.viewModel.draft.sections[0].id,
            partID: fixture.viewModel.draft.parts[0].id
        )

        #expect(fixture.viewModel.hasUnsavedChanges)
        #expect(fixture.jamTrack.name == "Original")
        #expect(fixture.jamTrack.parts.count == originalPartCount)
        #expect(fixture.sectionPart.patternName == originalPattern)
    }

    @Test
    func saveAppliesDraftChanges() throws {
        let fixture = try Fixture()
        fixture.viewModel.name = "Saved Name"
        fixture.viewModel.addPart(instrument: fixture.drums)
        fixture.viewModel.setPatternName(
            "New Pattern",
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
        let sectionPart: SectionPart
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
            let songSection = SongSection(name: "Verse", sortOrder: 0)
            jamTrack = JamTrack(name: "Original", style: style, key: key, feel: feel, bpm: 120)
            let part = Part(jamTrack: jamTrack, instrument: guitar)
            let section = JamTrackSection(jamTrack: jamTrack, songSection: songSection, order: 0)
            sectionPart = SectionPart(section: section, part: part, patternName: "Original Pattern")

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
            try context.save()

            viewModel = JamTrackDetailView.ViewModel(jamTrack: jamTrack)
        }
    }
}
