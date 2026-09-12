import SwiftData
import SwiftUI

extension JamTrackDetailView {
    struct Draft: Equatable {
        struct Part: Identifiable, Equatable {
            let id: UUID
            let persistentID: PersistentIdentifier?
            var instrumentID: PersistentIdentifier?
            var order: Int
        }

        struct SectionPart: Equatable {
            let persistentID: PersistentIdentifier?
            var partID: UUID
            var patternName: String
        }

        struct Section: Identifiable, Equatable {
            let id: UUID
            let persistentID: PersistentIdentifier?
            var songSectionID: PersistentIdentifier?
            var order: UInt8
            var sectionParts: [SectionPart]
        }

        var name: String
        var styleID: PersistentIdentifier?
        var feelID: PersistentIdentifier?
        var keyID: PersistentIdentifier?
        var bpm: UInt8
        var includeCountIn: Bool
        var parts: [Part]
        var sections: [Section]

        init(jamTrack: JamTrack) {
            name = jamTrack.name
            styleID = jamTrack.style?.persistentModelID
            feelID = jamTrack.feel?.persistentModelID
            keyID = jamTrack.key?.persistentModelID
            bpm = jamTrack.bpm
            includeCountIn = jamTrack.includeCountIn

            let partsByPersistentID = Dictionary(
                uniqueKeysWithValues: jamTrack.parts.map { ($0.persistentModelID, UUID()) }
            )
            parts = jamTrack.parts.map {
                Part(
                    id: partsByPersistentID[$0.persistentModelID]!,
                    persistentID: $0.persistentModelID,
                    instrumentID: $0.instrument?.persistentModelID,
                    order: $0.order
                )
            }
            sections = jamTrack.jamTrackSections.map { section in
                Section(
                    id: UUID(),
                    persistentID: section.persistentModelID,
                    songSectionID: section.songSection?.persistentModelID,
                    order: section.order,
                    sectionParts: section.sectionParts.compactMap { sectionPart in
                        guard let partID = sectionPart.part.flatMap({ partsByPersistentID[$0.persistentModelID] }) else {
                            return nil
                        }
                        return SectionPart(
                            persistentID: sectionPart.persistentModelID,
                            partID: partID,
                            patternName: sectionPart.patternName
                        )
                    }
                )
            }
        }
    }

    @MainActor
    @Observable
    final class ViewModel {
        var draft: Draft {
            didSet {
                updateDirtyState()
            }
        }

        private(set) var initialDraft: Draft
        var errorMessage: String?

        let jamTrack: JamTrack
        var modelContext: ModelContext?
        var navManager: NavigationStateManager?

        init(jamTrack: JamTrack) {
            let draft = Draft(jamTrack: jamTrack)
            self.jamTrack = jamTrack
            self.draft = draft
            self.initialDraft = draft
        }

        var name: String {
            get { draft.name }
            set { draft.name = newValue }
        }

        var bpm: UInt8 {
            get { draft.bpm }
            set { draft.bpm = newValue }
        }

        var hasUnsavedChanges: Bool {
            draft != initialDraft
        }

        var sortedParts: [Draft.Part] {
            draft.parts.sorted { $0.order < $1.order }
        }

        var sortedSections: [Draft.Section] {
            draft.sections.sorted { $0.order < $1.order }
        }

        func styleBinding(_ styles: [Style]) -> Binding<Style?> {
            catalogBinding(\.styleID, in: styles)
        }

        func feelBinding(_ feels: [Feel]) -> Binding<Feel?> {
            catalogBinding(\.feelID, in: feels)
        }

        func keyBinding(_ keys: [Key]) -> Binding<Key?> {
            catalogBinding(\.keyID, in: keys)
        }

        func instrumentBinding(for partID: UUID, instruments: [Instrument]) -> Binding<Instrument?> {
            Binding(
                get: {
                    guard let part = self.draft.parts.first(where: { $0.id == partID }) else { return nil }
                    return instruments.first { $0.persistentModelID == part.instrumentID }
                },
                set: { self.updateInstrument(for: partID, instrument: $0) }
            )
        }

