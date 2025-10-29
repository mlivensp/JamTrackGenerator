import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var navManager: NavigationStateManager
    @Query(sort: \JamTrack.name) private var jamTracks: [JamTrack]

    // Sidebar selection (first column)
    @State private var selectedCategory: SidebarCategory? = .jamTracks

    // Content list selection (second column) — ID-based
    @State private var selectedJamTrackID: JamTrack.ID?
    @State private var selectedStyleID: Style.ID?

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
            default:
                Text("Select a category")
            }
        } detail: {
            Group {
                switch selectedCategory {
                case .jamTracks:
                    if let id = selectedJamTrackID,
                       let index = jamTracks.firstIndex(where: { $0.id == id }) {
                        // Pass a live property-proxy binding into the editor and use the ID as identity
                        if let binding = jamTrackBinding(for: jamTracks[index]) {
                            JamTrackDetailView(jamTrack: binding)
                                .id(id)
                        } else {
                            Text("Select a Jam Track")
                        }
                    } else {
                        Text("Select a Jam Track")
                    }
                default:
                    Text("Select a category")
                }
            }
            .frame(minWidth: 300)
        }
        .alert("Unsaved Changes",
               isPresented: $navManager.showingUnsavedAlert,
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
        NavigationStack {
            List(SidebarCategory.allCases, id: \.self) { category in
                NavigationLink(value: category) { Text(category.rawValue) }
            }
            .navigationDestination(for: SidebarCategory.self) { category in
                switch category {
                case .jamTracks:
                    JamTracksView(selectedJamTrackID: $selectedJamTrackID)
                default:
                    Text("Select a category")
                }
            }
            .navigationDestination(for: JamTrack.self) { track in
                // NavigationStack pushes a model; resolve by id and provide same editor
                let id = track.id
                if let index = jamTracks.firstIndex(where: { $0.id == id }),
                   let binding = jamTrackBinding(for: jamTracks[index]) {
                    JamTrackDetailView(jamTrack: binding)
                        .id(id)
                } else {
                    Text("Track not found")
                }
            }
            .navigationTitle("Categories")
        }
        .alert("Unsaved Changes",
               isPresented: $navManager.showingUnsavedAlert,
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
    // MARK: - Live property-proxy binding for JamTrack (mutate model fields, don't replace instance)
    private func jamTrackBinding(for track: JamTrack) -> Binding<JamTrack>? {
        guard let index = jamTracks.firstIndex(where: { $0.id == track.id }) else { return nil }
        return Binding(
            get: { jamTracks[index] },
            set: { newValue in
                let target = jamTracks[index]
                target.name = newValue.name
                target.bpm = newValue.bpm
                target.includeCountIn = newValue.includeCountIn
                target.parts = newValue.parts
                target.jamTrackSections = newValue.jamTrackSections
                try? modelContext.save()
            }
        )
    }
}
