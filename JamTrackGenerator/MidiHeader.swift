//
//  MidiHeader.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/25/25.
//

import Foundation

struct MidiHeader{
    private let tag = "MThd"
    private let headerLength: UInt32 = 6
    private let format = UInt16(1)
    let pulsesPerQuarterNote: UInt16
    
    func encodeToData(trackCount: UInt16) -> Data{
        var data = Data()
        data.append(contentsOf: tag.utf8)
        data.append(contentsOf: headerLength.bigEndianBytes)
        data.append(contentsOf: format.bigEndianBytes)
        data.append(contentsOf: trackCount.bigEndianBytes)
        data.append(contentsOf: pulsesPerQuarterNote.bigEndianBytes)
        return data
    }
}
