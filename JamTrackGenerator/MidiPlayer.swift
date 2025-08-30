import AVFoundation

class MIDIPlayer {
    private let audioEngine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var midiPlayer: AVMIDIPlayer?
    
    init() throws {
        // Configure audio session for playback
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("Audio session activated successfully.")
        } catch {
            throw NSError(domain: "Failed to configure audio session: \(error.localizedDescription)", code: -1, userInfo: nil)
        }
        
        // Attach sampler to engine and connect to main mixer
        audioEngine.attach(sampler)
        audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)
        
        // Load the sound font file from the app bundle
        guard let url = Bundle.main.url(forResource: "General-GS", withExtension: "sf2") else {
            throw NSError(domain: "Sound font file not found in bundle.", code: 0, userInfo: nil)
        }
        
        // Load instrument (program 0: Acoustic Grand Piano)
        do {
            try sampler.loadSoundBankInstrument(at: url,
                                               program: 0,
                                               bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), // Explicitly cast to UInt8
                                               bankLSB: UInt8(kAUSampler_DefaultBankLSB)) // Explicitly cast to UInt8
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
    
    func playMIDIFile(from url: URL) throws {
        print("Attempting to play MIDI file from: \(url)")
//        guard url.startAccessingSecurityScopedResource() else {
//            throw NSError(domain: "Failed to obtain permission to access the file.", code: -1, userInfo: nil)
//        }
//        defer { url.stopAccessingSecurityScopedResource() }
        
        let midiData = try Data(contentsOf: url)
        
        guard let soundFontURL = Bundle.main.url(forResource: "General-GS", withExtension: "sf2") else {
            throw NSError(domain: "Sound font file not found in bundle.", code: 0, userInfo: nil)
        }
        
        do {
            midiPlayer = try AVMIDIPlayer(data: midiData, soundBankURL: soundFontURL)
            midiPlayer?.prepareToPlay()
            midiPlayer?.play {
                print("MIDI playback completed.")
            }
            print("MIDI file playback started.")
        } catch {
            throw NSError(domain: "Failed to play MIDI file: \(error.localizedDescription)", code: -4, userInfo: nil)
        }
    }
    
    func stopMIDIFile() {
        midiPlayer?.stop()
        midiPlayer = nil
        print("MIDI file playback stopped.")
    }
}
