//
//  JamTrackGeneratorApp.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/18/25.
//

import SwiftUI
import SwiftData

@main
struct JamTrackGeneratorApp: App {
    var sharedModelContainer: ModelContainer = {
//        let schema = Schema(versionedSchema: currentSchema)
        let schema = Schema([
            Style.self,
            Note.self,
            Key.self,
            NoteInKey.self,
            Feel.self,
            SongSection.self,
            Section.self,
            InstrumentFamily.self,
            Instrument.self,
            Part.self,
            Definition.self,
            ScaleDegree.self,
            HarmonicNoteInPattern.self,
            HarmonicPattern.self,
            SectionPart.self,
            DrumNote.self,
            DrumNoteInPattern.self,
            DrumPattern.self,
            
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            container.setup()
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
