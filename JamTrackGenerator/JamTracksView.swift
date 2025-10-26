import SwiftData
import SwiftUI

struct JamTracksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JamTrack.name) private var jamTracks: [JamTrack]

    // Use @Binding — NOT @Bindable
    @Binding var selectedJamTrack: JamTrack?

    var body: some View {
        List {
            ForEach(jamTracks) { jamTrack in
                HStack {
#if os(iOS) && !targetEnvironment(macCatalyst)
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        NavigationLink(value: jamTrack) {
                            Text(jamTrack.name)
                                .border(.blue, width: 1)
                        }
                    } else {
                        Text(jamTrack.name)
                            .border(.blue, width: 1)
                            .onTapGesture {
                                selectedJamTrack = jamTrack
                            }
                    }
#else
                    Text(jamTrack.name)
                        .border(.blue, width: 1)
                        .onTapGesture {
                            selectedJamTrack = jamTrack
                        }
#endif
                    Spacer()
                    PlaybackControlsView(size: .small, createURL: jamTrack.createURL)
                }
            }
            .onDelete { indexSet in
                // ... deletion logic
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
            try? modelContext.save()
        }
    }
}
