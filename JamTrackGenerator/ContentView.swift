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
    @State private var selectedDefinition: Definition?
    
//    @Query private var items: [Item]
//    @State private var specification = JamTrackSpecification()
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
        .toolbar {
            ToolbarItem {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
#endif
        }
    }

    private var splitView: some View {
        NavigationSplitView {
            List {
                Text("Item 1")
                //                ForEach(items) { item in
                //                    NavigationLink {
                //                        Text("Item at \(item.timestamp, format: .dateTime)")
                //                    } label: {
                //                        Text(item.timestamp, format: .dateTime)
                //                    }
                //                }
                //                .onDelete(perform: deleteItems)
            }
        } content: {
            List {
                ForEach(definitions) { definition in
                    NavigationLink(value: definition) {
                        Text(definition.name)
                    }
                }
            }
        } detail: {
            if let selectedDefinition {
                JamTrackDetailView(definition: selectedDefinition)
            }
        }
        .navigationDestination(for: Definition.self, destination: JamTrackDetailView.init)
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

    private func addItem() {
//        withAnimation {
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//        }
    }

    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Definition.self, inMemory: true)
}
