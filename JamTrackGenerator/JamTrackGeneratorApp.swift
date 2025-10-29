import SwiftUI
import SwiftData

@main
struct JamTrackGeneratorApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Style.self,
            RawNote.self,
            Key.self,
            NoteInKey.self,
            Feel.self,
            SongSection.self,
            JamTrackSection.self,
            InstrumentFamily.self,
            Instrument.self,
            Part.self,
            JamTrack.self,
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

    // ✅ Add this: shared navigation state manager
    var navManager = NavigationStateManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navManager) // ✅ Inject the navigation manager
        }
        .modelContainer(sharedModelContainer)
    }
}
