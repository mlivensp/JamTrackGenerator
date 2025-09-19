import Foundation
import MIDIKitSMF

// MARK: - Filtering

enum TrackFilter {
    case all
    case drumsOnly
    case nonDrumsOnly
}

// MARK: - Models

struct MidiNote: Hashable {
    let note: UInt8
    let tickOn: UInt64
    let tickOff: UInt64
    let velocityOn: UInt8
    let velocityOff: UInt8
    let channel: UInt8
}

struct MidiTrackData: Hashable {
    let name: String
    let isDrumTrack: Bool
    let notes: [MidiNote]
}

// MARK: - Processor

struct MidiProcessor {
    let pulsesPerQuarterNote: UInt16 = 480
    
    private let drumKeywords = [
        "drum", "drums", "percussion", "perc", "kit",
        "kick", "snare", "hihat", "hi-hat", "tom", "cymbal",
        "ride", "crash", "china", "splash", "cowbell", "conga",
        "bongo", "timbale", "clap", "rim", "shaker", "tambourine",
        "toms", "sticks"
    ]
    
    func process(url: URL, filter: TrackFilter = .all) throws -> [MidiTrackData] {
        let midiFile = try MIDIFile(midiFile: url)
        
        // Determine original PPQN (fallback to 480)
        let originalPPQN: UInt16
        switch midiFile.timeBase {
        case .musical(let ppqn):
            originalPPQN = ppqn
        default:
            originalPPQN = pulsesPerQuarterNote
        }
        
        let normalizationFactor = Double(pulsesPerQuarterNote) / Double(originalPPQN)
        
        var results: [MidiTrackData] = []
        
        for (trackIndex, track) in midiFile.tracks.enumerated() {
            // Try to get a name from meta events
            let foundName = try firstMetaName(in: track, url: url, trackIndex: trackIndex)
            
            // Parse notes with tick normalization
            var notes: [MidiNote] = []
            var activeNotes: [UInt8: (tickOn: UInt64, velocityOn: UInt8, channel: UInt8)] = [:]
            var currentTick: UInt64 = 0
            
            for event in track.events {
                let deltaTicksFilePPQN = UInt64(
                    event.delta.ticksValue(using: .musical(ticksPerQuarterNote: originalPPQN))
                )
                currentTick += UInt64(Double(deltaTicksFilePPQN) * normalizationFactor)
                
                guard let ev = event.event() else { continue }
                
                switch ev {
                case .noteOn(let payload) where payload.velocity.midi1Value > 0:
                    activeNotes[payload.note.number.uInt8Value] = (
                        tickOn: currentTick,
                        velocityOn: UInt8(payload.velocity.midi1Value),
                        channel: UInt8(payload.channel)
                    )
                    
                case .noteOn(let payload) where payload.velocity.midi1Value == 0:
                    let n = payload.note.number.uInt8Value
                    if let (tickOn, velocityOn, channel) = activeNotes.removeValue(forKey: n) {
                        notes.append(MidiNote(
                            note: n,
                            tickOn: tickOn,
                            tickOff: currentTick,
                            velocityOn: velocityOn,
                            velocityOff: 0,
                            channel: channel
                        ))
                    }
                    
                case .noteOff(let payload):
                    let n = payload.note.number.uInt8Value
                    if let (tickOn, velocityOn, channel) = activeNotes.removeValue(forKey: n) {
                        notes.append(MidiNote(
                            note: n,
                            tickOn: tickOn,
                            tickOff: currentTick,
                            velocityOn: velocityOn,
                            velocityOff: UInt8(payload.velocity.midi1Value),
                            channel: channel
                        ))
                    }
                    
                default:
                    continue
                }
            }
            
            // Drum detection
            let hasDrumChannel = notes.contains { $0.channel == 9 }
            
            // Resolve track name with fallbacks
            let originalName: String = {
                if let name = foundName, !name.isEmpty {
                    return name
                }
                if hasDrumChannel {
                    return "Drums"
                }
                return "Track \(trackIndex + 1)"
            }()
            
            let nameSuggestsDrums = !originalName.isEmpty &&
                drumKeywords.contains { originalName.lowercased().contains($0) }
            
            let isDrumTrack = hasDrumChannel || nameSuggestsDrums
            
            // Apply filter
            let passesFilter: Bool
            switch filter {
            case .all: passesFilter = true
            case .drumsOnly: passesFilter = isDrumTrack
            case .nonDrumsOnly: passesFilter = !isDrumTrack
            }
            
            if passesFilter {
                results.append(MidiTrackData(
                    name: originalName,
                    isDrumTrack: isDrumTrack,
                    notes: notes
                ))
            }
        }
        
        return results
    }
    
