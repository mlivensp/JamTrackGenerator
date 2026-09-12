import Foundation
import SwiftData

extension JamTrackDetailView {
    struct Draft: Equatable {
        enum PatternReference: Hashable {
            case drum(PersistentIdentifier)
            case harmonic(PersistentIdentifier)
        }

        struct Part: Identifiable, Equatable {
            let id: UUID
            let persistentID: PersistentIdentifier?
            var instrumentID: PersistentIdentifier?
            var order: Int
        }

        struct SectionPart: Equatable {
            let persistentID: PersistentIdentifier?
            var partID: UUID
            var patternReference: PatternReference?
        }

        struct Section: Identifiable, Equatable {
            let id: UUID
            let persistentID: PersistentIdentifier?
            var songSectionID: PersistentIdentifier?
            var order: Int
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
            let modelContext = jamTrack.modelContext
            sections = []
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
                            patternReference: Self.patternReference(
                                for: sectionPart,
                                part: sectionPart.part,
                                styleID: styleID,
                                feelID: feelID,
                                in: modelContext
                            )
                        )
                    }
                )
            }
        }

        private static func patternReference(
            for sectionPart: SchemaV1.SectionPart,
            part: SchemaV1.Part?,
            styleID: PersistentIdentifier?,
            feelID: PersistentIdentifier?,
            in modelContext: ModelContext?
        ) -> PatternReference? {
            guard !sectionPart.patternName.isEmpty,
                  let modelContext,
                  let isDrums = part?.instrument?.isDrums else {
                return nil
            }

            if isDrums {
                let patterns = (try? modelContext.fetch(FetchDescriptor<DrumPattern>())) ?? []
                return patterns
                    .filter {
                        $0.name == sectionPart.patternName
                            && ($0.style == nil || $0.style?.persistentModelID == styleID)
                            && ($0.feel == nil || $0.feel?.persistentModelID == feelID)
                    }
                    .sorted { $0.id.uuidString < $1.id.uuidString }
                    .first
                    .map { .drum($0.persistentModelID) }
            }

            let patterns = (try? modelContext.fetch(FetchDescriptor<HarmonicPattern>())) ?? []
            return patterns
                .filter {
                    $0.name == sectionPart.patternName
                        && ($0.style == nil || $0.style?.persistentModelID == styleID)
                        && ($0.feel == nil || $0.feel?.persistentModelID == feelID)
                }
                .sorted { $0.id.uuidString < $1.id.uuidString }
                .first
                .map { .harmonic($0.persistentModelID) }
        }
    }

    @MainActor
    @Observable
    final class ViewModel {
        enum ExportOperationState: Equatable {
            case idle
            case savingAndCreatingExportURL
        }

        var draft: Draft

        private(set) var initialDraft: Draft
        var errorMessage: String?
        private(set) var exportOperationState = ExportOperationState.idle

        let jamTrack: JamTrack

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

        var isSavingAndCreatingExportURL: Bool {
            exportOperationState == .savingAndCreatingExportURL
        }

        var sortedParts: [Draft.Part] {
            draft.parts.sorted { $0.order < $1.order }
        }

        var sortedSections: [Draft.Section] {
            draft.sections.sorted { $0.order < $1.order }
        }

        func setStyle(_ styleID: PersistentIdentifier?) {
            draft.styleID = styleID
        }

        func setFeel(_ feelID: PersistentIdentifier?) {
            draft.feelID = feelID
        }

        func setKey(_ keyID: PersistentIdentifier?) {
            draft.keyID = keyID
        }

        func setInstrument(_ instrumentID: PersistentIdentifier?, for partID: UUID) {
            guard let index = draft.parts.firstIndex(where: { $0.id == partID }) else { return }
            draft.parts[index].instrumentID = instrumentID
        }

        func setSongSection(_ songSectionID: PersistentIdentifier?, for sectionID: UUID) {
            guard let index = draft.sections.firstIndex(where: { $0.id == sectionID }) else { return }
            draft.sections[index].songSectionID = songSectionID
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

        func patternReference(for sectionID: UUID, partID: UUID) -> Draft.PatternReference? {
            draft.sections
                .first { $0.id == sectionID }?
                .sectionParts
                .first { $0.partID == partID }?
                .patternReference
        }

        func setPatternReference(_ patternReference: Draft.PatternReference?, for sectionID: UUID, partID: UUID) {
            guard let sectionIndex = draft.sections.firstIndex(where: { $0.id == sectionID }) else { return }
            if let partIndex = draft.sections[sectionIndex].sectionParts.firstIndex(where: { $0.partID == partID }) {
                draft.sections[sectionIndex].sectionParts[partIndex].patternReference = patternReference
            } else {
                draft.sections[sectionIndex].sectionParts.append(.init(persistentID: nil, partID: partID, patternReference: patternReference))
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
                return true
            } catch {
                errorMessage = "Save failed: \(error.localizedDescription)"
                return false
            }
        }

        func reset() {
            draft = initialDraft
            errorMessage = nil
        }

        func saveAndCreateExportURL(modelContext: ModelContext) -> URL? {
            guard exportOperationState == .idle else { return nil }

            exportOperationState = .savingAndCreatingExportURL
            defer { exportOperationState = .idle }

            guard save(modelContext: modelContext) else { return nil }
            guard let exportURL = JamTrackExportService.createURL(for: jamTrack) else {
                errorMessage = "Export failed: unable to create a MIDI file."
                return nil
            }
            return exportURL
        }

        private func reconcileDraft(into modelContext: ModelContext) -> Bool {
            guard let resolvedDraft = resolveDraft(in: modelContext) else {
                return false
            }

            let oldParts = jamTrack.parts
            let oldSections = jamTrack.jamTrackSections
            var partsByDraftID: [UUID: Part] = [:]
            var sectionsByDraftID: [UUID: JamTrackSection] = [:]

            for partDraft in draft.parts {
                let instrument = resolvedDraft.instrumentsByPartID[partDraft.id]!
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
                let songSection = resolvedDraft.songSectionsBySectionID[sectionDraft.id]!
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
                    let part = partsByDraftID[sectionPartDraft.partID]!
                    let sectionPart = existingSectionParts.first {
                        $0.persistentModelID == sectionPartDraft.persistentID
                    } ?? SectionPart(section: section, part: part, patternName: "")
                    if sectionPart.modelContext == nil {
                        modelContext.insert(sectionPart)
                    }
                    sectionPart.section = section
                    sectionPart.part = part
                    sectionPart.patternName = resolvedDraft.patternName(
                        for: sectionDraft.id,
                        partID: sectionPartDraft.partID
                    )
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
            jamTrack.style = resolvedDraft.style
            jamTrack.feel = resolvedDraft.feel
            jamTrack.key = resolvedDraft.key
            jamTrack.bpm = draft.bpm
            jamTrack.includeCountIn = draft.includeCountIn
            jamTrack.parts = draft.parts.compactMap { partsByDraftID[$0.id] }.sorted { $0.order < $1.order }
            jamTrack.jamTrackSections = draft.sections
                .compactMap { sectionsByDraftID[$0.id] }
                .sorted { $0.order < $1.order }
            return true
        }

        private func resolveDraft(in modelContext: ModelContext) -> ResolvedDraft? {
            guard let style = model(for: draft.styleID, in: modelContext, as: Style.self),
                  let feel = model(for: draft.feelID, in: modelContext, as: Feel.self),
                  let key = model(for: draft.keyID, in: modelContext, as: Key.self) else {
                errorMessage = "Save failed: select a key, style, and feel."
                return nil
            }

            var instrumentsByPartID: [UUID: Instrument] = [:]
            for partDraft in draft.parts {
                guard let instrument = model(for: partDraft.instrumentID, in: modelContext, as: Instrument.self) else {
                    errorMessage = "Save failed: each part needs an instrument."
                    return nil
                }
                instrumentsByPartID[partDraft.id] = instrument
            }

            var songSectionsBySectionID: [UUID: SongSection] = [:]
            var patternNamesBySectionPartKey: [SectionPartKey: String] = [:]
            for sectionDraft in draft.sections {
                guard let songSection = model(for: sectionDraft.songSectionID, in: modelContext, as: SongSection.self) else {
                    errorMessage = "Save failed: each section needs a song section."
                    return nil
                }
                for sectionPartDraft in sectionDraft.sectionParts {
                    guard let instrument = instrumentsByPartID[sectionPartDraft.partID] else {
                        errorMessage = "Save failed: a section references a deleted part."
                        return nil
                    }
                    guard let patternName = resolvePatternName(
                        for: sectionPartDraft.patternReference,
                        instrument: instrument,
                        in: modelContext
                    ) else {
                        return nil
                    }
                    patternNamesBySectionPartKey[
                        .init(sectionID: sectionDraft.id, partID: sectionPartDraft.partID)
                    ] = patternName
                }
                songSectionsBySectionID[sectionDraft.id] = songSection
            }

            return ResolvedDraft(
                style: style,
                feel: feel,
                key: key,
                instrumentsByPartID: instrumentsByPartID,
                songSectionsBySectionID: songSectionsBySectionID,
                patternNamesBySectionPartKey: patternNamesBySectionPartKey
            )
        }

        private func resolvePatternName(
            for reference: Draft.PatternReference?,
            instrument: Instrument,
            in modelContext: ModelContext
        ) -> String? {
            guard let reference else { return "" }

            switch reference {
            case .drum(let id):
                guard instrument.isDrums else {
                    errorMessage = "Save failed: a drum pattern is assigned to a non-drums part."
                    return nil
                }
                guard let pattern = model(for: id, in: modelContext, as: DrumPattern.self) else {
                    errorMessage = "Save failed: the selected drum pattern is no longer available."
                    return nil
                }
                return pattern.name
            case .harmonic(let id):
                guard !instrument.isDrums else {
                    errorMessage = "Save failed: a harmonic pattern is assigned to a drums part."
                    return nil
                }
                guard let pattern = model(for: id, in: modelContext, as: HarmonicPattern.self) else {
                    errorMessage = "Save failed: the selected harmonic pattern is no longer available."
                    return nil
                }
                return pattern.name
            }
        }

        private func model<Model: PersistentModel>(
            for id: PersistentIdentifier?,
            in modelContext: ModelContext,
            as type: Model.Type
        ) -> Model? {
            guard let id else { return nil }
            return modelContext.model(for: id) as? Model
        }

        private struct ResolvedDraft {
            let style: Style
            let feel: Feel
            let key: Key
            let instrumentsByPartID: [UUID: Instrument]
            let songSectionsBySectionID: [UUID: SongSection]
            let patternNamesBySectionPartKey: [SectionPartKey: String]

            func patternName(for sectionID: UUID, partID: UUID) -> String {
                patternNamesBySectionPartKey[
                    .init(sectionID: sectionID, partID: partID)
                ] ?? ""
            }
        }

        private struct SectionPartKey: Hashable {
            let sectionID: UUID
            let partID: UUID
        }
    }
}
