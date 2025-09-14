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
    @Query(sort: \JamTrack.name) var jamTracks: [JamTrack]
    @Binding var selectedJamTrack: JamTrack?
    
    var body: some View {
        List {
            ForEach(jamTracks) { jamTrack in
                NavigationLink(value: jamTrack) {
                    Text(jamTrack.name)
                        .border(.blue, width: 1)
                }
                .onTapGesture { selectedJamTrack = jamTrack }
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
//#Preview {
//    JamTracksView()
//}
