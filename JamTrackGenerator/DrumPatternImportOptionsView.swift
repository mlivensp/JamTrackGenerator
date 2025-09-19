import SwiftUI
import SwiftData

struct DrumPatternImportOptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DrumNote.midiValue) private var drumNotes: [DrumNote]
    @Query(sort: \Style.name) private var styles: [Style]
    @Query(sort: \Feel.name) private var feels: [Feel]
    let trackNotes: [MidiTrackData]
    @Binding var selectedDrumPatternNavigation: DrumPatternNavigation?
    @State private var selectedTracks: [MidiTrackData: Bool] = [:]
    @State private var trackStyles: [MidiTrackData: Style?] = [:]
    @State private var trackFeels: [MidiTrackData: Feel?] = [:]
    @State private var customNames: [MidiTrackData: String] = [:]
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let gridColumns = [
        GridItem(.fixed(40), alignment: .center), // Toggle
        GridItem(.flexible(), alignment: .leading), // Track Name
        GridItem(.fixed(40), alignment: .trailing), // Drum Icon
        GridItem(.flexible(), alignment: .leading), // Custom Name
        GridItem(.fixed(120), alignment: .leading), // Style
        GridItem(.fixed(120), alignment: .leading) // Feel
    ]
    
    var body: some View {
        NavigationView {
            Form {
                SwiftUI.Section {
                    // Column Headers
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        Text("Select")
                            .font(.headline)
                            .frame(width: 40)
                        Text("Track Name")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("")
                            .frame(width: 40) // Placeholder for Drum Icon
                        Text("Custom Name")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Style")
                            .font(.headline)
                            .frame(width: 120)
                        Text("Feel")
                            .font(.headline)
                            .frame(width: 120)
                    }
                    .padding(.horizontal)
                    
                    // Track Rows
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 10) {
                            ForEach(trackNotes, id: \.self) { track in
                                Toggle("", isOn: Binding(
                                    get: { selectedTracks[track] ?? false },
                                    set: { selectedTracks[track] = $0 }
                                ))
                                .frame(width: 40)
                                
                                Text(track.name.isEmpty ? "Track \(trackNotes.firstIndex(of: track)! + 1)" : track.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if track.isDrumTrack {
                                    Image(systemName: "drum")
                                        .foregroundColor(.accentColor)
                                        .frame(width: 40, alignment: .trailing)
                                } else {
                                    Color.clear
                                        .frame(width: 40)
                                }
                                
                                TextField("Custom Name", text: Binding(
                                    get: { customNames[track] ?? "" },
                                    set: { customNames[track] = $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Picker("", selection: Binding(
                                    get: { trackStyles[track] ?? nil },
                                    set: { trackStyles[track] = $0 }
                                )) {
                                    Text("Empty").tag(nil as Style?)
                                    ForEach(styles) { style in
                                        Text(style.name).tag(style as Style?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                                
                                Picker("", selection: Binding(
                                    get: { trackFeels[track] ?? nil },
                                    set: { trackFeels[track] = $0 }
                                )) {
                                    Text("Empty").tag(nil as Feel?)
                                    ForEach(feels) { feel in
                                        Text(feel.name).tag(feel as Feel?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }
                        }
                        .padding(.horizontal)
                    }
                } header: {
                    Text("MIDI Track Options")
                }
            }
            .navigationTitle("Import Drum Tracks")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        importSelectedTracks()
                    }
                    .disabled(selectedTracks.values.allSatisfy { !$0 })
                }
            }
            .overlay {
                if trackNotes.isEmpty {
                    ContentUnavailableView(
                        "No Tracks Available",
                        systemImage: "exclamationmark.triangle",
                        description: Text("The selected MIDI file contains no tracks or could not be processed.")
                    )
                }
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK") { dismiss() }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                trackNotes.forEach { track in
                    selectedTracks[track] = false
                    trackStyles[track] = nil
                    trackFeels[track] = nil
                    customNames[track] = ""
                }
                print("DrumPatternImportOptionsView appeared with \(trackNotes.count) tracks")
            }
        }
    }
    
    private func importSelectedTracks() {
        let selected = selectedTracks.filter { $0.value }.keys
        if selected.isEmpty {
            errorMessage = "No tracks selected for import."
            showError = true
            return
        }
        
        var hasError = false
        for track in selected {
            let customName = customNames[track]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let patternName = customName?.isEmpty ?? true
                ? (track.name.isEmpty ? "Imported Pattern \(trackNotes.firstIndex(of: track)! + 1)" : track.name)
                : customName!
            
            let newDrumPattern = DrumPattern(
                name: patternName,
                style: trackStyles[track] ?? nil,
                feel: trackFeels[track] ?? nil
            )
            
            let drumNotesInPattern = track.notes.compactMap { midiNote -> DrumNoteInPattern? in
                guard let drumNote = drumNotes.first(where: { $0.midiValue == midiNote.note }) else {
                    return nil
                }
                return DrumNoteInPattern(
                    pattern: newDrumPattern,
                    drumNote: drumNote,
                    timestampOn: UInt(midiNote.tickOn),
                    timestampOff: UInt(midiNote.tickOff)
                )
            }
            
            if drumNotesInPattern.isEmpty {
                hasError = true
                continue
            }
            
            newDrumPattern.drumNotesInPattern = drumNotesInPattern
            modelContext.insert(newDrumPattern)
        }
        
        if hasError {
            errorMessage = "Some tracks could not be imported due to invalid drum notes."
            showError = true
        } else {
            try? modelContext.save()
            dismiss()
        }
    }
}

#Preview {
    let trackNotes = [
        MidiTrackData(name: "Drums", isDrumTrack: true, notes: [
            MidiNote(note: 36, tickOn: 0, tickOff: 100, velocityOn: 100, velocityOff: 0, channel: 10)
        ]),
        MidiTrackData(name: "Piano", isDrumTrack: false, notes: [
            MidiNote(note: 60, tickOn: 0, tickOff: 100, velocityOn: 100, velocityOff: 0, channel: 0)
        ]),
        MidiTrackData(name: "Bass", isDrumTrack: true, notes: [
            MidiNote(note: 38, tickOn: 200, tickOff: 300, velocityOn: 90, velocityOff: 0, channel: 10)
        ])
    ]
    return DrumPatternImportOptionsView(
        trackNotes: trackNotes,
        selectedDrumPatternNavigation: .constant(nil)
    )
    .modelContainer(for: [DrumPattern.self, DrumNote.self, Style.self, Feel.self, Section.self], inMemory: true)
}
