import SwiftUI
import SwiftData

struct JamTracksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JamTrack.name) var jamTracks: [JamTrack]
    @Binding var selectedJamTrack: JamTrack?
    @State var viewModel: ViewModel
    
    init(selectedJamTrack: Binding<JamTrack?>) {
        self._selectedJamTrack = selectedJamTrack
        let viewModel = ViewModel()
        self._viewModel = .init(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            ForEach(jamTracks) { jamTrack in
                HStack {
#if os(iOS) && !targetEnvironment(macCatalyst)
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        // iPhone: NavigationLink without onTapGesture
                        NavigationLink(value: jamTrack) {
                            Text(jamTrack.name)
                                .border(.blue, width: 1)
                        }
                    } else {
                        // iPad: NavigationLink with onTapGesture
                        NavigationLink(value: jamTrack) {
                            Text(jamTrack.name)
                                .border(.blue, width: 1)
                        }
                        .onTapGesture {
                            selectedJamTrack = jamTrack
                            print("Selected JamTrack for iPad: \(jamTrack.name)")
                        }
                    }
#else
                    // macOS: NavigationLink with onTapGesture
                    NavigationLink(value: jamTrack) {
                        Text(jamTrack.name)
                            .border(.blue, width: 1)
                    }
                    .onTapGesture {
                        selectedJamTrack = jamTrack
                        print("Selected JamTrack for macOS: \(jamTrack.name)")
                    }
#endif
                    Spacer()
                    PlaybackControlsView(jamTrack: jamTrack, modelContext: modelContext, size: .small)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(jamTracks[index])
                }
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to delete JamTrack: \(error)")
                }
            }
        }
        .navigationTitle("Jam Tracks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addJamTrack) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .background(Color.clear.preference(key: ContentWidthPreferenceKey.self, value: 300))
    }
    
    private func addJamTrack() {
        withAnimation {
            let newJamTrack = JamTrack.newJamTrack(modelContext: modelContext)
            modelContext.insert(newJamTrack)
            selectedJamTrack = newJamTrack
            do {
                try modelContext.save()
            } catch {
                print("Failed to save JamTrack: \(error)")
            }
        }
    }
}
