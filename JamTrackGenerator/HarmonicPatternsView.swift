//
//  InstrumentPatternsView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/13/25.
//

import SwiftData
import SwiftUI

struct HarmonicPatternsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var navManager: NavigationStateManager

    @Query(sort: \HarmonicPattern.name) private var harmonicPatterns: [HarmonicPattern]
    @Binding var selectedHarmonicPatternID: HarmonicPattern.ID?

    @Query(sort: \Style.name) private var styles: [Style]
    @Query(sort: \Feel.name) private var feels: [Feel]
    @State private var importMidi = false
    @State private var importError: String?
    @State private var showImportOptions = false
    @State private var trackNotes: [MidiTrackData] = []
    @State private var selectedStyle: Style? = nil
    @State private var selectedFeel: Feel? = nil
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Picker("Style", selection: $selectedStyle) {
                        Text("All Styles").tag(nil as Style?)
                        ForEach(styles, id: \.self) { style in
                            Text(style.name).tag(style as Style?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Feel", selection: $selectedFeel) {
                        Text("All Feels").tag(nil as Feel?)
                        ForEach(feels, id: \.self) { feel in
                            Text(feel.name).tag(feel as Feel?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.horizontal)
                
                List {
                    Section(header: Text("Harmonic Patterns")) {
                         ForEach(filteredHarmonicPatterns) { harmonicPattern in
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    NavigationLink(value: harmonicPattern) {
                        Text(harmonicPattern.name)
                    }
                } else {
                    Text(harmonicPattern.name)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            proxyHarmonicPatternID.wrappedValue = harmonicPattern.id
                        }
                }
#else
                Text(harmonicPattern.name)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        proxyHarmonicPatternID.wrappedValue = harmonicPattern.id
                    }
#endif
                         }
                         .onDelete { indexSet in
                             for index in indexSet {
                                 modelContext.delete(filteredHarmonicPatterns[index])
                             }
                             try? modelContext.save()
                         }
                     }
                }
            }
            .background(Color.clear.preference(key: ContentWidthPreferenceKey.self, value: 400))
        }
        .navigationTitle("Harmonic Patterns")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    importMidi = true
                }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .fileImporter(isPresented: $importMidi, allowedContentTypes: [.midi]) { result in
            switch result {
            case .success(let url):
                let tracks = importMidi(from: url)
                print("Imported trackNotes: \(tracks.count) tracks")
                if tracks.isEmpty {
                    importError = "No tracks found in the MIDI file."
                } else {
                    trackNotes = tracks
                    showImportOptions = true
                    print("Showing HarmonicPatternImportOptionsView with \(tracks.count) tracks")
                }
            case .failure(let error):
                importError = "Failed to import MIDI file: \(error.localizedDescription)"
                print("File import error: \(error)")
            }
        }
        .sheet(isPresented: $showImportOptions) {
            PatternImportView(trackNotes: trackNotes)
            .environment(\.modelContext, modelContext)
            #if os(macOS)
            .frame(minWidth: 600, idealWidth: 800, minHeight: 500, idealHeight: 600)
            #endif
            .onAppear {
                print("DrumPatternImportOptionsView appeared with \(trackNotes.count) tracks")
            }
        }
        .alert("Import Error", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(importError ?? "Unknown error")
        }
        .onAppear {
            print("DrumPatternsView appeared")
        }
    }
    
    var proxyHarmonicPatternID: Binding<HarmonicPattern.ID?> {
        Binding(
            get: { selectedHarmonicPatternID },
            set: { newHarmonicPatternID in
                navManager.requestNavigation {
                    selectedHarmonicPatternID = newHarmonicPatternID
                }
            }
        )
    }

    private var filteredHarmonicPatterns: [HarmonicPattern] {
        harmonicPatterns.filter { pattern in
            (selectedStyle == nil || pattern.style == selectedStyle) &&
            (selectedFeel == nil || pattern.feel == selectedFeel)
        }
    }
    
    private func importMidi(from url: URL) -> [MidiTrackData] {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource")
            importError = "Unable to access the selected file."
            return []
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let processor = MidiProcessor()
        do {
            let trackNotes = try processor.process(url: url, filter: .all)
            return trackNotes
        } catch {
            print("MIDI processing failed: \(error)")
            importError = "MIDI processing failed: \(error.localizedDescription)"
            return []
        }
    }
}

//#Preview {
//    HarmonicPatternsView()
//}
