import SwiftUI
import SwiftData

struct PatternImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DrumNote.midiValue) private var drumNotes: [DrumNote]
    @Query(sort: \Style.name) private var styles: [Style]
    @Query(sort: \Feel.name) private var feels: [Feel]
    let trackNotes: [MidiTrackData]
    @State private var viewModel: ViewModel
    
    private let gridColumns = [
        GridItem(.fixed(40), alignment: .center), // Select Toggle
        GridItem(.flexible(minimum: 120, maximum: 200), alignment: .leading), // Track Name
        GridItem(.fixed(40), alignment: .trailing), // Drum Icon
        GridItem(.flexible(minimum: 120, maximum: 200), alignment: .leading), // Pattern Name
        GridItem(.fixed(80), alignment: .leading), // Use Style Checkbox
        GridItem(.fixed(80), alignment: .leading) // Use Feel Checkbox
    ]
    
    init(trackNotes: [MidiTrackData]) {
        self.trackNotes = trackNotes
        self._viewModel = State(wrappedValue: ViewModel(
            drumNotes: [],
            styles: [],
            feels: [],
            trackNotes: trackNotes
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header with Global Pickers
                VStack(alignment: .leading, spacing: 8) {
                    Text("MIDI Track Options")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    HStack(spacing: 16) {
                        Picker("Style", selection: $viewModel.selectedStyle) {
                            Text("None").tag(nil as Style?)
                            ForEach(styles) { style in
                                Text(style.name).tag(style as Style?)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: viewModel.selectedStyle) {
                            if let error = viewModel.validateGlobalStyle() {
                                viewModel.singleErrorMessage = error
                                viewModel.showError = true
                            }
                        }
                        
                        Picker("Feel", selection: $viewModel.selectedFeel) {
                            Text("None").tag(nil as Feel?)
                            ForEach(feels) { feel in
                                Text(feel.name).tag(feel as Feel?)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: viewModel.selectedFeel) {
                            if let error = viewModel.validateGlobalFeel() {
                                viewModel.singleErrorMessage = error
                                viewModel.showError = true
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Column Headers
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        Text("Select")
                            .font(.headline)
                            .frame(width: 40, alignment: .center)
                        Text("Track")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("")
                            .frame(width: 40, alignment: .trailing)
                        Text("Pattern Name")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Use Style")
                            .font(.headline)
                            .frame(width: 80, alignment: .leading)
                        Text("Use Feel")
                            .font(.headline)
                            .frame(width: 80, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                #if os(iOS)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                #else
                .background(Color(NSColor.controlBackgroundColor))
                #endif
                
                // Track Rows
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(trackNotes, id: \.self) { track in
                            TrackRowView(
                                track: track,
                                viewModel: viewModel
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
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
                        Task {
                            await viewModel.importSelectedTracks { success in
                                if success {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .disabled(!viewModel.isDoneButtonEnabled)
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
            .alert("Import Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                    dismiss()
                }
            } message: {
                Text(viewModel.singleErrorMessage)
            }
            .onAppear {
                print("DrumPatternImportOptionsView appeared with \(trackNotes.count) tracks")
                viewModel.configure(with: modelContext)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TrackRowView: View {
    let track: MidiTrackData
    let viewModel: PatternImportView.ViewModel // No @ObservedObject needed
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 10) {
                // Select Toggle
                Toggle("", isOn: Binding(
                    get: { viewModel.selectedTracks[track] ?? false },
                    set: {
                        viewModel.selectedTracks[track] = $0
                        if !$0 {
                            viewModel.patternNames[track] = ""
                        }
                    }
                ))
                .frame(width: 40, alignment: .center)
                
                // Track Name
                Text(track.name.isEmpty ? "Track \(viewModel.trackNotes.firstIndex(of: track)! + 1)" : track.name)
                    .frame(maxWidth: 120, alignment: .leading)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // Drum Icon
                Group {
                    if track.isDrumTrack {
                        Image(systemName: "drum")
                            .foregroundColor(.accentColor)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 40, alignment: .trailing)
                
                // Pattern Name
                TextField("Pattern Name", text: Binding(
                    get: { viewModel.patternNames[track] ?? "" },
                    set: {
                        viewModel.patternNames[track] = $0
                        Task {
                            if let error = await viewModel.validatePatternName(for: track) {
                                viewModel.errorMessages[track] = error
                                //                            viewModel.showError = true
                            } else {
                                viewModel.errorMessages[track] = nil
                            }
                        }
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 120, alignment: .leading)
                
                // Use Style Toggle
                Toggle("", isOn: Binding(
                    get: { viewModel.useStyleForTrack[track] ?? false },
                    set: { viewModel.useStyleForTrack[track] = $0 }
                ))
                .frame(width: 80, alignment: .leading)
                
                // Use Feel Toggle
                Toggle("", isOn: Binding(
                    get: { viewModel.useFeelForTrack[track] ?? false },
                    set: { viewModel.useFeelForTrack[track] = $0 }
                ))
                .frame(width: 80, alignment: .leading)
            }
            .padding(.vertical, 8)
            
            if let errorMessage = viewModel.errorMessages[track] {
                Text(errorMessage)
                    .foregroundStyle(Color.red)
            } else {
                Text("")
                    .foregroundStyle(Color.clear)
            }
        }
    }
}
