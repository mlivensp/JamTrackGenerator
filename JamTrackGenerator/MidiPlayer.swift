import AVFoundation

class MIDIPlayer {
    private let audioEngine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var midiPlayer: AVMIDIPlayer?
    private var midiData: Data? // Store MIDI data for looping
    private var soundFontURL: URL? // Store sound font URL for looping
    private var isLooping: Bool = false // Track looping state
    
    init() throws {
        #if os(iOS)
        // Configure audio session for iOS
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("Audio session activated successfully.")
        } catch {
            throw NSError(domain: "Failed to configure audio session: \(error.localizedDescription)", code: -1, userInfo: nil)
        }
        #elseif os(macOS)
        // No audio session configuration needed for macOS
        print("No audio session configuration required for macOS.")
        #endif
        
        // Attach sampler to engine and connect to main mixer
        audioEngine.attach(sampler)
        audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)
        
        // Load the sound font file from the app bundle
        guard let url = Bundle.main.url(forResource: "General-GS", withExtension: "sf2") else {
            throw NSError(domain: "Sound font file not found in bundle.", code: 0, userInfo: nil)
        }
        soundFontURL = url // Store for later use
        
        // Load instrument (program 0: Acoustic Grand Piano)
        do {
            try sampler.loadSoundBankInstrument(at: url,
                                               program: 0,
                                               bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                               bankLSB: UInt8(kAUSampler_DefaultBankLSB))
            print("Sound font loaded successfully.")
        } catch {
            throw NSError(domain: "Failed to load sound font: \(error.localizedDescription)", code: -2, userInfo: nil)
        }
        
        // Start the audio engine
        do {
            try audioEngine.start()
            print("Audio engine started successfully.")
        } catch {
            throw NSError(domain: "Failed to start audio engine: \(error.localizedDescription)", code: -3, userInfo: nil)
        }
    }
    
    func playNote() {
        print("Playing single note: MIDI 60")
        sampler.startNote(60, withVelocity: 100, onChannel: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.sampler.stopNote(60, onChannel: 0)
            print("Stopped single note.")
        }
    }
    
    func playMIDIFile(from url: URL, loop: Bool = false) throws {
        print("Attempting to play MIDI file from: \(url)")
        isLooping = loop // Set looping state
        
//        #if os(iOS)
//        guard url.startAccessingSecurityScopedResource() else {
//            throw NSError(domain: "Failed to obtain permission to access the file.", code: -1, userInfo: nil)
//        }
//        defer { url.stopAccessingSecurityScopedResource() }
//        #elseif os(macOS)
//        // No security-scoped resource handling needed for macOS (assuming file is accessible)
//        #endif
        
        let midiData = try Data(contentsOf: url)
        self.midiData = midiData // Store for looping
        
        guard let soundFontURL = soundFontURL else {
            throw NSError(domain: "Sound font file not found in bundle.", code: 0, userInfo: nil)
        }
        
        do {
            midiPlayer = try AVMIDIPlayer(data: midiData, soundBankURL: soundFontURL)
            midiPlayer?.prepareToPlay()
            midiPlayer?.play { [weak self] in
                print("MIDI playback completed.")
                if let self = self, self.isLooping {
                    // Restart playback if looping is enabled
                    do {
                        try self.restartMIDIFile()
                    } catch {
                        print("Failed to restart MIDI file for looping: \(error)")
                    }
                }
            }
            print("MIDI file playback started.")
        } catch {
            throw NSError(domain: "Failed to play MIDI file: \(error.localizedDescription)", code: -4, userInfo: nil)
        }
    }
    
    private func restartMIDIFile() throws {
        guard let midiData = midiData, let soundFontURL = soundFontURL else {
            throw NSError(domain: "Cannot restart: MIDI data or sound font URL missing.", code: -5, userInfo: nil)
        }
        
        midiPlayer = try AVMIDIPlayer(data: midiData, soundBankURL: soundFontURL)
        midiPlayer?.prepareToPlay()
        midiPlayer?.play { [weak self] in
            print("MIDI playback completed.")
            if let self = self, self.isLooping {
                // Continue looping
                do {
                    try self.restartMIDIFile()
                } catch {
                    print("Failed to restart MIDI file for looping: \(error)")
                }
            }
        }
        print("MIDI file playback restarted for looping.")
    }
    
    func pauseMIDIFile() {
        guard let midiPlayer = midiPlayer, midiPlayer.isPlaying else {
            print("No MIDI file is currently playing.")
            return
        }
        midiPlayer.stop() // AVMIDIPlayer has no explicit pause, so we stop and retain position
        print("MIDI file playback paused at position: \(midiPlayer.currentPosition) seconds.")
    }
    
    func resumeMIDIFile() {
        guard let midiPlayer = midiPlayer, !midiPlayer.isPlaying else {
            print("No MIDI file is paused or already playing.")
            return
        }
        midiPlayer.currentPosition = midiPlayer.currentPosition // Retain current position
        midiPlayer.prepareToPlay()
        midiPlayer.play { [weak self] in
            print("MIDI playback completed.")
            if let self = self, self.isLooping {
                do {
                    try self.restartMIDIFile()
                } catch {
                    print("Failed to restart MIDI file for looping: \(error)")
                }
            }
        }
        print("MIDI file playback resumed from position: \(midiPlayer.currentPosition) seconds.")
    }
    
    func stopMIDIFile() {
        midiPlayer?.stop()
        midiPlayer = nil
        midiData = nil // Clear stored data
        isLooping = false // Reset looping state
        print("MIDI file playback stopped.")
    }
    
    func setLooping(_ enabled: Bool) {
        isLooping = enabled
        print("Looping \(enabled ? "enabled" : "disabled").")
    }
}
