//
//  EditSectionView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/2/25.
//

import SwiftUI
import SwiftData

struct SectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Binding var section: Section
    @Query private var sectionParts: [SectionPart]
    private var harmonicPatterns: [HarmonicPattern] = []
    private var drumPatterns: [DrumPattern] = []
    
    init(modelContext: ModelContext, section: Binding<Section>) {
        self._section = section
        let sectionID = section.wrappedValue.persistentModelID
        self._sectionParts = Query(filter: #Predicate<SectionPart> { sectionPart in
            sectionPart.section?.persistentModelID == sectionID
        })
        if let jamTrack = section.wrappedValue.jamTrack {
            do {
                self.harmonicPatterns = try fetchPatterns(jamTrack: jamTrack, modelContext: modelContext)
                self.drumPatterns = try fetchDrumPatterns(jamTrack: jamTrack, modelContext: modelContext)
            } catch {
                fatalError("Fetching patterns failed: \(error)")
            }
        }
    }
    
    var body: some View {
        VStack {
            // Editable List of SectionParts
            List {
                if sectionParts.isEmpty || harmonicPatterns.isEmpty {
                    Text("No parts or patterns available")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(sectionParts.indices, id: \.self) { index in
                        let sectionPart = sectionParts[index]
                        HStack {
                            // First column: Part name (from instrument)
                            Text(sectionPart.part?.instrument?.name ?? "<< Unknown >>")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Second column: Pattern Picker
                            Picker("", selection: Binding(
                                get: { sectionParts[index].patternName },
                                set: { newValue in
                                    sectionParts[index].patternName = newValue
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        print("Failed to save patternName: \(error)")
                                    }
                                }
                            )) {
                                if sectionPart.part?.instrument?.name == "Drums" {
                                    ForEach(drumPatterns) { pattern in
                                        Text(pattern.name).tag(pattern.name)
                                    }
                                } else {
                                    ForEach(harmonicPatterns) { pattern in
                                        Text(pattern.name).tag(pattern.name)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .accessibilityLabel("Select pattern for \(sectionPart.part?.instrument?.name ?? "part")")
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteSectionParts)
                }
            }
            .navigationTitle("Edit Section")
            .padding(.horizontal)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Delete SectionPart entries
    private func deleteSectionParts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sectionParts[index])
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save after deleting section parts: \(error)")
        }
    }
    
    private func fetchDrumPatterns(jamTrack: JamTrack, modelContext: ModelContext) throws -> [DrumPattern] {
        let styleName = jamTrack.style?.name
        let feelName = jamTrack.feel?.name
        
        let fetchDescriptor = FetchDescriptor<DrumPattern>(predicate: #Predicate { drumPattern in
            (styleName == nil || drumPattern.style?.name == styleName) &&
            (feelName == nil || drumPattern.feel?.name == feelName)
        })
                                                           
        let result = try modelContext.fetch(fetchDescriptor)
        return result
    }
    
    // Fetch HarmonicPatterns
    private func fetchPatterns(jamTrack: JamTrack, modelContext: ModelContext) throws -> [HarmonicPattern] {
        let styleName = jamTrack.style?.name
        let feelName = jamTrack.feel?.name
        
        let fetchDescriptor = FetchDescriptor<HarmonicPattern>(
            predicate: #Predicate<HarmonicPattern> { harmonicPattern in
                styleName == nil || harmonicPattern.style?.name == styleName &&
                feelName == nil || harmonicPattern.feel?.name == feelName
            }
        )
        
        let result = try modelContext.fetch(fetchDescriptor)
        return result.isEmpty ? [HarmonicPattern(name: "Default Pattern", style: nil, feel: nil, baseOctave: 4)] : result
    }
}

// Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Style.self, RawNote.self, Key.self, NoteInKey.self, Feel.self,
        SongSection.self, Section.self, InstrumentFamily.self, Instrument.self,
        Part.self, JamTrack.self, ScaleDegree.self, HarmonicNoteInPattern.self,
        HarmonicPattern.self, SectionPart.self, DrumNote.self, DrumNoteInPattern.self,
        DrumPattern.self,
        configurations: config
    )
    
    let style = Style(name: "Rock")
    let jamTrack = JamTrack(name: "Sample Track", style: style)
    let songSection = SongSection(name: "Verse", sortOrder: 2)
    let section = Section(jamTrack: jamTrack, songSection: songSection, order: 1)
    jamTrack.jamTrackSections = [section]
    let instrument = Instrument(name: "Piano", programNumber: 15, instrumentFamily: nil)
    let part = Part(jamTrack: jamTrack, instrument: instrument)
    let sectionPart = SectionPart(section: section, part: part, patternName: "Pattern 1")
    part.sectionParts = [sectionPart]
    section.sectionParts = [sectionPart]
    let harmonicPattern = HarmonicPattern(name: "Pattern 1", style: style, feel: nil, baseOctave: 4)
    
    container.mainContext.insert(style)
    container.mainContext.insert(jamTrack)
    container.mainContext.insert(songSection)
    container.mainContext.insert(section)
    container.mainContext.insert(instrument)
    container.mainContext.insert(part)
    container.mainContext.insert(sectionPart)
    container.mainContext.insert(harmonicPattern)
    
    return NavigationStack {
        SectionDetailView(modelContext: container.mainContext, section: .constant(section))
            .modelContainer(container)
    }
}
