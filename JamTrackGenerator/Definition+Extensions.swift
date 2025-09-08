//
//  Definition+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/5/25.
//

import Foundation

extension Definition {
    var includeDrumTrack: Bool {
        let drumPart = sections.map { $0.sectionPartPatterns.map { $0.part }.first(where: { $0?.instrument.name == "Drums" } ) }.first
        return drumPart != nil
    }
    
    var includeBassTrack: Bool {
        true
    }
    

    func encodeToMidi() -> Data {
        var song = Song()
        song.buildTracks(definition: self)
        var document = MidiDocument(definition: self, song: song)
        document.encodeMidi()
        let midiData = document.encodeMidiToData()
        return Data(midiData)
    }
}
