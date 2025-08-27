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
    
    var header: MidiHeader
    var tracks: [MidiTrack] = []
    
    mutating func buildMetaTrack(specification: JamTrackSpecification) {
        var track = MidiTrack()
        track.addTimeSignature(numerator: 4, denominator: 4)
        track.addTempo(bpm: 120)
        tracks.append(track)
    }
    
    mutating func buildDrumTrack(specification: JamTrackSpecification) {
        var track = MidiTrack()
        var count = 0
        repeat {
            track.add(0x00) // delta time from last event
            track.add([0x99, 0x24, 0x64]) // note on, channel 9, bass drum 2, velocity 100
            track.add(UInt16(480).midiVLQ)
//            track.add([0x83, 0x60, 0x89, 0x24, 0x40]) // vlq encoded 480, note off chanel 9, bass drum 2, release velocity
            track.add([0x89, 0x24, 0x40]) // vlq encoded 480, note off chanel 9, bass drum 2, release velocity
            count += 1
        } while count < 8
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
    
    init(pulsesPerQuarterNote: UInt16) {
        header = .init(pulsesPerQuarterNote: pulsesPerQuarterNote)
        tracks = []
    }
    
    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileNoSuchFile)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let payload = Payload(header: header, tracks: tracks)
        let data = payload.encodeToData()
        return FileWrapper(regularFileWithContents: data)
    }
    
    
}
