import SwiftData
import SwiftUI

struct JamTracksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var navManager: NavigationStateManager
    
    @Query(sort: \JamTrack.name) private var jamTracks: [JamTrack]

    @Binding var selectedJamTrackID: JamTrack.ID?

    var body: some View {
        List(jamTracks, id: \.id, selection: proxyJamTrackId) { jamTrack in
            Text(jamTrack.name)
                .tag(jamTrack.id)
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
    
    var proxyJamTrackId: Binding<JamTrack.ID?> {
        Binding(
        get: { selectedJamTrackID },
        set: { newJamTrackID in
            navManager.requestNavigation {
                selectedJamTrackID = newJamTrackID
            }
        }
        )
    }

    private func addJamTrack() {
        // TODO: need to check for unsaved changes in current thang first
        withAnimation {
            let newJamTrack = JamTrack.newJamTrack(modelContext: modelContext)
            modelContext.insert(newJamTrack)
            selectedJamTrackID = newJamTrack.id
            try? modelContext.save()
        }
    }
}
