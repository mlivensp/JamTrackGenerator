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
    @State private var export = false

    var body: some View {
        NavigationSplitView {
            Button("Do It") {
                export = true
            }
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .fileExporter(
                isPresented: $export,
                document: buildDocument(specification: specification),
                contentType: .midi,
                defaultFilename: "test") { result in
                    switch result {
                    case .success(let url):
                        print("File saved to \(url)")
                    case .failure(let error):
                        print("Failed to save file: \(error.localizedDescription)")
                    }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    private func buildDocument(specification: JamTrackSpecification) -> MidiDocument {
        var document = MidiDocument(pulsesPerQuarterNote: Constants.pulsesPerQuarterNote)
        document.buildMetaTrack(specification: specification)
        document.buildDrumTrack(specification: specification)
        return document
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
    
    private func writeFile() {
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsURL.appendingPathComponent("test.mid")
//        let fileManager = FileManager.default
//        let homeURL = fileManager.homeDirectoryForCurrentUser
////        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let fileURL = homeURL.appendingPathComponent("test.mid")
//        
                guard let headerData = "MThd".data(using: .utf8) else {
                    fatalError(#function + ": Failed to convert string to data")
                }
                let lengthData: Data = Data([0x00, 0x00, 0x00, 0x06])
                let formatData: Data = Data([0x00, 0x01])
                let trackCountData: Data = Data([0x00, 0x01])
                let timeDivisionData: Data = Data([0x00, 0xFF, 0xFF, 0x03])
                var combinedData = Data()
                combinedData.append(contentsOf: headerData)
                combinedData.append(contentsOf: lengthData)
                combinedData.append(contentsOf: formatData)
                combinedData.append(contentsOf: trackCountData)
                combinedData.append(contentsOf: timeDivisionData)
                do {
                    try combinedData.write(to: fileURL)
                } catch {
                    fatalError(#function + ": \(error)")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
