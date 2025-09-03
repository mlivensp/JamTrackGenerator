//
//  JamTrackSpecification.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/18/25.
//

import Foundation

 @Observable class JamTrackSpecification {
     var includeDrumTrack: Bool = true
     var includeBassTrack: Bool = true
     var feel: Feel = .shuffle
     var bpm: UInt8 = 105
     var key: String = "A"
     var numberOfChoruses: Int = 1
     var includeCountIn = true
     var sections: [Section] = []
}

extension JamTrackSpecification {
    func encodeToMidi() -> Data {
        var song = Song()
        song.buildTracks(specification: self)
        var document = MidiDocument(specification: self, song: song)
        document.encodeMidi()
        let midiData = document.encodeMidiToData()
        return Data(midiData)
    }
}
