//
//  MidiDocument.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/25/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension FixedWidthInteger {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian) { Array($0) }
    }
}

extension FixedWidthInteger where Self: UnsignedInteger {
    /// Encodes the integer into a MIDI-style Variable-Length Quantity (VLQ).
    var midiVLQ: [UInt8] {
        var value = self
        var bytes: [UInt8] = []

        repeat {
            var byte = UInt8(value & 0x7F) // Take lowest 7 bits
            value >>= 7
            if !bytes.isEmpty {
                byte |= 0x80 // Set MSB if this is not the last byte
            }
            bytes.insert(byte, at: 0) // Prepend to maintain big-endian order
        } while value > 0

        return bytes
    }
}
struct MidiDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.midi] }
    
    let specification: JamTrackSpecification
    let song: Song
    var header: MidiHeader
    var tracks: [MidiTrack] = []
    
    init(specification: JamTrackSpecification, song: Song) {
        self.specification = specification
        self.song = song
        self.header = .init(pulsesPerQuarterNote: Global.pulsesPerQuarterNote)
        self.tracks = []
    }
    
    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileNoSuchFile)
    }
    

    fileprivate func buildMidiEvents(_ instrumentTrack: Track) -> [MidiEvent] {
        var events: [MidiEvent] = []
        for descriptor in instrumentTrack.events {
            events.append(.init(value: descriptor.midiValue, command: 0x90, pulse: descriptor.offsetOn, velocity: descriptor.onVelocity))
            events.append(.init(value: descriptor.midiValue, command: 0x80, pulse: descriptor.offsetOff, velocity: descriptor.offVelocity))
        }
        
        return events
    }
    
    fileprivate func buildMidiTrack(_ events: [MidiEvent], _ instrumentTrack: Track) -> MidiTrack {
        var lastPulse: UInt32 = 0
        var track = MidiTrack()
        if let program = instrumentTrack.program {
            track.add([0x00, 0xc1, program.rawValue])
        }
        
        for event in events {
            let delay = event.pulse - lastPulse
            track.addEvent(delay: delay, channel: instrumentTrack.channel, command: event.command, note: event.value, velocity: event.velocity)
            lastPulse = event.pulse
        }
        
        track.endTrack()
        return track
    }
    
    mutating func encodeMidi() {
        buildMetaTrack()
        for instrumentTrack in song.tracks {
            var events = buildMidiEvents(instrumentTrack)
            events.sort { ($0.pulse, $0.command) < ($1.pulse, $1.command) }
            tracks.append(buildMidiTrack(events, instrumentTrack))
        }
    }
    
    mutating func buildMetaTrack() {
        var track = MidiTrack()
        track.addTimeSignature(beat: 4, beatType: 4)
        track.addTempo(bpm: specification.bpm)
        track.endTrack()
        tracks.append(track)
    }
    
    public struct Payload {
        let header: MidiHeader
        let tracks: [MidiTrack]
        
        init(header: MidiHeader, tracks: [MidiTrack]) {
            self.header = header
            self.tracks = tracks
        }
        
        func encodeToData() -> Data {
            var data = Data()
            data.append(contentsOf: header.encodeToData(trackCount: UInt16(tracks.count)))
            for track in tracks {
                data.append(contentsOf: track.encodeToData())
            }
            return data
        }
    }
    
    func encodeMidiToData() -> Data {
        let payload = Payload(header: header, tracks: tracks)
        return payload.encodeToData()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
//        let payload = Payload(header: header, tracks: tracks)
        let data = encodeMidiToData()
        return FileWrapper(regularFileWithContents: data)
    }
    
    
}
