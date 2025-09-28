import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var keys: [Key]
    @Query var instruments: [Instrument]
    @Query var harmonicPatterns: [HarmonicPattern]
    @Query var drumPatterns: [DrumPattern]
    @Query var styles: [Style]
    @Query var feels: [Feel]
    
    @State private var errorMessage: String?
    @State private var selectedCategory: SidebarCategory = .jamTracks
    @State private var selectedJamTrack: JamTrack? = nil
    @State private var selectedHarmonicPattern: HarmonicPattern? = nil
    @State private var selectedDrumPatternNavigation: DrumPatternNavigation? = nil
    @State private var selectedStyle: Style? = nil
    @State private var selectedFeel: Feel? = nil
    
    var body: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            splitView
        } else {
            stackView
        }
#else
        splitView
#endif
    }
    
    private var splitView: some View {
        NavigationSplitView {
            // Sidebar
#if os(macOS)
            List(SidebarCategory.allCases, selection: $selectedCategory) { category in
                Text(category.rawValue).tag(category)
            }
            .navigationTitle("Categories")
#else
            List {
                ForEach(SidebarCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = category
                            print("Selected category in splitView: \(category.rawValue)")
                        }
                        .foregroundColor(selectedCategory == category ? .accentColor : .primary)
                        .background(selectedCategory == category ? Color.accentColor.opacity(0.1) : Color.clear)
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle("Categories")
#endif
        } content: {
            CategoryContentView(
                category: selectedCategory,
                selectedJamTrack: $selectedJamTrack,
                selectedStyle: $selectedStyle,
                selectedFeel: $selectedFeel,
                selectedDrumPatternNavigation: $selectedDrumPatternNavigation,
                selectedHarmonicPattern: $selectedHarmonicPattern
            )
        } detail: {
            Group {
                if let jamTrack = selectedJamTrack {
                    JamTrackDetailView(jamTrack: jamTrack)
                } else if let style = selectedStyle {
                    Text(style.name) // Replace with StyleDetailView
                } else if let feel = selectedFeel {
                    Text(feel.name) // Replace with FeelDetailView
                } else if let navigation = selectedDrumPatternNavigation {
                    switch navigation {
                    case .existing(let drumPattern):
                        Text(drumPattern.name) // Replace with DrumPatternDetailView
                    case .importOptions(let trackNotes):
                        PatternImportView(
                            trackNotes: trackNotes,
                            selectedDrumPatternNavigation: $selectedDrumPatternNavigation
                        )
                        .environment(\.modelContext, modelContext)
                    }
                } else if let harmonicPattern = selectedHarmonicPattern {
                    Text(harmonicPattern.name) // Replace with HarmonicPatternDetailView
                } else {
                    Text("Select an item")
                }
            }
            .navigationDestination(for: JamTrack.self) { JamTrackDetailView(jamTrack: $0) }
            .navigationDestination(for: Style.self) { Text($0.name) }
            .navigationDestination(for: Feel.self) { Text($0.name) }
            .navigationDestination(for: DrumPatternNavigation.self) { navigation in
                switch navigation {
                case .existing(let drumPattern):
                    Text(drumPattern.name) // Replace with DrumPatternDetailView
                case .importOptions(let trackNotes):
                    PatternImportView(
                        trackNotes: trackNotes,
                        selectedDrumPatternNavigation: $selectedDrumPatternNavigation
                    )
                    .environment(\.modelContext, modelContext)
                }
            }
            .navigationDestination(for: HarmonicPattern.self) { Text($0.name) }
        }
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        #endif
    }
    
    private var stackView: some View {
        NavigationStack {
            List {
                ForEach(SidebarCategory.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        Text(category.rawValue)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationDestination(for: SidebarCategory.self) { category in
                CategoryContentView(
                    category: category,
                    selectedJamTrack: $selectedJamTrack,
                    selectedStyle: $selectedStyle,
                    selectedFeel: $selectedFeel,
                    selectedDrumPatternNavigation: $selectedDrumPatternNavigation,
                    selectedHarmonicPattern: $selectedHarmonicPattern
                )
                .onAppear {
                    print("Navigated to CategoryContentView for category: \(category.rawValue)")
                }
            }
            .navigationDestination(for: DrumPatternNavigation.self) { navigation in
                switch navigation {
                case .existing(let drumPattern):
                    Text(drumPattern.name) // Replace with DrumPatternDetailView
                        .onAppear { print("Navigated to DrumPatternDetailView for pattern: \(drumPattern.name)") }
                case .importOptions(let trackNotes):
                    PatternImportView(
                        trackNotes: trackNotes,
                        selectedDrumPatternNavigation: $selectedDrumPatternNavigation
                    )
                    .onAppear { print("Navigated to DrumPatternImportOptionsView with \(trackNotes.count) tracks") }
                }
            }
            .onChange(of: selectedDrumPatternNavigation) { oldValue, newValue in
                print("selectedDrumPatternNavigation changed from \(String(describing: oldValue)) to \(String(describing: newValue))")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [JamTrack.self, DrumPattern.self, DrumNote.self, Style.self, Feel.self, JamTrackSection.self], inMemory: true)
}