    // MARK: - Name extraction using smfEvent
    
    private func firstMetaName(in track: MIDIFile.Chunk.Track, url: URL, trackIndex: Int) throws -> String? {
        // First pass: Try surfaced meta events via smfEvent
        for fileEvent in track.events {
            if let midiEvent = fileEvent.event() { // midiEvent is MIDIEvent?
                // Debug: Log every MIDIEvent
                print("Processing MIDIEvent: \(String(describing: midiEvent))")
                
                if let smfEvent = midiEvent.smfEvent(delta: .ticks(0)) {
                    switch smfEvent {
                    case .text(delta: _, event: let textEvent) where textEvent.textType == .trackOrSequenceName:
                        // 0x03 meta event: sequence or track name (String)
                        print("Track/Sequence Name (surfaced): \(textEvent.text)")
                        return textEvent.text // Return the first one found
                    default:
                        // Debug: Log non-track-name SMF events
                        print("Non-track-name SMF event: \(String(describing: smfEvent))")
                        break
                    }
                } else {
                    print("smfEvent returned nil for MIDIEvent: \(String(describing: midiEvent))")
                }
            }
        }
        
        // Fallback: Parse raw MIDI file data for MTrk chunks
        print("No surfaced track name found for track \(trackIndex); attempting raw file parse...")
        let fileData = try Data(contentsOf: url)
        let fileBytes = [UInt8](fileData)
        
        var currentTrackIndex = 0
        var i = 0
        while i < fileBytes.count - 3 {
            // Look for MTrk chunk
            if fileBytes[i] == 0x4D, fileBytes[i + 1] == 0x54, fileBytes[i + 2] == 0x72, fileBytes[i + 3] == 0x6B {
                i += 4
                // Read chunk length (4 bytes, big-endian)
                guard i + 4 <= fileBytes.count else {
                    print("Invalid MTrk chunk length at index \(i)")
                    break
                }
                let length = UInt32(fileBytes[i]) << 24 | UInt32(fileBytes[i + 1]) << 16 | UInt32(fileBytes[i + 2]) << 8 | UInt32(fileBytes[i + 3])
                i += 4
                let trackEnd = i + Int(length)
                guard trackEnd <= fileBytes.count else {
                    print("Invalid track end: \(trackEnd), file size: \(fileBytes.count)")
                    break
                }
                
                // Only parse the track matching trackIndex
                if currentTrackIndex == trackIndex {
                    print("Parsing MTrk chunk for track \(trackIndex): \(length) bytes")
                    // Parse track data for FF 03 <length> <text>
                    var j = i
                    while j < trackEnd - 1 {
                        // Skip delta-time (VLQ)
                        var deltaTime: UInt32 = 0
                        repeat {
                            guard j < trackEnd else {
                                print("Invalid delta-time at index \(j)")
                                break
                            }
                            let byte = fileBytes[j]
                            deltaTime = (deltaTime << 7) | UInt32(byte & 0x7F)
                            j += 1
                        } while j < trackEnd && (fileBytes[j - 1] & 0x80) != 0
                        
                        // Look for FF 03
                        if j < trackEnd - 1, fileBytes[j] == 0xFF, fileBytes[j + 1] == 0x03 {
                            j += 2
                            // Parse VLQ length
                            var length: UInt32 = 0
                            repeat {
                                guard j < trackEnd else {
                                    print("Invalid VLQ length in FF 03 at index \(j)")
                                    break
                                }
                                let byte = fileBytes[j]
                                length = (length << 7) | UInt32(byte & 0x7F)
                                j += 1
                            } while j < trackEnd && (fileBytes[j - 1] & 0x80) != 0
                            
                            let textStart = j
                            let textEnd = textStart + Int(length)
                            guard textEnd <= trackEnd, textStart < textEnd else {
                                print("Invalid text range: start=\(textStart), end=\(textEnd), track end=\(trackEnd)")
                                j = textStart // Move past invalid event
                                continue
                            }
                            
                            let textBytes = fileBytes[textStart..<textEnd]
                            if let name = String(bytes: textBytes, encoding: .ascii) ?? String(bytes: textBytes, encoding: .utf8) {
                                print("Raw-parsed Track/Sequence Name from track \(trackIndex): \(name)")
                                return name
                            } else {
                                print("Failed to decode text from bytes: \(textBytes.map { String(format: "%02X", $0) })")
                            }
                        }
                        j += 1
                    }
                    break // Found the target track, no need to parse further
                }
                i = trackEnd // Skip to next chunk
                currentTrackIndex += 1
            } else {
                i += 1
            }
        }
        
        // Secondary fallback: Check MIDIEvent cases (unlikely to contain FF 03)
        print("No track name found in raw file parse for track \(trackIndex); attempting MIDIEvent fallback...")
        for fileEvent in track.events {
            if let midiEvent = fileEvent.event() {
                var data: [UInt8] = []
                switch midiEvent {
                case .sysEx7(let sysExData):
                    data = sysExData.data
                    print("Found sysEx7 data: \(data.map { String(format: "%02X", $0) }) (ASCII: \(String(bytes: data, encoding: .ascii) ?? "N/A"))")
                case .universalSysEx7(let univData):
                    data = univData.data
                    print("Found universalSysEx7 data: \(data.map { String(format: "%02X", $0) }) (ASCII: \(String(bytes: data, encoding: .ascii) ?? "N/A"))")
                default:
                    print("Skipping MIDIEvent: \(String(describing: midiEvent))")
                    continue
                }
                
                // Meta event: FF 03 <length> <text>
                guard data.count >= 2, data[0] == 0xFF, data[1] == 0x03 else {
                    print("Data does not match FF 03: \(data.map { String(format: "%02X", $0) })")
                    continue
                }
                
                // Parse VLQ length
                var i = 2
                var length: UInt32 = 0
                repeat {
                    guard i < data.count else {
                        print("Invalid VLQ length in data: \(data.map { String(format: "%02X", $0) })")
                        break
                    }
                    let byte = data[i]
                    length = (length << 7) | UInt32(byte & 0x7F)
                    i += 1
                } while i < data.count && (data[i - 1] & 0x80) != 0
                let textStart = i
                let textEnd = textStart + Int(length)
                guard textEnd <= data.count, textStart < textEnd else {
                    print("Invalid text range: start=\(textStart), end=\(textEnd), data count=\(data.count)")
                    continue
                }
                
                let textBytes = data[textStart..<textEnd]
                if let name = String(bytes: textBytes, encoding: .ascii) ?? String(bytes: textBytes, encoding: .utf8) {
                    print("Raw-parsed Track/Sequence Name: \(name)")
                    return name
                } else {
                    print("Failed to decode text from bytes: \(textBytes.map { String(format: "%02X", $0) })")
                }
            }
        }
        
        print("No track name found for track \(trackIndex), even in raw data.")
        return nil // No track/sequence name found
    }
}

