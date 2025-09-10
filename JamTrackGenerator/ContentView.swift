//
//  ContentView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/18/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var definitions: [Definition]
    @Query var keys: [Key]
    @Query var instruments: [Instrument]
    @State private var selectedDefinition: Definition?
    @State private var errorMessage: String?

    var body: some View {
        Group {
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
//        .toolbar {
//            ToolbarItem {
//                Button(action: addItem) {
//                    Label("Add Item", systemImage: "plus")
//                }
//            }
//#if os(iOS)
//            ToolbarItem(placement: .navigationBarTrailing) {
//                EditButton()
//            }
//#endif
//        }
    }

    private var splitView: some View {
        NavigationSplitView {
            List {
                ForEach(instruments.sorted(by: { $0.name < $1.name} )) { instrument in
                    Text(instrument.name)
                }
            }
        } content: {
            List {
                ForEach(definitions) { definition in
                    NavigationLink(value: definition) {
                        Text(definition.name)
                    }
                }
                .onDelete(perform: deleteDefinitions)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addDefinition) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedDefinition {
                JamTrackDetailView(definition: selectedDefinition)
            }
        }
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
    }

    private var stackView: some View {
        NavigationStack {
            if let selectedDefinition {
                JamTrackDetailView(definition: selectedDefinition)
                    .navigationTitle("Jam Track Generator")
            }
        }
    }

    private func addDefinition() {
        withAnimation {
            let newDefinition = Definition.newDefinition(modelContext: modelContext)
            modelContext.insert(newDefinition)
            selectedDefinition = newDefinition
            do {
                try modelContext.save()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteDefinitions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(definitions[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Definition.self, inMemory: true)
}
