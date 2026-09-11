//
//  Data+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 10/17/25.
//

import Foundation

extension Data {
    func saveToDocuments() -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let midiURL = documentsURL.appendingPathComponent("test.midi")
        do {
            try self.write(to: midiURL)
            return midiURL
        } catch {
            print("Failed to write MIDI file: \(error)")
            return nil
        }
    }

}
