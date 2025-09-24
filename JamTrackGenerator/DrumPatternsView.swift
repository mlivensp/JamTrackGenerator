import SwiftData
import SwiftUI

struct DrumPatternsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DrumPattern.name) private var drumPatterns: [DrumPattern]
    @Binding var selectedDrumPatternNavigation: DrumPatternNavigation?
    @State private var importMidi = false
    @State private var importError: String?
    @State private var showImportOptions = false
    @State private var trackNotes: [MidiTrackData] = []
    
    var body: some View {
        List {
            SwiftUI.Section {
                ForEach(drumPatterns) { drumPattern in
                    NavigationLink(value: DrumPatternNavigation.existing(drumPattern)) {
                        Text(drumPattern.name)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(drumPatterns[index])
                    }
                    try? modelContext.save()
                }
            } header: {
                Text("Drum Patterns")
            }
        }
        .navigationTitle("Drum Patterns")
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
                    print("Showing DrumPatternImportOptionsView with \(tracks.count) tracks")
                }
            case .failure(let error):
                importError = "Failed to import MIDI file: \(error.localizedDescription)"
                print("File import error: \(error)")
            }
        }
        .sheet(isPresented: $showImportOptions) {
            DrumPatternImportOptionsView(
                trackNotes: trackNotes,
                selectedDrumPatternNavigation: $selectedDrumPatternNavigation
            )
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
