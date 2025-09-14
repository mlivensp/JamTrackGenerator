//
//  JamTracksView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/13/25.
//

import SwiftUI
import SwiftData

struct JamTracksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var jamTracks: [JamTrack]
    @Binding var selectedJamTrack: JamTrack?
    
    var body: some View {
        VStack {
            List {
                ForEach(jamTracks) { jamTrack in
                    NavigationLink(value: jamTrack) {
                        Text(jamTrack.name)
                            .border(.blue, width: 1)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(jamTracks[index])
                    }
                }
            }
            .navigationTitle("Jam Tracks")
            .navigationDestination(for: JamTrack.self) { jamTrack in
                JamTrackDetailView(jamTrack: jamTrack)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addJamTrack) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    private func addJamTrack() {
        let newJamTrack = JamTrack.newJamTrack(modelContext: modelContext)
        modelContext.insert(newJamTrack)
        selectedJamTrack = newJamTrack
    }
}
//#Preview {
//    JamTracksView()
//}
