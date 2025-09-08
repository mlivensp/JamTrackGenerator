import AVFoundation

/// Playback state for the score
enum PlaybackState {
    case stopped
    case playing
    case paused
}

@Observable class MIDIPlayer {
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private let sampler = AVAudioUnitSampler()
    var midiPlayer: AVMIDIPlayer?
    @ObservationIgnored private var midiData: Data? // Store MIDI data for looping
    @ObservationIgnored private var soundFontURL: URL? // Store sound font URL for looping
    var isLooping: Bool = false // Track looping state
    
    var playbackState: PlaybackState = .stopped
    @ObservationIgnored private var playbackTimer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    var currentPosition: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    var currentTempo: Double = 120.0 // BPM
    var volume: Float = 0.8

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
    
    deinit {
        // Synchronously stop timer and audio
        playbackTimer?.invalidate()
        playbackTimer = nil
        
        // Stop audio engine synchronously
        audioEngine.stop()
        
        // Clean up MIDI resources
//        if midiClient != 0 {
//            MIDIClientDispose(midiClient)
//        }
    }

//    func playNote() {
//        print("Playing single note: MIDI 60")
//        sampler.startNote(60, withVelocity: 100, onChannel: 0)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.sampler.stopNote(60, onChannel: 0)
//            print("Stopped single note.")
//        }
//    }
    
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
            if let midiPlayer = midiPlayer {
                totalDuration = midiPlayer.duration
            }
            midiPlayer?.prepareToPlay()
            midiPlayer?.play { [weak self] in
                print("MIDI playback completed.")
                if let self = self {
                    self.playbackState = .stopped
                    
                    if self.isLooping {
                        // Restart playback if looping is enabled
                        do {
                            try self.restartMIDIFile()
                        } catch {
                            print("Failed to restart MIDI file for looping: \(error)")
                        }
                    }
                }
            }
            playbackState = .playing
//            startPlaybackTimer()
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
            if let self {
                playbackState = .stopped
                
                if self.isLooping {
                    // Continue looping
                    do {
                        try self.restartMIDIFile()
                    } catch {
                        print("Failed to restart MIDI file for looping: \(error)")
                    }
                }
            }
        }
        playbackState = .playing
        startPlaybackTimer()
        print("MIDI file playback restarted for looping.")
    }
    
    func pauseMIDIFile() {
        guard let midiPlayer = midiPlayer, midiPlayer.isPlaying else {
            print("No MIDI file is currently playing.")
            return
        }
        midiPlayer.stop() // AVMIDIPlayer has no explicit pause, so we stop and retain position
        stopPlaybackTimer()
        playbackState = .paused
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
        playbackState = .playing
        startPlaybackTimer()
        print("MIDI file playback resumed from position: \(midiPlayer.currentPosition) seconds.")
    }
    
    func stopMIDIFile() {
        midiPlayer?.stop()
        midiPlayer = nil
        midiData = nil // Clear stored data
        stopPlaybackTimer()
        isLooping = false // Reset looping state
        print("MIDI file playback stopped.")
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePlayback()
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func setLooping(_ enabled: Bool) {
        isLooping = enabled
        print("Looping \(enabled ? "enabled" : "disabled").")
    }
    
    private func updatePlayback() {
//        guard let startTime = startTime else { return }
        guard let midiPlayer else { return }
        currentPosition = midiPlayer.currentPosition
        print("Current position: \(currentPosition)")
//        // Check if we've reached the end
//        if currentTime >= totalDuration {
//            if isLooping {
//                stop()
//                play()
//                return
//            } else {
//                stop()
//                return
//            }
//        }
//        
//        // Process MIDI events that should happen now
//        while noteIndex < sortedNotes.count && sortedNotes[noteIndex].timestamp <= currentTime {
//            let event = sortedNotes[noteIndex]
//            processMIDIEvent(event)
//            noteIndex += 1
//        }
    }
}
