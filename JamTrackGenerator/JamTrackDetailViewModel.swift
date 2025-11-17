import SwiftData
import SwiftUI

extension JamTrackDetailView {
    @Observable
    class ViewModel {
        var name: String {
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        var style: Style?{
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        var feel: Feel?{
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        var key: Key?{
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        var bpm: UInt8{
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        var includeCountIn: Bool{
            didSet {
                navManager?.isDirty = hasUnsavedChanges
            }
        }
        
        var parts: [Part]
        var jamTrackSections: [JamTrackSection]
        
        var errorMessage: String?
        var didSave: Bool = false
        
        var original: JamTrack
        var modelContext: ModelContext?
        
        var navManager: NavigationStateManager?
        
        init(jamTrack: JamTrack) {
            self.original = jamTrack
            
            self.name = jamTrack.name
            self.style = jamTrack.style
            self.feel = jamTrack.feel
            self.key = jamTrack.key
            self.bpm = jamTrack.bpm
            self.includeCountIn = jamTrack.includeCountIn
            
            // Step 1: Build parts first
            let clonedParts: [Part] = jamTrack.parts.compactMap { original in
                guard let instrument = original.instrument else { return nil }
                return Part(jamTrack: jamTrack, instrument: instrument, order: original.order)
            }
            self.parts = clonedParts
            
            // Step 2: Now build sections using clonedParts
            self.jamTrackSections = jamTrack.jamTrackSections.map { section in
                let newSection = JamTrackSection(
                    jamTrack: jamTrack,
                    songSection: section.songSection!,
                    order: section.order
                )
                newSection.sectionParts = section.sectionParts.compactMap { sp in
                    guard let originalPart = sp.part,
                          let matchingPart = clonedParts.first(where: { $0.instrument == originalPart.instrument }) else {
                        return nil
                    }
                    
                    return SectionPart(
                        section: newSection,
                        part: matchingPart,
                        patternName: sp.patternName
                    )
                }
                
                return newSection
            }
        }
        
        var sortedParts: [Part] {
            self.parts.sorted(by: { $0.order < $1.order })
        }
        
        var sortedSections: [JamTrackSection] {
            self.jamTrackSections.sorted(by: { $0.order < $1.order })
        }

        func addPart(instrument: Instrument) {
            let maxOrder = parts.map(\.order).max() ?? -1
            let newPart = Part(jamTrack: original, instrument: instrument, order: maxOrder + 1)
            parts.append(newPart)
        }

        func removePart(_ part: Part) {
            parts.removeAll { $0 == part }
            jamTrackSections.forEach { section in
                section.sectionParts.removeAll { $0.part == part }
            }
        }
        
        func addSection(songSection: SongSection) {
            let maxOrder = jamTrackSections.map(\.order).max() ?? 0
            let newSection = JamTrackSection(jamTrack: original, songSection: songSection, order: maxOrder + 1)
            jamTrackSections.append(newSection)
        }

        func removeSection(_ section: JamTrackSection) {
            jamTrackSections.removeAll { $0 == section }
        }
        
        func addSectionPart(to section: JamTrackSection, part: Part, patternName: String) {
            guard let index = jamTrackSections.firstIndex(where: { $0 === section }) else { return }
            let newSectionPart = SectionPart(section: section, part: part, patternName: patternName)
            jamTrackSections[index].sectionParts.append(newSectionPart)
        }
        
        var hasUnsavedChanges: Bool {
            return !didSave &&
                (name != original.name ||
                 key != original.key ||
                 style != original.style ||
                 feel != original.feel ||
                 bpm != original.bpm ||
                 includeCountIn != original.includeCountIn ||
                 parts != original.parts ||
                 jamTrackSections != original.jamTrackSections)
        }
        
        func commit() {
            original.name = name
            original.key = key
            original.style = style
            original.feel = feel
            original.bpm = bpm
            original.includeCountIn = includeCountIn

            for part in parts {
                part.jamTrack = original
            }

            for section in jamTrackSections {
                section.jamTrack = original
                for sp in section.sectionParts {
                    sp.section = section
                }
            }

            original.parts = parts.sorted(by: { $0.order < $1.order })
            original.jamTrackSections = jamTrackSections.sorted(by: { $0.order < $1.order })
        }
        
        func prepareForSave(modelContext: ModelContext) {
            for part in parts where part.modelContext == nil {
                modelContext.insert(part)
            }
            
            for section in jamTrackSections {
                if section.modelContext == nil {
                    modelContext.insert(section)
                }
                
                for sp in section.sectionParts where sp.modelContext == nil {
                    modelContext.insert(sp)
                }
            }
            
            commit()
        }

        func save(modelContext: ModelContext) {
            prepareForSave(modelContext: modelContext)
            
            do {
                try modelContext.save()
                navManager?.isDirty = false
                didSave = true
            } catch {
                errorMessage = "Save failed: \(error.localizedDescription)"
                didSave = false
            }
        }
        
        func reset() {
            let fresh = ViewModel(jamTrack: original)
            self.name = fresh.name
            self.key = fresh.key
            self.style = fresh.style
            self.feel = fresh.feel
            self.bpm = fresh.bpm
            self.includeCountIn = fresh.includeCountIn
            self.parts = fresh.parts
            self.jamTrackSections = fresh.jamTrackSections
            self.didSave = false
            self.errorMessage = nil
        }
        
        func discardChanges() {
            didSave = false
            errorMessage = nil
        }
        
        func dumpSectionParts() {
            for section in sortedSections {
                for sectionPart in section.sectionParts {
                    print("\(section.songSection?.name ?? "<Unknown Section>") \(sectionPart.part?.instrument?.name ?? "<Unknown Instrument>") \(sectionPart.patternName)")
                }
            }
        }
        
        func createURL() -> URL? {
            guard let modelContext else { return nil }
            save(modelContext: modelContext)
            let document = createMidiDocument(modelContext: modelContext)
            let midiData = document.encodeMidiToData()
            let url = midiData.saveToDocuments()
            return url
        }
        
        func createMidiDocument(modelContext: ModelContext) -> MidiDocument {
            var song = Song(modelContext: modelContext)
            guard let style = style, let feel = feel, let key = key else {
                fatalError("No style, feel or key set for track")
            }
            
            song.buildTracks(style: style, feel: feel, key: key, jamTrackSections: jamTrackSections)
            var document = MidiDocument(song: song, sharpsOrFlats: key.sharpsOrFlats, isMajor: key.isMajor, bpm: bpm)
            document.encodeMidi()
            return document
        }
    }
}
