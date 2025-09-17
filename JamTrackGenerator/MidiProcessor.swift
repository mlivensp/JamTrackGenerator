import Foundation
import MIDIKitSMF

// MARK: - Filtering

enum TrackFilter {
    case all
    case drumsOnly
    case nonDrumsOnly
}

// MARK: - Models

struct MidiNote {
    let note: UInt8
    let tickOn: UInt64
    let tickOff: UInt64
    let velocityOn: UInt8
    let velocityOff: UInt8
    let channel: UInt8
}

struct MidiTrackData {
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
            let foundName = firstMetaName(in: track)
            
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
    
    private func firstMetaName(in track: MIDIFile.Chunk.Track) -> String? {
        // First pass: Try surfaced meta events via smfEvent
        for fileEvent in track.events {
            if let midiEvent = fileEvent.event() { // midiEvent is MIDIEvent?
                if let smfEvent = midiEvent.smfEvent(delta: .ticks(0)) {
                    switch smfEvent {
                    case .text(delta: _, event: let textEvent) where textEvent.textType == .trackOrSequenceName:
                        // 0x03 meta event: sequence or track name (String)
                        print("Track/Sequence Name: \(textEvent.text)")
                        return textEvent.text // Return the first one found
                    default:
                        // Other events (e.g., .text with other textType, .noteOn)
                        break
                    }
                }
            }
        }
        
        // Fallback: Parse raw data for 0x03 meta event
        print("No surfaced track name found; attempting raw parse...")
        for fileEvent in track.events {
            if let midiEvent = fileEvent.event() {
                // Check for .sysEx7 or .universalSysEx7 with meta event data
                var data: [UInt8] = []
                switch midiEvent {
                case .sysEx7(let sysExData):
                    data = sysExData.data // Extract [UInt8] from SysEx7 struct
                case .universalSysEx7(let univData):
                    data = univData.data // Extract [UInt8] from UniversalSysEx7 struct
                default:
                    // Debug: Print unknown event type
                    print("Skipping event: \(String(describing: midiEvent))")
                    continue
                }
                
                // Meta event: FF 03 <length> <text>
                guard data.count >= 2, data[0] == 0xFF, data[1] == 0x03 else { continue }
                
                // Parse VLQ length
                var i = 2
                var length: UInt32 = 0
                repeat {
                    guard i < data.count else { break }
                    let byte = data[i]
                    length = (length << 7) | UInt32(byte & 0x7F)
                    i += 1
                } while i < data.count && (data[i-1] & 0x80) != 0
                
                let textStart = i
                let textEnd = textStart + Int(length)
                guard textEnd <= data.count, textStart < textEnd else { continue }
                
                let textBytes = data[textStart..<textEnd]
                if let name = String(bytes: textBytes, encoding: .ascii) ?? String(bytes: textBytes, encoding: .utf8) {
                    print("Raw-parsed Track/Sequence Name: \(name)")
                    return name
                }
            }
        }
        
        print("No track name found, even in raw data.")
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
        
        for (trackIndex, track) in midiFile.tracks.enumerated() {
            print("\n=== Track \(trackIndex) ===")
            var currentTick: UInt64 = 0
            
            for event in track.events {
                let deltaTicks = event.delta.ticksValue(using: midiFile.timeBase)
                currentTick += UInt64(deltaTicks)
                print("[tick \(currentTick)] \(event.event())")
            }
        }
    } catch {
        print("Error reading MIDI file: \(error)")
    }
}
