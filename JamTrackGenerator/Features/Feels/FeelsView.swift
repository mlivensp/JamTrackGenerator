//
//  FeelsView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/13/25.
//

import SwiftUI
import SwiftData

struct FeelsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var navManager: NavigationStateManager
    
    @Query(sort: \Feel.name) private var feels: [Feel]
    @Binding var selectedFeelID: Feel.ID?

    var body: some View {
        List {
            ForEach(feels) { feel in
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    NavigationLink(value: feel) {
                        Text(feel.name)
                    }
                } else {
                    Text(feel.name)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            proxyFeelID.wrappedValue = feel.id
                        }
                }
#else
                Text(feel.name)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        proxyFeelID.wrappedValue = feel.id
                    }
#endif
            }
        }
        .navigationTitle("Feels")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addFeel) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }
    
    var proxyFeelID: Binding<Feel.ID?> {
        Binding(
            get: { selectedFeelID },
            set: { newFeelID in
                navManager.requestNavigation {
                    selectedFeelID = newFeelID
                }
            }
        )
    }

    private func addFeel() {
        withAnimation {
            navManager.requestNavigation {
                let feel = Feel(name: "New Feel")
                modelContext.insert(feel)
                
                do {
                    try modelContext.save()
                } catch {
                    fatalError(error.localizedDescription)
                }
                
                selectedFeelID = feel.id
            }
        }
    }
}
//#Preview {
//    FeelsView()
//}
