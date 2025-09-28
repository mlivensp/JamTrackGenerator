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
    let keySignature: String
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
            
            // Try to get key signature from meta events
            let keySignature = try firstKeySignature(in: track, url: url, trackIndex: trackIndex) ?? "C major"
            
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
                    notes: notes,
                    keySignature: keySignature
                ))
            }
        }
        
        return results
    }
    
    // MARK: - Name extraction using smfEvent
    
    private func firstMetaName(in track: MIDIFile.Chunk.Track, url: URL, trackIndex: Int) throws -> String? {
        // First pass: Try surfaced meta events via smfEvent
        for fileEvent in track.events {
            if let midiEvent = fileEvent.event() {
                if let smfEvent = midiEvent.smfEvent(delta: .ticks(0)) {
                    switch smfEvent {
                    case .text(delta: _, event: let textEvent) where textEvent.textType == .trackOrSequenceName:
                        return textEvent.text
                    default:
                        break
                    }
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
            if fileBytes[i] == 0x4D, fileBytes[i + 1] == 0x54, fileBytes[i + 2] == 0x72, fileBytes[i + 3] == 0x6B {
                i += 4
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
                
                if currentTrackIndex == trackIndex {
                    var j = i
                    while j < trackEnd - 1 {
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
                        
                        if j < trackEnd - 1, fileBytes[j] == 0xFF, fileBytes[j + 1] == 0x03 {
                            j += 2
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
                                j = textStart
                                continue
                            }
                            
                            let textBytes = fileBytes[textStart..<textEnd]
                            if let name = String(bytes: textBytes, encoding: .ascii) ?? String(bytes: textBytes, encoding: .utf8) {
                                return name
                            }
                            print("Failed to decode text from bytes: \(textBytes.map { String(format: "%02X", $0) })")
                        }
                        j += 1
                    }
                    break
                }
                i = trackEnd
                currentTrackIndex += 1
            } else {
                i += 1
            }
        }
        
        // Secondary fallback: Check MIDIEvent cases
        print("No track name found in raw file parse for track \(trackIndex); attempting MIDIEvent fallback...")
        for fileEvent in track.events {
            if let midiEvent = fileEvent.event() {
                var data: [UInt8] = []
                switch midiEvent {
                case .sysEx7(let sysExData):
                    data = sysExData.data
                case .universalSysEx7(let univData):
                    data = univData.data
                default:
                    continue
                }
                
                guard data.count >= 2, data[0] == 0xFF, data[1] == 0x03 else {
                    continue
                }
                
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
                    return name
                }
                print("Failed to decode text from bytes: \(textBytes.map { String(format: "%02X", $0) })")
            }
        }
        
        return nil
    }
    
    // MARK: - Key signature extraction
    
    private func firstKeySignature(in track: MIDIFile.Chunk.Track, url: URL, trackIndex: Int) throws -> String? {
        // First pass: Try surfaced meta events via smfEvent (commented to avoid compile issues)
        /*
        for fileEvent in track.events {
            if let midiEvent = fileEvent.event() {
                if let smfEvent = try midiEvent.smfEvent(delta: .ticks(0)) {
                    switch smfEvent {
                    case .keySignature(delta: _, event: let keySigEvent):
                        let rawBytes = keySigEvent.midi1SMFRawBytes
                        guard rawBytes.count == 2 else {
                            continue
                        }
                        let sf = Int8(bitPattern: rawBytes[0])
                        let mi = rawBytes[1]
                        let isMajor = mi == 0
                        let majorKeys: [Int8: String] = [
                            -7: "Cb", -6: "Gb", -5: "Db", -4: "Ab", -3: "Eb",
                            -2: "Bb", -1: "F", 0: "C", 1: "G", 2: "D",
                            3: "A", 4: "E", 5: "B", 6: "F#", 7: "C#"
                        ]
                        
                        let minorKeys: [Int8: String] = [
                            -7: "Abm", -6: "Ebm", -5: "Bbm", -4: "Fm", -3: "Cm",
                            -2: "Gm", -1: "Dm", 0: "Am", 1: "Em", 2: "Bm",
                            3: "F#m", 4: "C#m", 5: "G#m", 6: "D#m", 7: "A#m"
                        ]
                        
                        let keyMap = isMajor ? majorKeys : minorKeys
                        return keyMap[sf] ?? "C major"
                    default:
                        continue
                    }
                }
            }
        }
        */
        
        // Fallback: Parse raw MIDI file data for MTrk chunks
        print("No surfaced key signature found for track \(trackIndex); attempting raw file parse...")
        let fileData = try Data(contentsOf: url)
        let fileBytes = [UInt8](fileData)
        
        var currentTrackIndex = 0
        var i = 0
        while i < fileBytes.count - 3 {
            if fileBytes[i] == 0x4D, fileBytes[i + 1] == 0x54, fileBytes[i + 2] == 0x72, fileBytes[i + 3] == 0x6B {
                i += 4
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
                
                if currentTrackIndex == trackIndex {
                    var j = i
                    while j < trackEnd - 1 {
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
                        
                        // Look for FF 58 (key signature)
                        if j < trackEnd - 1, fileBytes[j] == 0xFF, fileBytes[j + 1] == 0x58 {
                            j += 2
                            // Key signature event has fixed length of 2 bytes
                            guard j < trackEnd, fileBytes[j] == 0x02 else {
                                print("Invalid key signature length at index \(j)")
                                j += 1
                                continue
                            }
                            j += 1
                            guard j + 1 < trackEnd else {
                                print("Incomplete key signature data at index \(j)")
                                j += 2
                                continue
                            }
                            let sf = Int8(bitPattern: fileBytes[j])
                            let mi = fileBytes[j + 1]
                            j += 2
                            
                            let isMajor = mi == 0
                            let majorKeys: [Int8: String] = [
                                -7: "Cb", -6: "Gb", -5: "Db", -4: "Ab", -3: "Eb",
                                -2: "Bb", -1: "F", 0: "C", 1: "G", 2: "D",
                                3: "A", 4: "E", 5: "B", 6: "F#", 7: "C#"
                            ]
                            
                            let minorKeys: [Int8: String] = [
                                -7: "Abm", -6: "Ebm", -5: "Bbm", -4: "Fm", -3: "Cm",
                                -2: "Gm", -1: "Dm", 0: "Am", 1: "Em", 2: "Bm",
                                3: "F#m", 4: "C#m", 5: "G#m", 6: "D#m", 7: "A#m"
                            ]
                            
                            let keyMap = isMajor ? majorKeys : minorKeys
                            return keyMap[sf] ?? "C major"
                        }
                        j += 1
                    }
                    break
                }
                i = trackEnd
                currentTrackIndex += 1
            } else {
                i += 1
            }
        }
        
        // Secondary fallback: Check MIDIEvent cases
        print("No track key signature found in raw file parse for track \(trackIndex); attempting MIDIEvent fallback...")
        for fileEvent in track.events {
            if let midiEvent = fileEvent.event() {
                var data: [UInt8] = []
                switch midiEvent {
                case .sysEx7(let sysExData):
                    data = sysExData.data
                case .universalSysEx7(let univData):
                    data = univData.data
                default:
                    continue
                }
                
                guard data.count >= 2, data[0] == 0xFF, data[1] == 0x58 else {
                    continue
                }
                
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
                if textBytes.count == 2 {
                    let sf = Int8(bitPattern: textBytes[0])
                    let mi = textBytes[1]
                    let isMajor = mi == 0
                    let majorKeys: [Int8: String] = [
                        -7: "Cb", -6: "Gb", -5: "Db", -4: "Ab", -3: "Eb",
                        -2: "Bb", -1: "F", 0: "C", 1: "G", 2: "D",
                        3: "A", 4: "E", 5: "B", 6: "F#", 7: "C#"
                    ]
                    
                    let minorKeys: [Int8: String] = [
                        -7: "Abm", -6: "Ebm", -5: "Bbm", -4: "Fm", -3: "Cm",
                        -2: "Gm", -1: "Dm", 0: "Am", 1: "Em", 2: "Bm",
                        3: "F#m", 4: "C#m", 5: "G#m", 6: "D#m", 7: "A#m"
                    ]
                    
                    let keyMap = isMajor ? majorKeys : minorKeys
                    return keyMap[sf] ?? "C major"
                } else {
                    print("Failed to parse key signature from bytes: \(textBytes.map { String(format: "%02X", $0) })")
                }
            }
        }
        
        return nil
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
                
                var currentTick: UInt64 = 0
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
                    currentTick += UInt64(deltaTime)
                    
                    guard j < trackEnd else { break }
                    let eventStart = j
                    // Check for FF 03 (track name) or FF 58 (key signature)
                    if j < trackEnd - 1, fileBytes[j] == 0xFF {
                        if fileBytes[j + 1] == 0x03 {
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
                        } else if fileBytes[j + 1] == 0x58 {
                            j += 2
                            guard j < trackEnd, fileBytes[j] == 0x02 else {
                                j += 1
                                continue
                            }
                            j += 1
                            guard j + 1 < trackEnd else {
                                j += 2
                                continue
                            }
                            let sf = Int8(bitPattern: fileBytes[j])
                            let mi = fileBytes[j + 1]
                            j += 2
                            
                            let isMajor = mi == 0
                            let majorKeys: [Int8: String] = [
                                -7: "Cb", -6: "Gb", -5: "Db", -4: "Ab", -3: "Eb",
                                -2: "Bb", -1: "F", 0: "C", 1: "G", 2: "D",
                                3: "A", 4: "E", 5: "B", 6: "F#", 7: "C#"
                            ]
                            
                            let minorKeys: [Int8: String] = [
                                -7: "Abm", -6: "Ebm", -5: "Bbm", -4: "Fm", -3: "Cm",
                                -2: "Gm", -1: "Dm", 0: "Am", 1: "Em", 2: "Bm",
                                3: "F#m", 4: "C#m", 5: "G#m", 6: "D#m", 7: "A#m"
                            ]
                            
                            let keyMap = isMajor ? majorKeys : minorKeys
                            print("[tick \(currentTick)] Raw event: FF 58 (Key Signature): \(keyMap[sf] ?? "C major")")
                        } else {
                            j += 1
                        }
                    } else {
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
