import SwiftData
import SwiftUI

enum PatternSelection: Hashable {
    case drum(id: UUID)
    case harmonic(id: UUID)
}

struct JamTrackMatrixView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var viewModel: JamTrackDetailView.ViewModel
    @Query(sort: \SongSection.sortOrder) var songSections: [SongSection]
    @Query var instruments: [Instrument]
    @Query var drumPatterns: [DrumPattern]
    @Query var harmonicPatterns: [HarmonicPattern]
    @Query var instrumentFamilies: [InstrumentFamily]

    @State private var pendingPartDeletion: Part?
    @State private var pendingSectionDeletion: JamTrackSection?
    
    var body: some View {
        VStack {
//            HStack {
//                
//            }
//            .padding()
            
            ScrollView([.horizontal, .vertical]) {
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    // Top-left corner cell
                    ZStack {
                        // Diagonal line
                        Path { path in
                            path.move(to: .zero)
                            path.addLine(to: CGPoint(x: 150, y: 50))
                            path.move(to: CGPoint(x: 0, y: 50))
                            path.addLine(to: CGPoint(x: 150, y: 50))
                            path.move(to: CGPoint(x: 150, y: 0))
                            path.addLine(to: CGPoint(x: 150, y: 50))
                        }
                        .stroke(Color.gray, lineWidth: 1)
                        Button(action: {
                            let newSection = SongSection(name: "New Section", sortOrder: 5)
                            viewModel.addSection(songSection: newSection)
                        }) {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .background(Color.clear)
                        .position(x: 40, y: 35)

                        Button(action: {
                            guard let family = instrumentFamilies.sorted(by: { $0.sortOrder < $1.sortOrder } ).first,
                                  let newInstrument = family.instruments.sorted(by: { $0.programNumber < $1.programNumber } ).first else { return }
                            viewModel.addPart(instrument: newInstrument)
                        }) {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.blue)
                        }
                        .position(x: 110, y: 15)
                    }
                    .buttonStyle(.plain)
                    .background(Color.clear)
                    .frame(width: 150, height: 50)
                    
                    // Column headers (Parts)
                    ForEach(viewModel.sortedParts, id: \.id) { part in
                        if let actualIndex = viewModel.parts.firstIndex(where: { $0.id == part.id }) {
                            HStack {
                                Picker("", selection: $viewModel.parts[actualIndex].instrument) {
                                    ForEach(instruments.sorted(by: { $0.programNumber < $1.programNumber } )) { instrument in
                                        Text(instrument.name).tag(instrument)
                                    }
                                }
                                .frame(width: 150)
                                
                                Button(role: .destructive) {
                                    pendingPartDeletion = part
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    // Rows
                    ForEach(viewModel.sortedSections, id: \.id) { section in
                        if let actualIndex = viewModel.jamTrackSections.firstIndex(where: { $0.id == section.id }) {
                            HStack {
                                Picker("", selection: $viewModel.jamTrackSections[actualIndex].songSection) {
                                    ForEach(songSections) { section in
                                        Text(section.name).tag(section)
                                    }
                                }
                                
                                Button(role: .destructive) {
                                    pendingSectionDeletion = section
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .frame(height: 50)
                            
                            // Cells
                            ForEach(viewModel.sortedParts, id: \.id) { part in
                                let cellID = "\(section.uuid)-\(part.uuid)"
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
        .alert("Delete Instrument?", isPresented: Binding<Bool>(
            get: { pendingPartDeletion != nil },
            set: { if !$0 { pendingPartDeletion = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let part = pendingPartDeletion {
                    viewModel.removePart(part)
                    pendingPartDeletion = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingPartDeletion = nil
            }
        } message: {
            Text("This will remove the instrument.")
        }

        .alert("Delete Section?", isPresented: Binding<Bool>(
            get: { pendingSectionDeletion != nil },
            set: { if !$0 { pendingSectionDeletion = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let section = pendingSectionDeletion {
                    viewModel.removeSection(section)
                    pendingSectionDeletion = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingSectionDeletion = nil
            }
        } message: {
            Text("This will remove the section.")
        }
    }
    
    private var cellSelections: [String: PatternSelection] {
        var result: [String: PatternSelection] = [:]
        
        for section in viewModel.sortedSections {
            for sectionPart in section.sectionParts {
                guard let part = sectionPart.part,
                      let section = sectionPart.section else { continue }
                
                let cellKey = "\(section.uuid)-\(part.uuid)"
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
        var items: [GridItem] = [.init(.fixed(180))] // Row header
        items += Array(repeating: GridItem(.fixed(180)), count: viewModel.sortedParts.count)
        return items
    }
    
    func patternPicker(section: JamTrackSection, part: Part) -> some View {
        let cellKey = "\(section.uuid)-\(part.uuid)"
        let selected = cellSelections[cellKey]
        
        let isDrums = part.instrument?.isDrums == true
        
        let filtered: [PatternSelection] = isDrums
        ? drumPatterns
            .filter { ($0.style == nil || $0.style == viewModel.style) && ($0.feel == nil || $0.feel == viewModel.feel) }
            .map { .drum(id: $0.id) }
        : harmonicPatterns
            .filter { ($0.style == nil || $0.style == viewModel.style) && ($0.feel == nil || $0.feel == viewModel.feel) }
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
    }
}
