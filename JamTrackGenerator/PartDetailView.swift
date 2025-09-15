//
//  EditPartView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/3/25.
//

import SwiftUI
import SwiftData

struct PartDetailView: View {
    @Binding var part: Part
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var sectionParts: [SectionPart]
    @Query private var instruments: [Instrument]
    private var harmonicPatterns: [HarmonicPattern] = []
    private var drumPatterns: [DrumPattern] = []
    @State private var showDrumPatterns = false
    
    init(modelContext: ModelContext, part: Binding<Part>) {
        self._part = part
        let partID = part.wrappedValue.persistentModelID
        self._sectionParts = Query(filter: #Predicate<SectionPart> { sectionPart in
            sectionPart.part?.persistentModelID == partID
        })
        showDrumPatterns = part.wrappedValue.instrument?.name == "Drums"
        
        if let jamTrack = part.wrappedValue.jamTrack {
            do {
                if showDrumPatterns {
                    self.drumPatterns = try fetchDrumPatterns(jamTrack: jamTrack, modelContext: modelContext)
                } else {
                    self.harmonicPatterns = try fetchPatterns(jamTrack: jamTrack, modelContext: modelContext)
                }
            } catch {
                fatalError("Fetching patterns failed: \(error)")
            }
        }
    }
    
    var body: some View {
        VStack {
            // Instrument Picker
            Picker("Instrument", selection: $part.instrument) {
                ForEach(instruments.sorted(by: { $0.name < $1.name } )) { instrument in
                    Text(instrument.name).tag(instrument)
                }
            }
            .pickerStyle(.menu)
            .padding()
            .accessibilityLabel("Select instrument for part")
            
            // Editable List of SectionParts
            List {
                if sectionParts.isEmpty {
                    Text("No sections available")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    
                    ForEach(sectionParts.indices, id: \.self) { index in
                        let sectionPart = sectionParts[index]
                        HStack {
                            // First column: Section name
                            Text(sectionPart.section?.songSection?.name ?? "<< Unknown >>")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Second column: Pattern Picker
                            Picker("", selection: Binding(
                                get: {
                                    sectionParts[index].patternName },
                                set: { newValue in
                                    sectionParts[index].patternName = newValue
                                    try? modelContext.save()
                                }
                            )) {
                                ForEach(harmonicPatterns) { pattern in
                                    Text(pattern.name).tag(pattern.name)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .accessibilityLabel("Select pattern for \(sectionPart.section?.songSection?.name ?? "section")")
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteSectionParts)
                }
            }
            .navigationTitle("Edit Part")
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
        try? modelContext.save()
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
                ((styleName == nil || harmonicPattern.style?.name == styleName) &&
                (feelName == nil || harmonicPattern.feel?.name == feelName))
            }
        )
        
        let result = try modelContext.fetch(fetchDescriptor)
        return result
    }
}

// Preview (same as above)
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
    jamTrack.sections = [section]
    let instrument = Instrument(name: "Piano", programNumber: 15, instrumentFamily: nil)
    let part = Part(jamTrack: jamTrack, instrument: instrument)
    let sectionPart = SectionPart(section: section, part: part, patternName: "Pattern 1")
    part.sectionParts = [sectionPart]
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
        PartDetailView(modelContext: container.mainContext, part: .constant(part))
            .modelContainer(container)
    }
}
//import SwiftUI
//import SwiftData
//
//struct PartDetailView: View {
//    @Binding var part: Part
//    @Environment(\.modelContext) private var modelContext
//    @Query private var sectionParts: [SectionPart]
//    private let harmonicPatterns: [HarmonicPattern]
//    @Query private var instruments: [Instrument]
//    
//    init(part: Binding<Part>) {
//        self._part = part
//        let partID = part.wrappedValue.persistentModelID
//        self._sectionParts = Query(filter: #Predicate<SectionPart> { sectionPart in
//            sectionPart.part?.persistentModelID == partID
//        })
//        self._instruments = Query() // Fetch all instruments
//        do {
//            self.harmonicPatterns = try fetchPatterns(part: part.wrappedValue, modelContext: part.wrappedValue.modelContext ?? ModelContext(ModelContainer(for:             Style.self, RawNote.self, Key.self, NoteInKey.self, Feel.self, SongSection.self, Section.self, InstrumentFamily.self, Instrument.self, Part.self, JamTrack.self, ScaleDegree.self, HarmonicNoteInPattern.self, HarmonicPattern.self, SectionPart.self, DrumNote.self, DrumNoteInPattern.self, DrumPattern.self)))
//        } catch {
//            fatalError("fetching patterns failed: \(error)")
//        }
//    }
//    
//    var body: some View {
//        VStack {
//            // Instrument Picker
//            Picker("Instrument", selection: $part.instrument) {
//                ForEach(instruments) { instrument in
//                    Text(instrument.name).tag(instrument)
//                }
//            }
//            .pickerStyle(.menu)
//            .padding()
//            .accessibilityLabel("Select instrument for part")
//            
//            // Editable List of SectionParts
//            List {
//                if sectionParts.isEmpty {
//                    Text("No sections available")
//                        .foregroundStyle(.secondary)
//                        .frame(maxWidth: .infinity)
//                } else {
//                    ForEach($sectionParts) { $sectionPart in
//                        HStack {
//                            // First column: Section name
//                            Text(sectionPart.section?.songSection?.name ?? "<< Unknown >>")
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                            
//                            // Second column: Pattern Picker
//                            Picker("", selection: $sectionPart.patternName) {
//                                ForEach(harmonicPatterns) { pattern in
//                                    Text(pattern.name).tag(pattern.name)
//                                }
//                            }
//                            .pickerStyle(.menu)
//                            .frame(maxWidth: .infinity, alignment: .trailing)
//                            .accessibilityLabel("Select pattern for \(sectionPart.section?.songSection?.name ?? "section")")
//                        }
//                        .padding(.vertical, 4)
//                    }
//                    .onDelete(perform: deleteSectionParts)
//                }
//            }
//            .navigationTitle("Edit Part")
//            .padding(.horizontal)
//        }
//    }
//    
//    // Delete SectionPart entries
//    private func deleteSectionParts(at offsets: IndexSet) {
//        for index in offsets {
//            modelContext.delete(sectionParts[index])
//        }
//        try? modelContext.save()
//    }
//    
//    // Fetch HarmonicPatterns
//    private func fetchPatterns(part: Part, modelContext: ModelContext) -> [HarmonicPattern] {
//        let styleName = part.jamTrack?.style?.name
//        
//        let fetchDescriptor = FetchDescriptor<HarmonicPattern>(
//            predicate: #Predicate<HarmonicPattern> { harmonicPattern in
//                styleName == nil || harmonicPattern.style?.name == styleName
//            }
//        )
//        
//        do {
//            return try modelContext.fetch(fetchDescriptor)
//        } catch {
//            print("Fetching harmonic patterns failed: \(error.localizedDescription)")
//            return []
//        }
//    }
//}
//
//// Preview
//#Preview {
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: Style.self, RawNote.self, Key.self, NoteInKey.self, Feel.self, SongSection.self, Section.self, InstrumentFamily.self, Instrument.self, Part.self, JamTrack.self, ScaleDegree.self, HarmonicNoteInPattern.self, HarmonicPattern.self, SectionPart.self, DrumNote.self, DrumNoteInPattern.self, DrumPattern.self, configurations: config)
//    
//    let style = Style(name: "Rock")
//    let jamTrack = JamTrack(name: "Sample Track", style: style)
//    let songSection = SongSection(name: "Verse", sortOrder: 2)
//    let section = Section(jamTrack: jamTrack, songSection: songSection, order: 1)
//    jamTrack.sections = [section]
//    let instrument = Instrument(name: "Piano", programNumber: 15, instrumentFamily: nil)
//    let part = Part(jamTrack: jamTrack, instrument: instrument)
//    let sectionPart = SectionPart(section: section, part: part, patternName: "Pattern 1")
//    part.sectionParts = [sectionPart]
//    let harmonicPattern = HarmonicPattern(name: "Pattern 1", style: style, feel: nil, baseOctave: 4)
//    
//    container.mainContext.insert(style)
//    container.mainContext.insert(jamTrack)
//    container.mainContext.insert(songSection)
//    container.mainContext.insert(section)
//    container.mainContext.insert(instrument)
//    container.mainContext.insert(part)
//    container.mainContext.insert(sectionPart)
//    container.mainContext.insert(harmonicPattern)
//    
//    return NavigationStack {
//        PartDetailView(part: .constant(part))
//            .modelContainer(container)
//    }
//}
//struct PartDetailView: View {
//    @Environment(\.modelContext) var modelContext
//    @Query private var instruments: [Instrument]
//    @Binding var part: Part
//    @Environment(\.dismiss) var dismiss
//    
//    @State var selection: String = ""
//    
//    var body: some View {
//        VStack {
//            LabeledContent {
//                Picker("", selection: $part.instrument) {
//                    ForEach(instruments.sorted(by: { $0.name < $1.name } )) { instrument in
//                        Text(instrument.name).tag(instrument)
//                    }
//                }
//            }
//            label: { Text("Instrument") }
//            //                    PatternPickerView(sectionPart: sectionPart)
//            //                    Picker("", selection: $sectionPart.pattern) {
//            //                        List {
//            //                            Text("")
//            //                            Text("One")
//            //                            Text("Two")
//            //                        }
//            //                    }
//
//            let harmonicPatterns = fetchPatterns(part: part, modelContext: modelContext)
//            ForEach(part.sectionParts) { sectionPart in
//                HStack {
//                    Text(sectionPart.section?.songSection?.name ?? "<< Unknown >>")
//
//                    Picker("", selection: $sectionPart.patternName) {
//                        ForEach(harmonicPatterns) { pattern in
//                            Text(pattern.name).tag(pattern.name)
//                        }
//                    }
//                }
//            }
//        }
//        .navigationTitle("Edit Part")
//        .toolbar {
//            ToolbarItem(placement: .cancellationAction) {
//                Button("Cancel") {
//                    dismiss()
//                }
//            }
//            ToolbarItem(placement: .confirmationAction) {
//                Button("Save") {
//                    dismiss()
//                }
//            }
//        }
//    }
//    
//    func fetchPatterns(part: Part, modelContext: ModelContext) -> [String] {
//        let styleName = part.jamTrack?.style?.name // Capture the style name to avoid optional chaining in predicate
//        let feelName = part.jamTrack?.feel?.name
//        
//        let fetchDescriptor = FetchDescriptor<HarmonicPattern>(
//            predicate: #Predicate<HarmonicPattern> { harmonicPattern in
//                // Handle cases where style or name might be nil
//                (styleName == nil || harmonicPattern.style?.name == styleName) &&
//                (feelName == nil || harmonicPattern.feel?.name == feelName)
//            }
//        )
//        
//        do {
//            return try modelContext.fetch(fetchDescriptor).map(\.name)
//        } catch {
//            fatalError("Fetching harmonic patterns failed: \(error.localizedDescription)")
//        }
//    }
//}
//
//struct PatternPickerView: View {
//    @State var sectionPart: SectionPart
//    
//    var body: some View {
//        Picker("Pattern", selection: $sectionPart.patternName) {
//            Text("Simple").tag("Simple")
//            Text("Complex").tag("Complex")
//        }
//    }
//}

//#Preview {
//    @Previewable @State var part = Part(instrument: .accordion)
//    EditPartView(part: $part)
//}