// MARK: - Debug helper

func dumpMIDIEvents(from url: URL) {
    do {
        let midiFile = try MIDIFile(midiFile: url)
        
        print("MIDI Format: \(midiFile.format)")
        print("Time Base: \(midiFile.timeBase)")
        print("Track count: \(midiFile.tracks.count)")
        
        // Log raw file data
        let fileData = try Data(contentsOf: url)
        let fileBytes = [UInt8](fileData)
        print("Raw MIDI file data: \(fileBytes.prefix(100).map { String(format: "%02X", $0) })... (total \(fileBytes.count) bytes)")
        
        // Parse raw MTrk chunks
        var trackIndex = 0
        var i = 0
        while i < fileBytes.count - 3 {
            if fileBytes[i] == 0x4D, fileBytes[i + 1] == 0x54, fileBytes[i + 2] == 0x72, fileBytes[i + 3] == 0x6B {
                i += 4
                let length = UInt32(fileBytes[i]) << 24 | UInt32(fileBytes[i + 1]) << 16 | UInt32(fileBytes[i + 2]) << 8 | UInt32(fileBytes[i + 3])
                i += 4
                let trackEnd = i + Int(length)
                guard trackEnd <= fileBytes.count else {
                    print("Invalid track end: \(trackEnd), file size: \(fileBytes.count)")
                    break
                }
                print("\n=== Track \(trackIndex) (Raw MTrk, \(length) bytes) ===")
                print("Raw track data: \(fileBytes[i..<min(i + 100, trackEnd)].map { String(format: "%02X", $0) })...")
                
                let currentTick: UInt64 = 0
                var j = i
                while j < trackEnd {
                    // Parse delta-time
                    var deltaTime: UInt32 = 0
                    repeat {
                        guard j < trackEnd else {
                            print("Invalid delta-time at index \(j)")
                            break
                        }
                        let byte = fileBytes[j]
                        deltaTime = (deltaTime << 7) | UInt32(byte & 0x7F)
                        j += 1
                    } while j < trackEnd && (fileBytes[j - 1] & 0x80) != 0
                    
                    guard j < trackEnd else { break }
                    let eventStart = j
                    // Check for FF 03
                    if j < trackEnd - 1, fileBytes[j] == 0xFF, fileBytes[j + 1] == 0x03 {
                        j += 2
                        var length: UInt32 = 0
                        repeat {
                            guard j < trackEnd else { break }
                            let byte = fileBytes[j]
                            length = (length << 7) | UInt32(byte & 0x7F)
                            j += 1
                        } while j < trackEnd && (fileBytes[j - 1] & 0x80) != 0
                        let textStart = j
                        let textEnd = textStart + Int(length)
                        if textEnd <= trackEnd, textStart < textEnd {
                            let textBytes = fileBytes[textStart..<textEnd]
                            let ascii = String(bytes: textBytes, encoding: .ascii) ?? String(bytes: textBytes, encoding: .utf8) ?? "N/A"
                            print("[tick \(currentTick)] Raw event: FF 03 (Track/Sequence Name): \(textBytes.map { String(format: "%02X", $0) }) (ASCII: \(ascii))")
                        }
                        j = textEnd
                    } else {
                        // Skip event (simplified, assumes status byte + data)
                        while j < trackEnd && (fileBytes[j] & 0x80) == 0 { j += 1 }
                        j += 1
                    }
                    let eventBytes = fileBytes[eventStart..<min(j, trackEnd)]
                    print("[tick \(currentTick)] Raw event data: \(eventBytes.map { String(format: "%02X", $0) })")
                }
                i = trackEnd
                trackIndex += 1
            } else {
                i += 1
            }
        }
        
        // Log MIDIKitSMF-parsed events
        for (trackIndex, track) in midiFile.tracks.enumerated() {
            print("\n=== Track \(trackIndex) (MIDIKitSMF) ===")
            var currentTick: UInt64 = 0
            for event in track.events {
                let deltaTicks = event.delta.ticksValue(using: midiFile.timeBase)
                currentTick += UInt64(deltaTicks)
                if let midiEvent = event.event() {
                    print("[tick \(currentTick)] MIDIEvent: \(String(describing: midiEvent))")
                    switch midiEvent {
                    case .sysEx7(let sysExData):
                        print("  Raw sysEx7 data: \(sysExData.data.map { String(format: "%02X", $0) }) (ASCII: \(String(bytes: sysExData.data, encoding: .ascii) ?? "N/A"))")
                    case .universalSysEx7(let univData):
                        print("  Raw universalSysEx7 data: \(univData.data.map { String(format: "%02X", $0) }) (ASCII: \(String(bytes: univData.data, encoding: .ascii) ?? "N/A"))")
                    default:
                        break
                    }
                    if let smfEvent = midiEvent.smfEvent(delta: .ticks(0)) {
                        print("  SMF Event: \(String(describing: smfEvent))")
                    } else {
                        print("  SMF Event: nil")
                    }
                } else {
                    print("[tick \(currentTick)] No MIDIEvent")
                }
            }
        }
    } catch {
        print("Error reading MIDI file: \(error)")
    }
}
