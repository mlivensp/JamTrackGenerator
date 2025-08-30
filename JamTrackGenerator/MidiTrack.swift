//
//  MidiTrack.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/25/25.
//

import Foundation

struct MidiTrack{
    let tag = "MTrk"
    var content: [UInt8] = []
    
    mutating func addTimeSignature(beat: UInt8, beatType: UInt8) {
        content.append(contentsOf: [0x00, 0xff, 0x58, 0x04])
        content.append(beat)
        let denominatorBase2 = log2(Double(beatType))
        let denominatorValue = UInt8(clamping: Int(denominatorBase2.rounded()))
        content.append(denominatorValue)
        content.append(contentsOf: [0x18, 0x08])
    }
    
    mutating func addTempo(bpm: UInt8) {
        let microsecondsPerQuarterNote = UInt(60 / Double(bpm) * 1000000)
        let tempoBytes: [UInt8] = microsecondsPerQuarterNote.bigEndianBytes.suffix(3)
        content.append(contentsOf: [0x00, 0xff, 0x51, 0x03])
        content.append(contentsOf: tempoBytes)
    }
    
    mutating func add(_ item: UInt8) {
        content.append(item)
    }
    
    mutating func add(_ items: [UInt8]) {
        content.append(contentsOf: items)
    }
    
    fileprivate mutating func noteOnOff(_ delay: UInt32, _ command: UInt8, _ channel: UInt8, _ note: UInt8, _ velocity: UInt8) {
        content.append(contentsOf: delay.midiVLQ)
        let noteOn: UInt8 = command | channel
        content.append(noteOn)
        content.append(note)
        content.append(velocity)
    }
    
    mutating func addEvent(delay: UInt32, channel: UInt8, command: UInt8, note: UInt8, velocity: Velocity) {
        let channelAndCommand = command|channel
        content.append(contentsOf: delay.midiVLQ)
        content.append(channelAndCommand)
        content.append(note)
        content.append(velocity)
    }
    
    mutating func noteOn(delay: UInt32, channel: UInt8, note: UInt8, velocity: UInt8) {
        let command = UInt8(0x90)
        noteOnOff(delay, command, channel, note, velocity)
    }
    
    mutating func noteOff(delay: UInt32, channel: UInt8, note: UInt8, velocity: UInt8) {
        let command = UInt8(0x80)
        noteOnOff(delay, command, channel, note, velocity)
    }
    
    mutating func endTrack() {
        content.append(contentsOf: [0x00, 0xff, 0x2f, 0x00])
    }

    func encodeToData() -> Data{
        var data = Data()
        data.append(contentsOf: tag.utf8)
        let length = UInt32(content.count)
        data.append(contentsOf: length.bigEndianBytes)
        data.append(contentsOf: content)
        return data
    }
}