        func songSectionBinding(for sectionID: UUID, songSections: [SongSection]) -> Binding<SongSection?> {
            Binding(
                get: {
                    guard let section = self.draft.sections.first(where: { $0.id == sectionID }) else { return nil }
                    return songSections.first { $0.persistentModelID == section.songSectionID }
                },
                set: { self.updateSongSection(for: sectionID, songSection: $0) }
            )
        }

        func addPart(instrument: Instrument) {
            let order = (draft.parts.map(\.order).max() ?? -1) + 1
            draft.parts.append(.init(id: UUID(), persistentID: nil, instrumentID: instrument.persistentModelID, order: order))
        }

        func removePart(id: UUID) {
            draft.parts.removeAll { $0.id == id }
            for index in draft.sections.indices {
                draft.sections[index].sectionParts.removeAll { $0.partID == id }
            }
        }

        func addSection(songSection: SongSection) {
            let order = (draft.sections.map(\.order).max() ?? 0) + 1
            draft.sections.append(.init(id: UUID(), persistentID: nil, songSectionID: songSection.persistentModelID, order: order, sectionParts: []))
        }

        func removeSection(id: UUID) {
            draft.sections.removeAll { $0.id == id }
        }

        func patternName(for sectionID: UUID, partID: UUID) -> String? {
            draft.sections
                .first { $0.id == sectionID }?
                .sectionParts
                .first { $0.partID == partID }?
                .patternName
        }

        func setPatternName(_ patternName: String, for sectionID: UUID, partID: UUID) {
            guard let sectionIndex = draft.sections.firstIndex(where: { $0.id == sectionID }) else { return }
            if let partIndex = draft.sections[sectionIndex].sectionParts.firstIndex(where: { $0.partID == partID }) {
                draft.sections[sectionIndex].sectionParts[partIndex].patternName = patternName
            } else {
                draft.sections[sectionIndex].sectionParts.append(.init(persistentID: nil, partID: partID, patternName: patternName))
            }
        }

        @discardableResult
        func save(modelContext: ModelContext) -> Bool {
            guard reconcileDraft(into: modelContext) else { return false }

            do {
                try modelContext.save()
                let savedDraft = Draft(jamTrack: jamTrack)
                draft = savedDraft
                initialDraft = savedDraft
                errorMessage = nil
                navManager?.isDirty = false
                return true
            } catch {
                errorMessage = "Save failed: \(error.localizedDescription)"
                updateDirtyState()
                return false
            }
        }

        func reset() {
            draft = initialDraft
            errorMessage = nil
            navManager?.isDirty = false
        }

        func createURL() -> URL? {
            guard let modelContext, save(modelContext: modelContext) else { return nil }
            return JamTrackExportService.createURL(for: jamTrack)
        }

        private func updateInstrument(for partID: UUID, instrument: Instrument?) {
            guard let index = draft.parts.firstIndex(where: { $0.id == partID }) else { return }
            draft.parts[index].instrumentID = instrument?.persistentModelID
        }

        private func updateSongSection(for sectionID: UUID, songSection: SongSection?) {
            guard let index = draft.sections.firstIndex(where: { $0.id == sectionID }) else { return }
            draft.sections[index].songSectionID = songSection?.persistentModelID
        }

        private func updateDirtyState() {
            navManager?.isDirty = hasUnsavedChanges
        }

        private func catalogBinding<Model: PersistentModel>(
            _ keyPath: WritableKeyPath<Draft, PersistentIdentifier?>,
            in models: [Model]
        ) -> Binding<Model?> {
            Binding(
                get: { models.first { $0.persistentModelID == self.draft[keyPath: keyPath] } },
                set: { self.draft[keyPath: keyPath] = $0?.persistentModelID }
            )
        }

