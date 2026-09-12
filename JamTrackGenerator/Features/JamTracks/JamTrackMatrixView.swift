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

    @State private var pendingPartDeletion: JamTrackDetailView.Draft.Part?
    @State private var pendingSectionDeletion: JamTrackDetailView.Draft.Section?
    
#if canImport(UIKit)
    let systemSeparator = Color(UIColor.separator)
#else
    let systemSeparator = Color(NSColor.separatorColor)
#endif

    fileprivate var topLeftCell: some View {
        ZStack {
            // Diagonal line
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: 180, y: 50))
                path.move(to: CGPoint(x: 0, y: 50))
                path.addLine(to: CGPoint(x: 180, y: 50))
                path.move(to: CGPoint(x: 180, y: 0))
                path.addLine(to: CGPoint(x: 180, y: 50))
            }
            .stroke(Color(.clear), lineWidth: 1)
        }
        .buttonStyle(.plain)
        .background(Color.clear)
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 0) {
                        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 8) {
                            topLeftCell
                                .frame(width: 150, height: 50)
                            
                            // Column headers (Parts)
                            ForEach(viewModel.sortedParts, id: \.id) { part in
                                HStack {
                                    Picker("", selection: viewModel.instrumentBinding(for: part.id, instruments: instruments)) {
                                        Text("Select Instrument").tag(nil as Instrument?)
                                        ForEach(instruments.sorted(by: { $0.programNumber < $1.programNumber } )) { instrument in
                                            Text(instrument.name).tag(instrument as Instrument?)
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
                            .buttonStyle(.plain)
                            .padding()

                            // Rows
                            ForEach(viewModel.sortedSections, id: \.id) { section in
                                HStack {
                                    Picker("", selection: viewModel.songSectionBinding(for: section.id, songSections: songSections)) {
                                        Text("Select Section").tag(nil as SongSection?)
                                        ForEach(songSections) { songSection in
                                            Text(songSection.name).tag(songSection as SongSection?)
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
                                    let cellID = "\(section.id)-\(part.id)"
                                    patternPicker(section: section, part: part)
                                        .id(cellID)
                                        .frame(width: 150, height: 50)
                                        .border(Color.gray)
                                }

                                Text("")
                            }
                            
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    let fetchDescriptor = FetchDescriptor<SongSection>(predicate: #Predicate { songSection in songSection.name == "Chorus"})
                                    guard let chorusSection = try? modelContext.fetch(fetchDescriptor).first else { return }
                                    viewModel.addSection(songSection: chorusSection)
                                }) {
                                    Image(systemName: "plus.circle")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                            }
                            .frame(width: 150, height: 25)
//                            .background(Color.clear)
//                            .position(x: 20, y: 35)
                       }
                    }
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .topLeading)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .alert("Delete Instrument?", isPresented: Binding<Bool>(
                get: { pendingPartDeletion != nil },
                set: { if !$0 { pendingPartDeletion = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let part = pendingPartDeletion {
                        viewModel.removePart(id: part.id)
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
                        viewModel.removeSection(id: section.id)
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
    }
    
    private var cellSelections: [String: PatternSelection] {
        var result: [String: PatternSelection] = [:]
        
        for section in viewModel.sortedSections {
            for sectionPart in section.sectionParts {
                guard let part = viewModel.draft.parts.first(where: { $0.id == sectionPart.partID }),
                      let instrument = instruments.first(where: { $0.persistentModelID == part.instrumentID }) else {
                    continue
                }

                let cellKey = "\(section.id)-\(part.id)"
                if instrument.isDrums {
                    if let pattern = drumPatterns.first(where: { $0.name == sectionPart.patternName }) {
                        result[cellKey] = .drum(id: pattern.id)
                    }
                } else {
                    if let pattern = harmonicPatterns.first(where: { $0.name == sectionPart.patternName }) {
                        result[cellKey] = .harmonic(id: pattern.id)
                    }
                }
            }
        }
        
        return result
    }
    private var gridColumns: [GridItem] {
        var items: [GridItem] = [.init(.fixed(200))] // Row header
        items += Array(repeating: GridItem(.fixed(180)), count: viewModel.sortedParts.count)
        items.append(GridItem(.flexible(minimum: 0, maximum: .infinity)))
        return items
    }
    
    func patternPicker(section: JamTrackDetailView.Draft.Section, part: JamTrackDetailView.Draft.Part) -> some View {
        let cellKey = "\(section.id)-\(part.id)"
        let selected = cellSelections[cellKey]

        let isDrums = instruments.first { $0.persistentModelID == part.instrumentID }?.isDrums == true
        
        let filtered: [PatternSelection] = isDrums
        ? drumPatterns
            .filter {
                ($0.style == nil || $0.style?.persistentModelID == viewModel.draft.styleID)
                    && ($0.feel == nil || $0.feel?.persistentModelID == viewModel.draft.feelID)
            }
            .map { .drum(id: $0.id) }
        : harmonicPatterns
            .filter {
                ($0.style == nil || $0.style?.persistentModelID == viewModel.draft.styleID)
                    && ($0.feel == nil || $0.feel?.persistentModelID == viewModel.draft.feelID)
            }
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
                
                viewModel.setPatternName(patternName, for: section.id, partID: part.id)
            }
        )
        
        return Group {
            if part.instrumentID != nil {
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
