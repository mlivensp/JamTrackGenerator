//
//  PatternGridView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/18/25.
//

import SwiftData
import SwiftUI

struct PatternsGridView: View {
    let sections: [JamTrackSection]
    @Bindable var part: Part
    @Environment(\.modelContext) private var modelContext

    private func sectionPart(for section: JamTrackSection) -> SectionPart? {
        part.sectionParts.first { $0.section?.id == section.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Row
            HStack {
                Text("Section")
                    .font(.headline)
                    .frame(width: 120, alignment: .leading)
                Text("Pattern")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            // Data Rows
            ForEach(sections) { section in
                Group {
                    if let sectionPart = sectionPart(for: section) {
                        SectionRowView(
                            section: section,
                            sectionPart: sectionPart
                        )
                    } else {
                        HStack {
                            Text(section.songSection?.name ?? "<< Missing Section >>")
                                .frame(width: 120, alignment: .leading)
                                .padding(.horizontal)
                            Text("No pattern")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
// MARK: - Section Row View (handles editing for each row)
struct SectionRowView: View {
    let section: JamTrackSection
    @Bindable var sectionPart: SectionPart
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            Text(section.songSection?.name ?? "<< Missing Section >>")
                .frame(width: 120, alignment: .leading)
                .padding(.horizontal)
            
            Picker("Pattern", selection: $sectionPart.patternName) {
                Text("None").tag("")
                if let part = sectionPart.part {
                    let availablePatterns = self.availablePatterns(isDrumPart: part.isDrumPart)
                    ForEach(availablePatterns, id: \.self) { pattern in
                        Text(pattern).tag(pattern)
                    }
                } else {
                    fatalError(">> Missing Part <<")
                }
            }
            .pickerStyle(.menu)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func availablePatterns(isDrumPart: Bool) -> [String] {
        do {
            if isDrumPart {
                let fetchDescriptor = FetchDescriptor<DrumPattern>(sortBy: [SortDescriptor(\.name)])
                let patterns = try modelContext.fetch(fetchDescriptor)
                return patterns.map(\.name)
            } else {
                let fetchDescriptor = FetchDescriptor<HarmonicPattern>(sortBy: [SortDescriptor(\.name)])
                let patterns = try modelContext.fetch(fetchDescriptor)
                return patterns.map(\.name)
            }
        }
        catch {
            fatalError("failed to fetch patterns: \(error)")
        }
    }
}
//#Preview {
//    PatternGridView()
//}
