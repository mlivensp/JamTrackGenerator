import SwiftData
import SwiftUI

struct JamTracksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var navManager: NavigationStateManager
    
    @Query(sort: \JamTrack.name) private var jamTracks: [JamTrack]

    @Binding var selectedJamTrackID: JamTrack.ID?

    var body: some View {
        List {
            ForEach(jamTracks) { jamTrack in
                HStack {
#if os(iOS) && !targetEnvironment(macCatalyst)
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        // iPhone: NavigationLink without onTapGesture
                        NavigationLink(value: jamTrack) {
                            Text(jamTrack.name)
                        }
                    } else {
                        // iPad: NavigationLink with onTapGesture
                        NavigationLink(value: jamTrack) {
                            Text(jamTrack.name)
                                .border(.blue, width: 1)
                        }
                        .onTapGesture {
                            proxyJamTrackID.wrappedValue = jamTrack.id
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
                        proxyJamTrackID.wrappedValue = jamTrack.id
                        print("Selected JamTrack for macOS: \(jamTrack.name)")
                    }
#endif
                    Spacer()
                    PlaybackControlsView(size: .small) {
                        JamTrackExportService.createURL(for: jamTrack)
                    }
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
    
    var proxyJamTrackID: Binding<JamTrack.ID?> {
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
        withAnimation {
            navManager.requestNavigation {
                let newJamTrack = JamTrackTemplateService.makeDefaultJamTrack(in: modelContext)
                modelContext.insert(newJamTrack)
                
                do {
                    try modelContext.save()
                } catch {
                    fatalError(error.localizedDescription)
                }
                
                selectedJamTrackID = newJamTrack.id
            }
        }
    }
}
