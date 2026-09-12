import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var navManager: NavigationStateManager
    @Query(sort: \JamTrack.name) private var jamTracks: [JamTrack]
    @Query(sort: \Style.name) private var styles: [Style]
    @Query(sort: \Feel.name) private var feels: [Feel]
    @Query(sort: \DrumPattern.name) private var drumPatterns: [DrumPattern]
    @Query(sort: \HarmonicPattern.name) private var harmonicPatterns: [HarmonicPattern]

    // Sidebar selection (first column)
    @State private var selectedCategory: SidebarCategory? = .jamTracks

    // Content list selection (second column) — ID-based
    @State private var selectedJamTrackID: JamTrack.ID?
    @State private var selectedStyleID: Style.ID?
    @State private var selectedFeelID: Feel.ID?
    @State private var selectedDrumPatternID: DrumPattern.ID?
    @State private var selectedHarmonicPatternID: HarmonicPattern.ID?
    
    @State private var navPath: NavigationPath = NavigationPath()
    @State private var showUnsavedAlert: Bool = false

    var body: some View {
        VStack {
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
        .onAppear {
            navManager.showUnsavedAlert = {
                self.showUnsavedAlert = true
            }
        }
    }

    // MARK: - Split View (macOS / iPad)
    private var splitView: some View {
        NavigationSplitView {
            List(SidebarCategory.allCases, selection: proxyCategory) { category in
                Text(category.rawValue).tag(category)
            }
            .navigationTitle("Categories")
        } content: {
            switch selectedCategory {
            case .jamTracks:
                JamTracksView(selectedJamTrackID: $selectedJamTrackID)
            case .styles:
                StylesView(selectedStyleID: $selectedStyleID)
            case .feels:
                FeelsView(selectedFeelID: $selectedFeelID)
            case .drumPatterns:
                DrumPatternsView(selectedDrumPatternID: $selectedDrumPatternID)
            case .harmonicPatterns:
                HarmonicPatternsView(selectedHarmonicPatternID: $selectedHarmonicPatternID)
            default:
                Text("Select a category")
            }
        } detail: {
            Group {
                switch selectedCategory {
                case .jamTracks:
                    if let id = selectedJamTrackID,
                       let index = jamTracks.firstIndex(where: { $0.id == id }) {
                        JamTrackDetailView(jamTrack: jamTracks[index], navPath: $navPath)
                            .id(id)
                    } else {
                        Text("Select a Jam Track")
                    }
                case .styles:
                    if let id = selectedStyleID,
                       let index = styles.firstIndex(where: { $0.id == id }) {
                        if let binding = styleBinding(for: styles[index]) {
                            StyleEditView(style: binding, navPath: $navPath)
                                .id(id)
                        } else {
                            Text("Select a Style")
                        }
                    } else {
                        Text("Select a Style")
                    }
                case .feels:
                    if let id = selectedFeelID,
                       let index = feels.firstIndex(where: { $0.id == id }) {
                        if let binding = feelBinding(for: feels[index]) {
                            FeelEditView(feel: binding, navPath: $navPath)
                                .id(id)
                        } else {
                            Text("Select a Feel")
                        }
                    } else {
                        Text("Select a Feel")
                    }
                case .drumPatterns:
                    if let id = selectedDrumPatternID,
                       let index = drumPatterns.firstIndex(where: { $0.id == id }) {
                        if let binding = drumPatternBinding(for: drumPatterns[index]) {
                            DrumPatternEditView(drumPattern: binding, navPath: $navPath)
                                .id(id)
                        } else {
                            Text("Select a Drum Pattern")
                        }
                    } else {
                        Text("Select a Drum Pattern")
                    }
                case .harmonicPatterns:
                    if let id = selectedHarmonicPatternID,
                       let index = harmonicPatterns.firstIndex(where: { $0.id == id }) {
                        if let binding = harmonicPatternBinding(for: harmonicPatterns[index]) {
                            HarmonicPatternEditView(harmonicPattern: binding, navPath: $navPath)
                                .id(id)
                        } else {
                            Text("Select an Harmonic Pattern")
                        }
                    } else {
                        Text("Select an Harmonic Pattern")
                    }
               default:
                    Text("Select a category")
                }
            }
            .frame(minWidth: 300)
        }
        .alert("Unsaved Changes",
               isPresented: $showUnsavedAlert,
               presenting: navManager) { _ in
            Button("Discard Changes", role: .destructive) {
                navManager.discardChangesAndNavigate()
            }
            Button("Cancel", role: .cancel) {
                navManager.cancelNavigation()
            }
        } message: { _ in
            Text("If you navigate away, your changes will be lost.")
        }
    }

    // MARK: - Stack View (iPhone)
    private var stackView: some View {
        NavigationStack(path: $navPath) {
            List(SidebarCategory.allCases, id: \.self) { category in
                NavigationLink(value: category) { Text(category.rawValue) }
            }
            .navigationDestination(for: SidebarCategory.self) { category in
                switch category {
                case .jamTracks:
                    JamTracksView(selectedJamTrackID: $selectedJamTrackID)
                case .styles:
                    StylesView(selectedStyleID: $selectedStyleID)
                case .feels:
                    FeelsView(selectedFeelID: $selectedFeelID)
                case .drumPatterns:
                    DrumPatternsView(selectedDrumPatternID: $selectedDrumPatternID)
                case .harmonicPatterns:
                    HarmonicPatternsView(selectedHarmonicPatternID: $selectedHarmonicPatternID)
                }
            }
            .navigationDestination(for: JamTrack.self) { track in
                // NavigationStack pushes a model; resolve by id and provide same editor
                let id = track.id
                if let index = jamTracks.firstIndex(where: { $0.id == id }) {
                    JamTrackDetailView(jamTrack: jamTracks[index], navPath: $navPath)
                        .id(id)
                } else {
                    Text("Track not found")
                }
            }
            .navigationDestination(for: Style.self) { style in
                let id = style.id
                if let index = styles.firstIndex(where: { $0.id == id }),
                   let binding = styleBinding(for: styles[index]) {
                    StyleEditView(style: binding, navPath: $navPath)
                        .id(id)
                } else {
                    Text("Style not found")
                }
            }
            .navigationDestination(for: Feel.self) { feel in
                let id = feel.id
                if let index = feels.firstIndex(where: { $0.id == id }),
                   let binding = feelBinding(for: feels[index]) {
                    FeelEditView(feel: binding, navPath: $navPath)
                        .id(id)
                } else {
                    Text("Feel not found")
                }
            }
            .navigationDestination(for: DrumPattern.self) { drumPattern in
                let id = drumPattern.id
                if let index = drumPatterns.firstIndex(where: { $0.id == id }),
                   let binding = drumPatternBinding(for: drumPatterns[index]) {
                    DrumPatternEditView(drumPattern: binding, navPath: $navPath)
                        .id(id)
                } else {
                    Text("Drum Pattern not found")
                }
            }
            .navigationDestination(for: HarmonicPattern.self) { harmonicPattern in
                let id = harmonicPattern.id
                if let index = harmonicPatterns.firstIndex(where: { $0.id == id }),
                   let binding = harmonicPatternBinding(for: harmonicPatterns[index]) {
                    HarmonicPatternEditView(harmonicPattern: binding, navPath: $navPath)
                        .id(id)
                } else {
                    Text("Harmonic Pattern not found")
                }
            }
            .navigationTitle("Categories")
        }
        .alert("Unsaved Changes",
               isPresented: $showUnsavedAlert,
               presenting: navManager) { _ in
            Button("Discard Changes", role: .destructive) {
                navManager.discardChangesAndNavigate()
            }
            Button("Cancel", role: .cancel) {
                navManager.cancelNavigation()
            }
        } message: { _ in
            Text("If you navigate away, your changes will be lost.")
        }
    }

    // MARK: - Proxy for sidebar selection (keeps reference to navManager.requestNavigation API)
    private var proxyCategory: Binding<SidebarCategory?> {
        Binding(
            get: { selectedCategory },
            set: { newCategory in
                let _ = print("navManager.isDirty = \(navManager.isDirty)")
                navManager.requestNavigation {
                    selectedCategory = newCategory
                    selectedJamTrackID = nil
                }
            }
        )
    }
    private func styleBinding(for style: Style) -> Binding<Style>? {
        guard let index = styles.firstIndex(where: { $0.id == style.id }) else { return nil }
        return Binding(
            get: { styles[index] },
            set: { newValue in
                let target = styles[index]
                target.name = newValue.name
                try? modelContext.save()
            }
        )
    }
    
    private func feelBinding(for feel: Feel) -> Binding<Feel>? {
        guard let index = feels.firstIndex(where: { $0.id == feel.id }) else { return nil }
        return Binding(
            get: { feels[index] },
            set: { newValue in
                let target = feels[index]
                target.name = newValue.name
                try? modelContext.save()
            }
        )
    }
    
    private func drumPatternBinding(for drumPattern: DrumPattern) -> Binding<DrumPattern>? {
        guard let index = drumPatterns.firstIndex(where: { $0.id == drumPattern.id }) else { return nil }
        return Binding(
            get: { drumPatterns[index] },
            set: { newValue in
                let target = drumPatterns[index]
                target.name = newValue.name
                target.style = newValue.style
                target.feel = newValue.feel
                target.drumNotesInPattern = newValue.drumNotesInPattern
                try? modelContext.save()
            }
        )
    }
    
    private func harmonicPatternBinding(for harmonicPattern: HarmonicPattern) -> Binding<HarmonicPattern>? {
        guard let index = harmonicPatterns.firstIndex(where: { $0.id == harmonicPattern.id }) else { return nil }
        return Binding(
            get: { harmonicPatterns[index] },
            set: { newValue in
                let target = harmonicPatterns[index]
                target.name = newValue.name
                target.style = newValue.style
                target.feel = newValue.feel
                target.baseOctave = newValue.baseOctave
                target.harmonicNotesInPattern = newValue.harmonicNotesInPattern
                try? modelContext.save()
            }
        )
    }
}
