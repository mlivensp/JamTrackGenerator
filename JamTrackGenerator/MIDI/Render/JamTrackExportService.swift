import Foundation
import SwiftData

struct JamTrackExportRequest {
    let style: Style
    let feel: Feel
    let key: Key
    let bpm: UInt8
    let jamTrackSections: [JamTrackSection]
}

enum JamTrackExportService {
    static func createURL(for jamTrack: JamTrack) -> URL? {
        guard let modelContext = jamTrack.modelContext,
              let exportRequest = createExportRequest(for: jamTrack) else {
            return nil
        }
        
        return createURL(for: exportRequest, modelContext: modelContext)
    }
    
    static func createURL(for exportRequest: JamTrackExportRequest, modelContext: ModelContext) -> URL? {
        encodeToMidi(for: exportRequest, modelContext: modelContext).saveToDocuments()
    }
    
    static func encodeToMidi(for exportRequest: JamTrackExportRequest, modelContext: ModelContext) -> Data {
        createMidiDocument(for: exportRequest, modelContext: modelContext).encodeMidiToData()
    }
    
    static func createMidiDocument(for exportRequest: JamTrackExportRequest, modelContext: ModelContext) -> MidiDocument {
        var song = Song(modelContext: modelContext)
        song.buildTracks(
            style: exportRequest.style,
            feel: exportRequest.feel,
            key: exportRequest.key,
            jamTrackSections: exportRequest.jamTrackSections
        )
        
        var document = MidiDocument(
            song: song,
            sharpsOrFlats: exportRequest.key.sharpsOrFlats,
            isMajor: exportRequest.key.isMajor,
            bpm: exportRequest.bpm
        )
        document.encodeMidi()
        return document
    }
    
    private static func createExportRequest(for jamTrack: JamTrack) -> JamTrackExportRequest? {
        guard let style = jamTrack.style,
              let feel = jamTrack.feel,
              let key = jamTrack.key else {
            return nil
        }
        
        return JamTrackExportRequest(
            style: style,
            feel: feel,
            key: key,
            bpm: jamTrack.bpm,
            jamTrackSections: jamTrack.jamTrackSections
        )
    }
}
