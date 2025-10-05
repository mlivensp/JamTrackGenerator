import SwiftData
import SwiftUI

enum PatternSelection: Hashable {
    case drum(id: UUID)
    case harmonic(id: UUID)
}

struct JamTrackMatrixView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var jamTrack: JamTrack
    @Query(sort: \SongSection.sortOrder) var songSections: [SongSection]
    @Query var instruments: [Instrument]
    @Query var drumPatterns: [DrumPattern]
    @Query var harmonicPatterns: [HarmonicPattern]
    @Query var instrumentFamilies: [InstrumentFamily]
    
    var body: some View {
        VStack {
            HStack {
                Button("Add Section") {
                    let newSection = SongSection(name: "New Section", sortOrder: 5)
                    modelContext.insert(newSection)
                    let _ = jamTrack.addSection(songSection: newSection)
                }
                Button("Add Part") {
                    guard let family = instrumentFamilies.first,
                          let newInstrument = family.instruments.first else { return }
                    let _ = jamTrack.addPart(instrument: newInstrument)
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
    }
    
    private var cellSelections: [String: PatternSelection] {
        var result: [String: PatternSelection] = [:]
        
        for section in jamTrack.sortedSections {
            for sectionPart in section.sectionParts {
                guard let part = sectionPart.part,
                      let section = sectionPart.section else { continue }
                
                let cellKey = "\(section.id)-\(part.id)"
                let patternName = sectionPart.patternName
                
                if part.instrument?.isDrums == true {
                    if let pattern = drumPatterns.first(where: { $0.name == patternName }) {
                        result[cellKey] = .drum(id: pattern.id)
                    }
                } else {
                    if let pattern = harmonicPatterns.first(where: { $0.name == patternName }) {
                        result[cellKey] = .harmonic(id: pattern.id)
                    }
                }
            }
        }
        
        return result
    }
    private var gridColumns: [GridItem] {
        var items: [GridItem] = [.init(.fixed(150))] // Row header
        items += Array(repeating: GridItem(.fixed(150)), count: jamTrack.sortedParts.count)
        return items
    }
    
    func patternPicker(section: JamTrackSection, part: Part) -> some View {
        let cellKey = "\(section.id)-\(part.id)"
        let selected = cellSelections[cellKey]

        let isDrums = part.instrument?.isDrums == true

        let filtered: [PatternSelection] = isDrums
            ? drumPatterns
                .filter { ($0.style == nil || $0.style == jamTrack.style) && ($0.feel == nil || $0.feel == jamTrack.feel) }
                .map { .drum(id: $0.id) }
            : harmonicPatterns
                .filter { ($0.style == nil || $0.style == jamTrack.style) && ($0.feel == nil || $0.feel == jamTrack.feel) }
                .map { .harmonic(id: $0.id) }

        let patterns: [PatternSelection] = {
            guard let selected, !filtered.contains(selected) else { return filtered }
            return [selected] + filtered
        }()

        let binding = Binding<PatternSelection?>(
            get: { selected },
            set: { newValue in
                guard let newValue else { return }

                let patternName: String
                switch newValue {
                case .drum(let id):
                    guard let pattern = drumPatterns.first(where: { $0.id == id }) else {
                        fatalError("Drum pattern with id \(id) not found in drumPatterns")
                    }
                    patternName = pattern.name
                case .harmonic(let id):
                    guard let pattern = harmonicPatterns.first(where: { $0.id == id }) else {
                        fatalError("Harmonic pattern with id \(id) not found in harmonicPatterns")
                    }
                    patternName = pattern.name
                }

                if let existing = section.sectionParts.first(where: { $0.part == part }) {
                    existing.patternName = patternName
                } else {
                    let newSectionPart = SectionPart(section: section, part: part, patternName: patternName)
                    section.sectionParts.append(newSectionPart)
                }
            }
        )

        return Group {
            if part.instrument != nil {
                Picker("", selection: binding) {
                    Text("<Empty>").tag(nil as PatternSelection?)
                    ForEach(patterns, id: \.self) { pattern in
                        let label = patternName(pattern)
                        Text(label).tag(pattern)
                    }
                }
                .id(cellKey)
            } else {
                Text("No instrument")
                    .frame(width: 150, height: 50)
                    .background(Color.yellow)
            }
        }
    }

    private func patternName(_ pattern: PatternSelection) -> String {
        switch pattern {
        case .drum(let id):
            guard let label = drumPatterns.first(where: { $0.id == id })?.name else {
                fatalError("Drum pattern with id \(id) not found in drumPatterns")
            }
            return label
        case .harmonic(let id):
            guard let label = harmonicPatterns.first(where: { $0.id == id })?.name else {
                fatalError("Harmonic pattern with id \(id) not found in harmonicPatterns")
            }
            return label
        }
    }}
