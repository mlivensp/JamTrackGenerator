import SwiftData
import SwiftUI

struct PartDetailView: View {
    @Bindable var part: Part
    let sections: [SchemaV1.JamTrackSection]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFamily: InstrumentFamily?
    @Query(sort: (\InstrumentFamily.name)) private var allInstrumentFamilies: [InstrumentFamily] = []
    @State private var filteredInstruments: [Instrument] = []
    
    var body: some View {
        NavigationStack {
            List {
                HStack {
                    Picker("Family", selection: $selectedFamily) {
                        Text("All Families").tag(nil as InstrumentFamily?) //.tag(InstrumentFamily?.none)
                        ForEach(allInstrumentFamilies) { family in
                            Text(family.name)
                                .tag(family as InstrumentFamily?)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedFamily) { _, newFamily in
                        // Auto-clear instrument if family changes to one that doesn't contain it
                        if let newFamily = newFamily,
                           let currentInstrument = part.instrument,
                           currentInstrument.instrumentFamily != newFamily {
                            part.instrument = nil
                        }
                        updateFilteredInstruments()
                    }
                    
                    Picker("Instrument", selection: $part.instrument) {
                        Text("None").tag(Instrument?.none)
                        ForEach(filteredInstruments) { instrument in
                            Text(instrument.name)
                                .tag(instrument as Instrument?)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(selectedFamily == nil && !allInstrumentFamilies.isEmpty)
                    .onChange(of: part.instrument) { _, _ in
                        updateFilteredInstruments()
                    }
                }
                .onAppear {
                    selectedFamily = part.instrument?.instrumentFamily
                }
                
                // Patterns Grid Section
                SwiftUI.Section {
                    if !sections.isEmpty {
                        PatternsGridView(
                            sections: sections,
                            part: part
                        )
                    } else {
                        Text("No sections available for this jam track")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Patterns")
                }
            }
            .navigationTitle("Edit Part")
            // Cross-platform navigation title display
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                ensureSectionPartsExist()
            }
        }
    }
    
    // MARK: - Private Methods    
    private func updateFilteredInstruments() {
        if let family = selectedFamily {
            filteredInstruments = allInstrumentFamilies
                .first { $0.id == family.id }?
                .instruments ?? []
        } else {
            filteredInstruments = []
        }
    }
    
    private func ensureSectionPartsExist() {
        let existingSectionIds = Set(part.sectionParts.compactMap { $0.section?.id })
        
        for section in sections {
            if !existingSectionIds.contains(section.id) {
                let newSectionPart = SectionPart(
                    section: section,
                    part: part,
                    patternName: ""
                )
                modelContext.insert(newSectionPart)
            }
        }
        
        try? modelContext.save()
    }
}