        private func reconcileDraft(into modelContext: ModelContext) -> Bool {
            guard let style = model(for: draft.styleID, in: modelContext, as: Style.self),
                  let feel = model(for: draft.feelID, in: modelContext, as: Feel.self),
                  let key = model(for: draft.keyID, in: modelContext, as: Key.self) else {
                errorMessage = "Save failed: select a key, style, and feel."
                return false
            }

            let oldParts = jamTrack.parts
            let oldSections = jamTrack.jamTrackSections
            var partsByDraftID: [UUID: Part] = [:]
            var sectionsByDraftID: [UUID: JamTrackSection] = [:]

            for partDraft in draft.parts {
                guard let instrument = model(for: partDraft.instrumentID, in: modelContext, as: Instrument.self) else {
                    errorMessage = "Save failed: each part needs an instrument."
                    return false
                }

                let part = oldParts.first { $0.persistentModelID == partDraft.persistentID }
                    ?? Part(jamTrack: jamTrack, instrument: instrument, order: partDraft.order)
                if part.modelContext == nil {
                    modelContext.insert(part)
                }
                part.instrument = instrument
                part.order = partDraft.order
                part.jamTrack = jamTrack
                partsByDraftID[partDraft.id] = part
            }

            for sectionDraft in draft.sections {
                guard let songSection = model(for: sectionDraft.songSectionID, in: modelContext, as: SongSection.self) else {
                    errorMessage = "Save failed: each section needs a song section."
                    return false
                }

                let section = oldSections.first { $0.persistentModelID == sectionDraft.persistentID }
                    ?? JamTrackSection(jamTrack: jamTrack, songSection: songSection, order: sectionDraft.order)
                if section.modelContext == nil {
                    modelContext.insert(section)
                }
                section.songSection = songSection
                section.order = sectionDraft.order
                section.jamTrack = jamTrack
                sectionsByDraftID[sectionDraft.id] = section

                let existingSectionParts = section.sectionParts
                for sectionPartDraft in sectionDraft.sectionParts {
                    guard let part = partsByDraftID[sectionPartDraft.partID] else {
                        errorMessage = "Save failed: a section references a deleted part."
                        return false
                    }
                    let sectionPart = existingSectionParts.first {
                        $0.persistentModelID == sectionPartDraft.persistentID
                    } ?? SectionPart(section: section, part: part, patternName: sectionPartDraft.patternName)
                    if sectionPart.modelContext == nil {
                        modelContext.insert(sectionPart)
                    }
                    sectionPart.section = section
                    sectionPart.part = part
                    sectionPart.patternName = sectionPartDraft.patternName
                }

                let retainedSectionPartIDs = Set(sectionDraft.sectionParts.compactMap(\.persistentID))
                for sectionPart in existingSectionParts where !retainedSectionPartIDs.contains(sectionPart.persistentModelID) {
                    modelContext.delete(sectionPart)
                }
            }

            let retainedSectionIDs = Set(draft.sections.compactMap(\.persistentID))
            for section in oldSections where !retainedSectionIDs.contains(section.persistentModelID) {
                modelContext.delete(section)
            }
            let retainedPartIDs = Set(draft.parts.compactMap(\.persistentID))
            for part in oldParts where !retainedPartIDs.contains(part.persistentModelID) {
                modelContext.delete(part)
            }

            jamTrack.name = draft.name
            jamTrack.style = style
            jamTrack.feel = feel
            jamTrack.key = key
            jamTrack.bpm = draft.bpm
            jamTrack.includeCountIn = draft.includeCountIn
            jamTrack.parts = draft.parts.compactMap { partsByDraftID[$0.id] }.sorted { $0.order < $1.order }
            jamTrack.jamTrackSections = draft.sections
                .compactMap { sectionsByDraftID[$0.id] }
                .sorted { $0.order < $1.order }
            return true
        }

        private func model<Model: PersistentModel>(
            for id: PersistentIdentifier?,
            in modelContext: ModelContext,
            as type: Model.Type
        ) -> Model? {
            guard let id else { return nil }
            return modelContext.model(for: id) as? Model
        }
    }
}
