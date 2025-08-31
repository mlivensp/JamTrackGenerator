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
    @Query private var items: [Item]
    @State private var specification = JamTrackSpecification()
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
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: .dateTime)")
                    } label: {
                        Text(item.timestamp, format: .dateTime)
                    }
                }
                .onDelete(perform: deleteItems)
            }
        } detail: {
            JamTrackDetailView()
        }
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
    }

    private var stackView: some View {
        NavigationStack {
            JamTrackDetailView()
            .navigationTitle("Jam Track Generator")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
