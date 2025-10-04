import SwiftData
import SwiftUI

enum PatternSelection: Hashable {
    case drum(id: String)
    case harmonic(id: String)
}

struct JamTrackMatrixView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var jamTrack: JamTrack
    @Query var songSections: [SongSection]
    @Query var instruments: [Instrument]
    @Query var drumPatterns: [DrumPattern]
    @Query var harmonicPatterns: [HarmonicPattern]
    @Query var instrumentFamilies: [InstrumentFamily]
    @State private var cellSelections: [String: PatternSelection] = [:]
    
    var body: some View {
        VStack {
            HStack {
                Button("Add Section") {
                    let newSection = SongSection(name: "New Section", sortOrder: 5)
                    modelContext.insert(newSection)
                    jamTrack.addSection(songSection: newSection)
                }
                Button("Add Part") {
                    guard let family = instrumentFamilies.first,
                          let newInstrument = family.instruments.first else { return }
                    jamTrack.addPart(instrument: newInstrument)
                }
            }
            .padding()
            
            ScrollView([.horizontal, .vertical]) {
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    // Top-left corner cell
                    Text("JamTrack Matrix")
                        .font(.headline)
                        .frame(width: 150, height: 50)
                        .background(Color.gray.opacity(0.2))
                    
                    // Column headers (Parts)
                    ForEach(jamTrack.sortedParts, id: \.id) { part in
                        if let actualIndex = jamTrack.parts.firstIndex(where: { $0.id == part.id }) {
                            Picker("", selection: $jamTrack.parts[actualIndex].instrument) {
                                ForEach(instruments) { instrument in
                                    Text(instrument.name).tag(instrument)
                                }
                            }
                            .frame(width: 150)
                        }
                    }
                    
                    // Rows
                    ForEach(jamTrack.sortedSections, id: \.id) { section in
                        if let actualIndex = jamTrack.jamTrackSections.firstIndex(where: { $0.id == section.id }) {
                            Picker("", selection: $jamTrack.jamTrackSections[actualIndex].songSection) {
                                ForEach(songSections) { section in
                                    Text(section.name).tag(section)
                                }
                            }
                            .frame(height: 50)
                            
                            // Cells
                            ForEach(jamTrack.sortedParts, id: \.id) { part in
                                let cellID = "\(section.id)-\(part.id)"
                                patternPicker(section: section, part: part)
                                    .id(cellID)
                                    .frame(width: 150, height: 50)
                                    .border(Color.gray)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            for section in jamTrack.sortedSections {
                for sectionPart in section.sectionParts {
                    guard let part = sectionPart.part,
                          let section = sectionPart.section else { continue }
                    
                    let cellKey = "\(section.id)-\(part.id)"
                    let patternName = sectionPart.patternName
                    
                    if part.instrument?.isDrums == true {
                        if let pattern = drumPatterns.first(where: { $0.name == patternName }) {
                            cellSelections[cellKey] = .drum(id: pattern.name)
                        }
                    } else {
                        if let pattern = harmonicPatterns.first(where: { $0.name == patternName }) {
                            cellSelections[cellKey] = .harmonic(id: pattern.name)
                        }
                    }
                }
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        var items: [GridItem] = [.init(.fixed(150))] // Row header
        items += Array(repeating: GridItem(.fixed(150)), count: jamTrack.sortedParts.count)
        return items
    }
    
    func patternPicker(section: JamTrackSection, part: Part) -> some View {
        let cellKey = "\(section.id)-\(part.id)"
        let binding = Binding<PatternSelection?>(
            get: { cellSelections[cellKey] },
            set: { newValue in
                cellSelections[cellKey] = newValue
                
                // Persist to model
                if let newValue {
                    let patternName: String
                    switch newValue {
                    case .drum(let id):
                        guard let pattern = drumPatterns.first(where: { $0.name == id }) else { return }
                        patternName = pattern.name
                    case .harmonic(let id):
                        guard let pattern = harmonicPatterns.first(where: { $0.name == id }) else { return }
                        patternName = pattern.name
                    }
                    
                    if let existing = section.sectionParts.first(where: { $0.part == part }) {
                        existing.patternName = patternName
                    } else {
                        let newSectionPart = SectionPart(section: section, part: part, patternName: patternName)
                        section.sectionParts.append(newSectionPart)
                    }
                }
            }
        )
        
        return Group {
            if let instrument = part.instrument {
                let isDrums = instrument.isDrums
                let patterns: [PatternSelection] = isDrums
                ? drumPatterns.map { .drum(id: $0.name) }
                : harmonicPatterns.map { .harmonic(id: $0.name) }
                
                Picker("", selection: binding) {
                    Text("<Empty>").tag(nil as PatternSelection?)
                    ForEach(patterns, id: \.self) { pattern in
                        switch pattern {
                        case .drum(let id):
                            if let drum = drumPatterns.first(where: { $0.name == id }) {
                                Text(drum.name).tag(PatternSelection.drum(id: id))
                            }
                        case .harmonic(let id):
                            if let harmonic = harmonicPatterns.first(where: { $0.name == id }) {
                                Text(harmonic.name).tag(PatternSelection.harmonic(id: id))
                            }
                        }
                    }
                }
            } else {
                Text("No instrument")
                    .frame(width: 150, height: 50)
                    .background(Color.yellow)
            }
        }
    }
}
